# 0014. Factory Console: a live view of the pipeline, staged from static page to event stream

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (first version), 4 (event-driven history), 8 (decision on a full admin area)

## Context

Alex learns visually and wants one place that shows the whole software factory: which ADRs exist and in what state, the backlog and work in progress, lint and test results, running agents, deployments awaiting approval. Nearly all of this exists as structured data in GitHub's API already. The question is where the view lives and how fresh it must be. A live transcript of an agent's reasoning is not available through the API; a run exposes its status, timing and logs once each step finishes.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| A. Static page on GitHub Pages reading the GitHub API from the browser, with an optional read-only token kept in the browser | Zero infrastructure, no stored secrets, separate from the product app, available today | Polling, not push; token model is personal | £0 |
| B. Event-driven snapshot: a workflow runs on each GitHub event, writes a JSON snapshot and an append-only event log, publishes to Pages | No token in the browser, history for DORA metrics, about a minute of latency | More moving parts; needs events worth recording | £0 |
| C. Admin area inside the TaleQuilt app: webhooks into the API, events in the database, live push to a React page | Truly realtime, behind sign-in | Waits for Phase 3; couples the view of the factory to the product; full coverage rules apply | Hosting already paid for |
| D. Grafana Cloud free tier with its GitHub data source, plus a GitHub Projects board | Fastest; the usual corporate answer | ADR state and agent runs need custom work | £0 |

## Decision

Staged. **Now:** option A, a Factory Console at `docs/index.html` deployed to GitHub Pages by `.github/workflows/pages.yml`, reading the GitHub API live. It shows the live state of the `main` ruleset, the backlog grouped by gate label, open pull requests with their check runs, workflow runs with agent runs highlighted, ADRs with their status, deployments and recent activity. **Phase 4:** option B layered on top, so agent runs and gate timings accumulate as history for the metrics. **Phase 8:** decide between option C and option D with real usage behind the decision.

Conventions the console relies on:

- Agent workflows are named `Agent: <role>` so the console can recognise and group them.
- Gate labels are `gate/needs-spec`, `gate/spec-approved`, `gate/plan-approved`, plus `size/small` (ADR 0010).
- ADR status is the `**Status:**` line of each file and the status column of `docs/adr/README.md`.
- Static status (what is built, in progress or planned) lives in `docs/factory-status.js`, shared by the map and the console, and is updated in the same pull request as the change it describes.

Token handling: the console works without a token at GitHub's anonymous rate limit. For a faster refresh Alex can paste a fine-grained personal access token scoped to this one repository with read-only Contents, Issues, Pull requests, Actions, Deployments and Metadata permissions and an expiry. It is held in the browser's local storage only, sent only to `api.github.com`, and never committed. The page renders every API string as text, never as HTML, so a crafted issue title cannot run script on the page.

**Live flow (added 9 October 2026).** The console opens with one lane per open pull request: stations for the push, the CI checks, Copilot's review, the triage agent, open threads, Alex's review and merge, and the merge itself, followed by a lane for `main` (CI, Pages, and the Phase 3 staging and production stations as not-yet). Each station is in one of six states: done, running now, waiting for someone, failed or blocked, skipped, or not yet. Running stations pulse, connectors animate where work is flowing, and the reduced-motion preference turns motion off. The states come from GitHub's check runs, reviews and review comments, so the lane moves on its own as the pipeline acts.

**Pages waits for CI (added 9 October 2026).** The live flow drew CI then Pages in sequence while the two workflows in fact ran in parallel on each merge, so the console showed the site live before CI had finished. Rather than redraw the lane with a fork, the Pages workflow now runs on `workflow_run` of CI on `main`, deploys only when CI succeeded, and checks out the commit CI tested. The lane is now a true sequence, and it sets the rule Phase 3 inherits: no deploy stage starts ahead of CI. The cost is that the console updates a couple of minutes later after each merge, and that every green CI run on `main` now deploys, not only those that changed `docs/`.

## Consequences

The pipeline gains an instrument panel before it gains agents, and the panel improves as each phase adds data. Every later phase has a place to show its results. The console is documentation, so it ships with the same pull request as the thing it describes.

## At company scale

This is an internal developer portal in miniature. Companies use Backstage or a vendor equivalent, fed by webhooks into a service with its own identity, with single sign-on and per-team views. The staged path here mirrors how such portals usually start: a page reading existing APIs, then an event store, then a product of its own if the usage justifies it.
