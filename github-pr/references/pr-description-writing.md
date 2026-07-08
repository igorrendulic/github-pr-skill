# PR Description Writing

## Core Principle

The diff is already visible on GitHub. The PR description should explain what the diff cannot show: what was impossible before and is now possible, what was broken and is now fixed, what behavior changed, and why the shape of the solution is worth reviewing.

If the lead sentence describes files moved, functions added, or tests updated, rewrite it around user-visible behavior, developer-facing capability, or review-relevant design intent.

For user-facing bugs, do a before/after pass before describing mechanics: name what the user would have seen before, then what they see now. Mention the technical cause only when it helps reviewers understand risk.

## Resolve Range and Base

Current-branch mode describes `HEAD` against the repo's default base. PR mode describes a supplied PR ref.

For current-branch mode, resolve the base in this order:

1. Caller-supplied `base:<ref>`.
2. `git rev-parse --abbrev-ref origin/HEAD`, stripping `origin/`.
3. `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'`.
4. Existing `origin/main`, `origin/master`, or `origin/develop`.
5. Ask the user.

Fetch and inspect:

```bash
git fetch --no-tags origin <base>
git log --oneline "origin/<base>..HEAD"
git log --format=fuller "origin/<base>..HEAD"
git diff "origin/<base>...HEAD"
```

For PR mode:

```bash
gh pr view <ref> --json baseRefName,headRefOid,url,body,state,isCrossRepository,headRepositoryOwner
```

If the PR is not open, report that and stop. Use the PR's base and head when building the description. For forks, avoid assuming `origin` is the base remote unless it matches the base owner/repo; fall back to `gh pr diff <ref>` and `gh pr view <ref> --json commits` when local refs are unreliable.

If the commit list is empty, report "No commits to describe" and stop.

## Size the Body

Match the description to the change size:

| Change profile | Description approach |
| --- | --- |
| Small simple change | 1-2 value-led sentences, usually no headings. |
| Small behavioral bugfix | 3-5 sentences with before/after behavior. |
| Medium feature or refactor | Narrative frame, then what changed and why. |
| Large or architectural change | Summary plus 3-5 design decision callouts and validation notes. |
| Performance change | Include before/after measurements in a table when available. |

When in doubt, shorter wins. Fix-up commits, lint commits, and rebase cleanup should not inflate the description.

## Title

Prefer the repo's existing title and commit style. If no convention is obvious, use:

```text
type(scope): imperative description
```

Rules:

- Choose type by intent, not file extension.
- Use `fix` when code remedies broken or missing behavior.
- Use `feat` only for a capability users could not previously accomplish.
- Use `refactor`, `docs`, `test`, `perf`, or `chore` when more precise.
- Keep the description lowercase, imperative, under 72 characters, and without a trailing period.
- Never use `!` or `BREAKING CHANGE:` without explicit user confirmation.

## Related Work

Make an explicit related-reference pass before writing the final body. Check the user prompt, branch name, full commit messages, existing PR body, PR template, plan/debug notes, and visible IDs or URLs.

Classify candidates:

- **Closing reference**: the PR fully resolves the item and the tracker syntax is known.
- **Non-closing reference**: the PR is related, partial, investigative, follow-up, or validation-only.
- **Uncertain**: the change appears related to tracked work but the ID or close-vs-link intent is unclear.

Ask for uncertain references when the answer changes automation. Otherwise use a neutral related reference or omit it. Do not invent closing keywords.

Common syntax:

| Tracker | Closing | Non-closing |
| --- | --- | --- |
| GitHub Issues | `Fixes #123` | `Related: #123` |
| Cross-repo GitHub Issues | `Fixes owner/repo#123` | `Related: owner/repo#123` |
| Linear | `Fixes ENG-123` | `Related to ENG-123` |

Use closing syntax only when the PR targets the branch where the tracker will close the issue and the PR truly resolves it. For partial work, keep the behavioral summary separate from the reference.

## Body Structure

Use this order:

1. Opening summary.
2. Body sections that add review value.
3. Related references, when needed.
4. Validation/test plan.
5. Evidence links or screenshots supplied by the user.

If the body uses headings, put the opening under `## Summary`. Do not leave an orphaned paragraph above the first heading.

Good sections include:

- `## Summary`
- `## What changed`
- `## Design notes`
- `## Validation`
- `## Screenshots`
- `## Evidence`
- `## Related`

Skip sections that would only restate the diff.

## Validation and Evidence

Include commands actually run and whether they passed. If no validation was possible, say why plainly. Do not label command output as screenshots or demo evidence.

Preserve existing `## Demo`, `## Screenshots`, or `## Evidence` sections when rewriting unless the user asks to refresh them. If the user supplies a new artifact path or URL, place it in the matching evidence section.

## GitHub Formatting Gotchas

- Do not prefix ordinary list items with `#`; GitHub may treat them as issue references.
- Use a real temp file with `--body-file` when applying the body with `gh`.
- Avoid raw HTML unless the repository's existing PR template uses it.
- Keep markdown tables compact and readable in GitHub's PR view.
