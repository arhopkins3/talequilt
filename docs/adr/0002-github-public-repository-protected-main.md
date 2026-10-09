# 0002. GitHub, public repository, protected main, pull-request-only flow

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0

## Context

The gates are the thing being demonstrated, and GitHub's free plan offers the controls that implement them (branch protection, required reviewers on environments, code scanning) only on public repositories. The repository also serves as a portfolio piece. The name `talequilt` was checked against a web search with no conflicting app or mark found; a formal trademark search is due before a domain is bought.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| Public repository on GitHub Free | All required gates available; portfolio visibility | Everything, including mistakes, is public; secrets must never land in history | £0 |
| Private repository on GitHub Free | Hides work in progress | No required reviewers on environments, no code scanning, limited branch rules | £0 |
| Private repository on GitHub Team plus Code Security | Full controls, private | Monthly fee for little gain on a one-person project | about £4 per user plus Code Security licence |

## Decision

Public repository `arhopkins3/talequilt`. `main` is protected by a ruleset: pull request required, direct pushes blocked, force pushes and deletion blocked, conversations resolved before merge, status checks required as they are added. Trunk-based development: short-lived branches, no long-running release branches.

## Consequences

Secret scanning with push protection matters more because the history is public (Phase 2). The branch rule is the Phase 0 exit test: a one-line change reaches `main` only through a pull request. Phase 4 raises required approvals to one once pull requests are agent-authored (see ADR 0013).

## At company scale

Companies use private repositories on paid plans, usually with organisation-level rulesets that teams cannot override, and often a merge queue. The controls are the same; ownership of them moves from the repository to a platform team.
