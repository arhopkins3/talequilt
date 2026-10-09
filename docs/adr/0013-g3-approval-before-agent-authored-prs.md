# 0013. Gate G3 before agent-authored pull requests: zero required approvals

- **Status:** Accepted; revisit in Phase 4
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0

## Context

Gate G3 is Alex reviewing and approving each pull request. GitHub does not let the author of a pull request approve it (confirmed in GitHub's documentation on required reviews). Until Phase 4, pull requests are opened from Claude Code sessions that act under Alex's own GitHub account, so Alex is the author of every pull request and cannot approve it. Only one person has write access, so a required approval of one would make every pull request unmergeable without an admin bypass.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| Require a pull request with zero required approvals until Phase 4; Alex's merge is the approval act | Honest; the rule is never bypassed | Segregation of duties is not yet enforced by the tool, only by practice |
| Require one approval and allow admin bypass | Rule reads correctly | Alex bypasses it on every merge; teaches a bad habit |
| Install the Claude GitHub App now so it authors pull requests | Brings the real design forward | Cloud sessions would still author as Alex; only workflow-opened pull requests benefit |
| A second account as reviewer | Satisfies the rule | Fakes the segregation; adds credential management |

## Decision

The `main` ruleset requires a pull request, blocks direct pushes, force pushes and deletion, requires conversation resolution and (from Phase 1) passing status checks, with zero required approvals and no bypass actors. In Phase 4, when the Claude GitHub App authors pull requests, required approvals rise to one, review from code owners is switched on, and stale approvals are dismissed on new pushes.

## Consequences

Until Phase 4, the operating model states plainly that G3 relies on Alex reviewing before merging rather than on a tool-enforced approval. The gap is a teaching point on segregation of duties, and closing it is part of the Phase 4 exit test.

## At company scale

Segregation of duties is an audit control: the author of a change cannot approve it, and evidence of an independent approval must exist for every production change. Companies enforce it with required approvals, code owners and no bypass for anyone, including administrators, and auditors sample merged pull requests to check.
