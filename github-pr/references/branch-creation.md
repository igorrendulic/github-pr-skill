# Branch Creation From Default Branch

Use this reference when the full workflow starts from the repo's default branch and a feature branch must be created.

Before creating a branch from a dirty checkout, the main workflow must classify uncommitted paths and ask the user whether other local changes belong in this PR or a separate PR. Do not use checkout or stash commands to bypass that decision.

## Decision Flow

### 1. Fetch fresh remote base

```bash
git fetch --no-tags origin <base>
```

If fetch fails because of network, auth, or missing remote, create the branch from current local `HEAD` and note that base freshness was not verified. Do not run the unpushed-commit check without a fresh remote base.

### 2. Check for unpushed local commits

```bash
git log origin/<base>..HEAD --oneline
```

- Empty output: set `BASE_REF=origin/<base>` and continue.
- Non-empty output: show the commit list and ask:

```text
Local <base> has N unpushed commits not on origin/<base>. Carry them onto the new feature branch, or leave them on local <base>?
```

If the user chooses to carry them forward, set `BASE_REF=HEAD`.

If the user chooses to leave them on the default branch, set `BASE_REF=origin/<base>`.

Never default silently. Accidentally carrying unrelated local default-branch commits into a PR is worse than asking.

### 3. Create the feature branch

```bash
git checkout -b <branch-name> "$BASE_REF"
```

If checkout fails because uncommitted changes would be overwritten, stash and retry:

```bash
git stash push -u -m "github-pr: pre-branch <branch-name>" -- <current-pr-paths>
git checkout -b <branch-name> "$BASE_REF"
git stash pop
```

Use explicit current-PR paths when stashing. If separate-PR paths would also be overwritten by branch checkout, stop and ask the user whether to include those paths in this PR, move them to a separate branch first, or stash them for the separate PR. Never stash all dirty files after the user has routed some of them to a separate PR unless the user explicitly asks for that.

If `git stash pop` reports conflicts, stop. Surface the conflict output and stash ref to the user. Do not auto-resolve stash conflicts or drop the stash.

## Existing Linked Worktrees

If the current directory is already a linked worktree, do not run `git worktree add` from inside it. Create or switch the branch in the current directory so the harness remains in the visible workspace.
