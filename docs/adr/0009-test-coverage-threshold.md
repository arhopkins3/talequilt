# 0009. Test coverage threshold: 80 percent, ratchet only upward

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (enforced from Phase 1)

## Context

Tests are the contract that keeps agents honest: a change is acceptable when the tests say so. A coverage threshold that blocks merge stops an agent passing by writing code without tests. The number must be high enough to matter and defined precisely enough to be fair.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| 80 percent line coverage per project from the start | Strict from day one; nothing to ratchet later | Early friction on UI scaffolding and generated code | £0 |
| 70 percent API, 60 percent web, ratchet upward | Gentler start | Lower bar while the codebase is small, when it is cheapest to test | £0 |
| Patch coverage only on changed lines | Focuses on new code | Needs an external service; whole-project debt invisible | £0 on public repos |

## Decision

80 percent line coverage, measured per project (API, worker, web) with test projects excluded and an explicit, reviewed exclusion list for generated code and entry points. The threshold is configuration Alex owns and may only rise. Pull requests that delete or loosen tests are flagged by the reviewer and fail review.

## Consequences

Phase 1 must land with coverage tooling and the exclusion list in the same pull request as the first code. Coverage is reported on every pull request so the trend is visible.

## At company scale

Companies pair a whole-project floor with patch coverage on changed lines, treat the floor as a policy owned by engineering leadership, and watch for coverage theatre, where tests execute code without asserting anything.
