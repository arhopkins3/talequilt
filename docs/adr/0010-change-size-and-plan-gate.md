# 0010. Change size classification and when the plan gate is skipped

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (enforced from Phase 4)

## Context

Gate G2 (Alex approves the plan) applies to anything beyond a small change. Without a definition of small, either every change waits for a plan or agents decide for themselves what needs one.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| A `size/small` label applied by Alex at G1, plus a hard floor of areas that are never small | Human judgement where it matters; mechanical floor where risk is clear | Alex must think about size at every G1 | £0 |
| Mechanical rule: under 50 changed lines, no new files | Objective | A 40-line change to sign-in would skip planning | £0 |
| Nothing skips G2 | Maximum visibility | Slower; approval fatigue | £0 |

## Decision

A change skips G2 only when Alex applies `size/small` while approving the spec. Never small, whatever the label: anything touching `.github/`, `.claude/`, `infra/`, sign-in or authorisation, secrets, AI model calls or prompts, the database schema, or test thresholds. Always small: documentation-only changes and dependency version bumps that pass CI.

## Consequences

The builder agent checks the touched paths against the hard floor and refuses to treat a change as small if they match, regardless of the label. The issue template's "touches a guarded area" checkboxes feed the same rule.

## At company scale

Companies express this as change categories (standard, normal, emergency) in their change-management process, with pre-approved standard changes mapping to the small category here.
