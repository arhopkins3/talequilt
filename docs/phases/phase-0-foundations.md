# Phase 0: Foundations

**Exit test:** a one-line change reaches `main` only through a reviewed pull request.

## Brief

### What this phase adds

A repository with its rules written down and one rule enforced: nothing reaches `main` except through a pull request. Concretely: `CLAUDE.md` (standards every agent reads), the operating model, an ADR template with thirteen accepted or proposed ADRs, issue and pull request templates, a `CODEOWNERS` file, the MIT licence, and a ruleset on `main`.

### The problem it solves

Without a protected trunk, any agent or person with push access can change production code with no record, no review and no test. Every later gate (tests, scans, approvals) hangs off the pull request, so the pull request has to be the only way in before anything else is built. Without ADRs, the reasoning behind choices lives in chat and is lost; the point of this project is to explain and defend those choices.

### Terms, defined once

- **Trunk-based development:** one long-lived branch (`main`), short-lived feature branches merged within days.
- **Pull request:** a proposal to merge a branch, carrying the diff, discussion, automated check results and approvals.
- **Branch protection / ruleset:** GitHub settings that restrict what may happen to a branch. Rulesets are the newer form: they layer, apply to patterns, and can be exported as JSON.
- **Status check:** a named result a workflow reports on a commit; a ruleset can require it to pass before merge.
- **CODEOWNERS:** a file mapping paths to people whose review is required when those paths change.
- **ADR (architecture decision record):** a short numbered document capturing one decision, its options and consequences.

### Alternatives

| Alternative | Why not here |
| --- | --- |
| Push straight to `main` with CI running after | No gate before the change lands; nothing to demonstrate |
| GitFlow with develop and release branches | Adds ceremony and merge pain without adding control; trunk plus environments does the same job |
| Classic branch protection instead of a ruleset | Works, but rulesets are the current GitHub direction and can be exported for audit |
| Decisions in a wiki | Not reviewed, not versioned with code, invisible to agents |

### At company scale

Rulesets are set at organisation level so teams cannot loosen them. CODEOWNERS maps to teams, not people. ADRs are indexed centrally and cross-cutting ones go through an architecture review board. The one-person version here keeps every mechanism and only shrinks the cast.

## Decide

Settled in the Phase 0 survey (`docs/phase-0/open-questions.md`) and recorded as ADRs 0001 to 0013.

## Build

One pull request carrying everything above. Alex applies the ruleset on `main` before merging it, so the pull request itself is the first change to pass through the gate.

### Ruleset on `main` (Alex applies in GitHub: Settings, Rules, Rulesets, New branch ruleset)

| Setting | Value | Why |
| --- | --- | --- |
| Name | `main-protection` | |
| Enforcement status | Active | |
| Bypass list | Empty | No one, including the repository admin, bypasses the gate (ADR 0013) |
| Target branches | Include default branch | |
| Restrict deletions | On | `main` cannot be deleted |
| Require linear history | Off for now | Merge commits are fine; revisit if squash-only becomes the convention |
| Require a pull request before merging | On | The gate |
| Required approvals | 0 | Alex authors every pull request until Phase 4 and cannot self-approve; becomes 1 in Phase 4 |
| Dismiss stale approvals on push | On | Harmless now, needed in Phase 4 |
| Require review from Code Owners | Off until Phase 4 | Would block every pull request today for the same self-approval reason |
| Require conversation resolution | On | Review threads must be closed before merge |
| Require status checks to pass | On, with no checks listed yet | Phase 1 adds build, test, lint and coverage checks by name |
| Block force pushes | On | History on `main` is immutable |

## Break it: the drill

Run these from a local clone after the ruleset is active. Each should fail.

1. Commit directly to `main` and push:
   ```bash
   git checkout main && git pull
   echo "direct" >> README.md && git commit -am "Direct push test" && git push
   ```
   Expected: rejected with a message that changes must be made through a pull request. Then undo locally: `git reset --hard origin/main`.
2. Force push: `git push --force origin main`. Expected: rejected.
3. Delete the branch: `git push origin --delete main`. Expected: rejected.
4. Open a pull request with an unresolved review comment on it and try to merge. Expected: the merge button is disabled until the conversation is resolved.

Record what you saw in the learning log debrief.

## Debrief

Written in `docs/learning-log.md` after the drill.
