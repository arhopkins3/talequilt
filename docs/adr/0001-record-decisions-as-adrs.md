# 0001. Record decisions as ADRs in the repository

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0

## Context

The project exists to be explained and defended. Agents will make and propose many choices, and the reasoning behind each is as much a deliverable as the code. Decisions kept in chat transcripts are lost; decisions kept in a wiki drift from the code they describe.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| ADRs in `docs/adr/`, reviewed in pull requests | Versioned with the code, reviewable, agents can read them, visible in the portfolio | Needs discipline to write | £0 |
| A wiki or Notion page | Easy to edit | Separate from code, no review gate, agents cannot read it in context | £0 |
| Decisions in issue comments only | Zero ceremony | Scattered, hard to find later, no status lifecycle | £0 |

## Decision

Every significant choice gets a numbered ADR in `docs/adr/` using the template, with options, a recommendation, the decision and a cost estimate. ADRs are accepted only through a pull request Alex merges. An architecture change without an ADR fails review.

## Consequences

The record of reasoning is complete and searchable. Agents must draft an ADR whenever the plan gate (G2) finds an architecture change. Superseding is by a new ADR, never by editing an old one.

## At company scale

Companies often hold ADRs per service or per team, with a central index and an architecture review board for cross-cutting ones. The same template works; the difference is who must approve, and that auditors treat ADRs as change-management evidence.
