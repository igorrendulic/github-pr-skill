---
name: github-pr
description: Create or update GitHub pull requests from the current repository using git and the GitHub CLI. Use when asked to open, create, ship, draft, describe, rewrite, or update a PR; turn uncommitted or committed changes into a branch-backed pull request; generate a high-quality PR title/body; or handle branch, commit, push, and gh pr create/edit workflows safely.
---

# GitHub Pull Request

Turn the current repo state into a reviewable GitHub pull request. Prefer the full workflow unless the user explicitly asks only for a PR description or only to update an existing PR body.

When this skill says to ask the user, use the available blocking question tool if the harness provides one. If no blocking question tool exists, ask plainly in chat and wait. Do not silently choose when the skill says a decision must be user-owned.

## Modes

- **Full workflow**: inspect context, resolve branch state, commit changes if needed, push, compose the PR title/body, and create or report the PR.
- **Description-only**: draft a title/body for the current branch or a supplied PR ref. Print the result and stop unless the user asks to apply it.
- **Description update**: rewrite an existing open PR title/body. Preview the new title and body summary, ask for confirmation, then apply with `gh pr edit`.

## Step 1: Gather Context

Run focused read-only commands before deciding what to do:

```bash
git status --short --branch
git diff --stat HEAD
git diff HEAD
git branch --show-current
git log --oneline -10
git remote -v
git rev-parse --abbrev-ref origin/HEAD 2>/dev/null || echo DEFAULT_BRANCH_UNRESOLVED
gh pr view --json url,title,body,state,baseRefName,headRefName 2>/dev/null || echo NO_OPEN_PR
```

Also check whether the current checkout is a linked worktree:

```bash
git rev-parse --absolute-git-dir
git rev-parse --git-common-dir
git rev-parse --show-superproject-working-tree
```

Resolve the common git dir to an absolute path before comparing it with `--absolute-git-dir`. If they differ and `--show-superproject-working-tree` is empty, this is already a linked worktree. Work in place; do not create a nested worktree.

## Step 2: Resolve Branch State

Resolve the default branch in this order:

1. `git rev-parse --abbrev-ref origin/HEAD`, stripping `origin/`.
2. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`.
3. Existing remote branches named `main`, `master`, or `develop`.
4. Ask the user if no base can be resolved.

Branch routing:

- Detached `HEAD`: create a feature branch from current `HEAD` before committing or pushing.
- On default branch with no uncommitted changes and no unpushed commits: report that there is no feature-branch work to PR and stop.
- On default branch with work: resolve uncommitted change ownership using Step 3 before creating a feature branch. Then create the branch for the current-PR changes. Read `references/branch-creation.md` before creating it.
- On a feature branch: continue in place.
- Existing open PR for the branch: push new commits, report the PR URL, then ask before rewriting the description.

Derive branch names from the change intent using lowercase hyphenated words, for example `fix-pr-description-body-file`. If the name exists, add a short numeric suffix.

## Step 3: Resolve Uncommitted Change Ownership

Before staging, committing, or creating a feature branch from a dirty checkout, classify every uncommitted path from `git status --short` and the diffs gathered in Step 1:

- **Current PR changes**: files that clearly belong to the user's requested PR intent.
- **Other local changes**: files that appear unrelated, ambiguous, generated outside the current intent, or part of a different logical change.

If there are any other local changes, do not ignore them and do not silently leave them behind. Show the user the grouped paths with a concise reason for the classification, then ask:

```text
I found other uncommitted changes that do not clearly belong to this PR. Include them in this PR, or keep them for a separate PR?
```

The user owns this decision. If they choose:

- **Include in this PR**: treat the selected paths as current PR changes and include them in the commit plan.
- **Separate PR**: keep the selected paths out of this PR, report that they remain for a separate PR, and include the exact path list in the final report. If branch creation or checkout would disturb current-PR or separate-PR paths, ask before stashing. Stash only the paths the user authorizes for that purpose, use a descriptive message, restore the stash as soon as it is safe, and report the stash result. Do not drop the stash.
- **Split selection**: include only the selected paths in this PR and keep the rest for a separate PR.

If the user says the other changes should be a separate PR and asks you to create it too, finish or safely pause the current PR flow first, then start a new full workflow for those paths. Never stage separate-PR paths into the current PR.

## Step 4: Commit and Push

Skip commit creation when the working tree is clean and all intended commits already exist on the branch.

When committing:

- Match repo commit style from recent commits and project instructions.
- Prefer one commit. Use 2-3 commits only when changed files clearly represent separate logical concerns.
- Stage explicit file paths. Do not use `git add .` or `git add -A`.
- Stage only paths resolved as current PR changes in Step 3.
- If commit hooks fail, inspect the failure and fix only issues caused by the intended change.

Push with:

```bash
git push -u origin HEAD
```

If push fails because auth, network, or permissions are unavailable, stop and report the exact blocker and the branch/commit state.

## Step 5: Compose Title and Body

Always read `references/pr-description-writing.md` in full before composing or rewriting a title/body.

Inputs to use:

- User request and conversation context.
- Branch name and commits.
- Full diff against the base branch.
- Existing PR body when rewriting.
- PR template if present.
- Validation commands actually run and their outcomes.
- Supplied evidence links, screenshots, recordings, or artifact paths.

Do not invent validation, issue-closing references, screenshots, or product behavior. If a required related-work decision is ambiguous, ask; otherwise use neutral `Related:` references or omit the reference.

## Step 6: Apply With `gh`

Resolve the PR-body file before creating or updating the PR:

- When the active session context clearly identifies a `plan_name`, create `.agent/<plan_name>/` if needed and write the body to `.agent/<plan_name>/pr_body.md`.
- Infer `plan_name` only from the active session or plan context. Do not scan `.agent/` and guess from unrelated plan directories.
- If no single plan name can be determined from that context, fall back to a unique real temporary file, for example `mktemp "${TMPDIR:-/private/tmp}/github-pr-body.XXXXXX.md"`.
- Keep a plan-scoped `pr_body.md` after the GitHub command so it remains with the plan context. A fallback temp file remains temporary.

For a new PR, write the body to the resolved file and call:

```bash
gh pr create --title "<TITLE>" --body-file "$BODY_FILE"
```

For an existing PR update, preview first:

- New title.
- First two sentences of the new body.
- Total body line count.

Ask for confirmation, then call:

```bash
gh pr edit --title "<TITLE>" --body-file "$BODY_FILE"
```

Never pass a multi-line body through inline command substitution, stdin, or `--body "$(cat ...)"`. Use `--body-file` with the resolved real file so wrappers cannot silently create an empty PR body.

## Step 7: Report

Report:

- PR URL, or the exact reason PR creation/update could not be completed.
- Branch name and pushed state.
- Commits created, if any.
- Validation performed, including commands not run and why.
- Other local changes that were routed to a separate PR, including exact paths and whether they are restored, still unstaged, or in a named stash.
- Any user action still required, such as resolving stash conflicts, authenticating `gh`, or creating the separate PR for routed local changes.
