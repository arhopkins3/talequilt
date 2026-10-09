# 0003. GitHub Actions as the delivery platform

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0

## Context

The pipeline needs continuous integration, security scanning, deployment with human approval, and a place to run agents. The role Alex is preparing for does not mandate a platform.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| GitHub Actions | Free minutes on public repositories; hosts the Claude Code Action; environments with required reviewers; CodeQL and Dependabot built in | Vendor coupling to GitHub | £0 at this scale |
| Azure DevOps Pipelines | Native to Azure; familiar in many enterprises | Second system to run alongside GitHub; no Claude Code Action; free tier limited to one parallel job | £0 to about £30 |
| GitLab CI | Strong built-in security scanning | Would mean moving the repository; free tier minutes limited | £0 to about £20 |

## Decision

GitHub Actions throughout. No mapping to another platform is maintained unless a future role requires it.

## Consequences

Every workflow lives under `.github/workflows/`, which Alex owns as code owner. Actions are pinned to a commit SHA, not a tag (Phase 2). CI minutes per merged pull request become a cost metric in Phase 4.

## At company scale

Enterprises often run self-hosted runners inside their own network for data residency and access to private resources, add a central reusable-workflow library, and restrict which marketplace actions may be used through an allow-list policy.
