# 0011. MIT licence for the code

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0

## Context

The repository is public and serves as a portfolio piece. Without a licence, others may read the code but not reuse it. Book text and generated images are a separate matter from the code licence.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| MIT | Short, permissive, the common choice for portfolio projects | No explicit patent grant |
| Apache 2.0 | Explicit patent grant | Longer, more corporate than the project needs |
| No licence | Full control | Unusual for a public portfolio; discourages reuse |

## Decision

MIT for all code and configuration in the repository. Manuscript text and generated images are not part of the licensed work; they are tracked under their own rights notes when they arrive in Phase 5 and Phase 6.

## Consequences

Dependencies must have licences compatible with redistribution under MIT; the Phase 2 licence check enforces this.

## At company scale

Companies keep an approved-licence list and block copyleft dependencies in proprietary code through the same kind of automated check.
