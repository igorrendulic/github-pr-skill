# github-pr

Codex skill for turning local repository work into a GitHub pull request.

Install this repository directly into a Codex skills directory, or use a local checkout while developing the skill.

## Goal

`github-pr` helps an agent prepare a reviewable pull request from the current repository. It guides the agent through inspecting git state, choosing or creating the right branch, committing intended changes, pushing to GitHub, and creating or updating a PR with a concise title and useful body.

The skill is intentionally cautious around git state. It avoids staging unrelated local changes, checks whether the current branch already has an open PR, uses real temp files for PR bodies, and asks before user-owned decisions such as rewriting an existing PR description, carrying unpushed default-branch commits into a feature branch, or routing other uncommitted changes into this PR versus a separate PR.

## What The Skill Optimizes For

- Preserve unrelated local work.
- Surface other uncommitted changes and route them to this PR or a separate PR instead of ignoring them.
- Keep PR branches tied to the actual change intent.
- Avoid accidental PRs from default branches with no feature work.
- Generate PR descriptions that explain behavior, risk, and validation instead of restating the diff.
- Use `gh pr create` and `gh pr edit` safely with `--body-file`.
- Report exact blockers when auth, network, or permissions prevent pushing or PR creation.

## Repository Layout

- `github-pr/SKILL.md`: entry point loaded by Codex when the skill triggers.
- `github-pr/agents/openai.yaml`: UI metadata for skill lists and prompt chips.
- `github-pr/references/branch-creation.md`: default-branch branch creation flow and safeguards.
- `github-pr/references/pr-description-writing.md`: PR title and body writing guidance.
- `install.sh`: installs this skill into a local Codex skills directory.

## How To Use

Invoke the skill when you want Codex to create or update a GitHub pull request from the repository you are currently working in.

Example prompts:

```text
Use github-pr to open a PR for these changes.
Use $github-pr to turn my current changes into a GitHub pull request.
Create a draft PR from this branch.
Write a PR title and body for this branch.
Update the PR description for the current branch.
```

The default full workflow is:

1. Inspect git status, diffs, recent commits, remotes, default branch, worktree state, and any existing open PR.
2. Resolve whether to continue on the current branch or create a feature branch.
3. Ask how to route other uncommitted changes: include them in this PR, split selected paths, or keep them for a separate PR.
4. Commit only intended changes when needed.
5. Push the branch.
6. Create a new PR or report the existing PR.
7. Include validation results, separate-PR paths, and any remaining user action in the final report.

You can also ask for description-only mode when you only want a title and body:

```text
Use github-pr to draft only the PR title and body for this branch.
```

## Requirements

- A git repository with a configured GitHub remote.
- The GitHub CLI (`gh`) installed and authenticated for PR creation or updates.
- Network access and push permissions for the target repository when creating or updating PRs.

The skill can still draft a PR description without pushing when local context is available, but it cannot create or update a GitHub PR without `gh` access.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/igorrendulic/github-pr-skill/main/install.sh | bash
```

By default, the installer copies the skill to `${CODEX_HOME:-$HOME/.codex}/skills/github-pr`.

For a local checkout, run:

```bash
./install.sh
```

To install from a fork or a non-`main` branch, set installer environment variables:

```bash
GITHUB_PR_REPO=your-org/github-pr-skill GITHUB_PR_REF=your-branch ./install.sh
```

## Development Notes

Keep `github-pr/SKILL.md` focused on the core workflow. Put detailed branch and description guidance in `github-pr/references/` and link those files directly from `SKILL.md` so Codex can load only the relevant context.

When changing the skill:

1. Keep frontmatter limited to `name` and `description`.
2. Make sure every reference file used by the skill is linked from `SKILL.md`.
3. Validate installer changes with a temporary `CODEX_HOME`.
4. Test PR flows in a disposable branch or repository before relying on them for real PR creation.
