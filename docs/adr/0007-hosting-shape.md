# 0007. Hosting shape: Container Apps, Static Web Apps, Azure SQL serverless

- **Status:** Accepted (26 November 2026, Phase 3 build 4; proposed 9 October 2026 in Phase 0)
- **Date:** 2026-11-26
- **Deciders:** Alex Hopkins
- **Phase:** 3 (shape chosen in Phase 0, priced and accepted here)

## Context

The architecture guardrails fix the shape: a React single-page app, an ASP.NET Core API, a relational database, blob storage, and a queue with a background worker. Hosting must be as cheap as Azure allows and scale to zero where possible, with staging and production built from the same Bicep templates. Region: UK South. Billing: pay-as-you-go. Both environments have now existed for a day under the pipeline, so the prices below come from the list, and the assumptions from how the system has been used.

## Options considered

| Option                                                                                                                                                                     | For                                                                                       | Against                                                         | Monthly cost, both environments idle                        |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | --------------------------------------------------------------- | ----------------------------------------------------------- |
| Azure Container Apps (consumption) for API and worker, Static Web Apps free tier, Azure SQL serverless with auto-pause, Storage queues and blobs, Key Vault, Log Analytics | Scales to zero; representative of company systems; one container model for API and worker | Cold starts; SQL auto-pause adds a few seconds on first request | About £5 to £20 (the Phase 0 guess; see the estimate below) |
| App Service B1 for API and worker, Azure SQL Basic                                                                                                                         | Always on, simplest to debug                                                              | Fixed cost regardless of use                                    | About £30 to £40                                            |
| Container Apps with PostgreSQL Flexible Server B1ms                                                                                                                        | Open-source database                                                                      | No auto-pause                                                   | About £25                                                   |
| Azure Functions for API and worker                                                                                                                                         | Cheapest                                                                                  | Awkward home for an ASP.NET Core API; less representative       | About £5                                                    |

## Decision

The first option, accepted as built. The prices and the estimate are below; the budgets are set from the estimate; two things the pricing exposed were changed in the same pull request.

## Prices

UK South, pay-as-you-go, in pounds, read from Azure's retail price list on 26 November 2026. Only the meters this system touches.

| Service                                             | Meter                                            | Price                                                                            |
| --------------------------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------- |
| Container Apps (consumption)                        | Active vCPU                                      | £0.000026 per vCPU-second                                                        |
|                                                     | Idle vCPU (a replica kept warm with no requests) | £0.000003 per vCPU-second                                                        |
|                                                     | Memory, active or idle                           | £0.000003 per GiB-second                                                         |
|                                                     | Requests                                         | £0.30 per million                                                                |
|                                                     | Free grant, per subscription per month           | 180,000 vCPU-seconds, 360,000 GiB-seconds, 2 million requests                    |
|                                                     | Environment                                      | Nothing, for a consumption-only environment                                      |
| Azure SQL serverless, General Purpose Gen5          | Compute, when not paused                         | £0.49 per vCore-hour; the database's floor is 0.5 vCore, so £0.245 an hour awake |
|                                                     | Compute, paused                                  | Nothing                                                                          |
|                                                     | Storage                                          | £0.099 per GB-month                                                              |
| Log Analytics                                       | Ingestion                                        | First 5 GB a month free, then £2.17 per GB; 30 days' retention included          |
| Storage account                                     | Blob, hot, geo-redundant                         | £0.029 per GB-month                                                              |
|                                                     | Queue operations                                 | £0.006 per 10,000                                                                |
| Key Vault                                           | Operations                                       | £0.023 per 10,000                                                                |
| Static Web Apps                                     | Free tier                                        | Nothing                                                                          |
| Budgets, alerts, managed identities, OpenID Connect |                                                  | Nothing                                                                          |
| GitHub Actions, Container Registry                  | Public repository                                | Nothing                                                                          |

## Estimate

What each environment costs a month, with the assumptions stated. Where the system is used lightly, the database is the whole bill; everything else rounds to pence.

| Environment | Item                                                           | Assumption                                                                                                                                | A month                                                      |
| ----------- | -------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| Production  | API replica kept warm (0.25 vCPU, 0.5 GiB, `apiMinReplicas` 1) | Idle all month, after the free grant                                                                                                      | £4 to £6                                                     |
| Production  | Database awake                                                 | One to two hours a day: Alex's use, the deploy's migrations and smoke test, an hour's pause delay after each                              | £7 to £15                                                    |
| Production  | Database storage, blobs, queue, Key Vault, logs                | Well under the free log allowance                                                                                                         | Under £1                                                     |
| Staging     | API and worker                                                 | Scale to zero; active only for deploys, tests and Alex's checks                                                                           | £0 to £2                                                     |
| Staging     | Database awake                                                 | Each Deploy run wakes it for migrations, the smoke test and the suites, then the pause delay; a busy day has five runs, a quiet week none | £5 to £15                                                    |
| Staging     | The rest                                                       | As production                                                                                                                             | Under £1                                                     |
| **Both**    |                                                                |                                                                                                                                           | **About £17 to £40**, against the Phase 0 guess of £5 to £20 |

The Phase 0 guess assumed both environments idle; the real driver is how many hours a day the two databases are awake, which the pipeline decides as much as any user does.

## What the pricing changed

1. **The health probes were keeping the production database awake.** The Container Apps liveness and readiness probes asked `/api/health`, which runs the database check, every ten and thirty seconds. On the production replica, which is always on, that meant the serverless database never saw the hour of inactivity it needs to pause: it would have run 720 hours a month at the 0.5-vCore floor, about £176, nine times the budget. The probes now ask `/api/health/live`, which runs no checks and says only that the process is up; `/api/health` keeps the database check for the smoke tests and the web app. Found in this costing, before the first bill, which is the point of doing it.
2. **Staging pauses after 15 minutes, not 60.** The auto-pause delay is now a parameter: 15 in staging, where deploys and tests are the only traffic and a cold start costs nobody anything, 60 in production so a reader does not meet one between pages. The minimum Azure allows is 15.
3. **Budgets sized from the estimate.** Staging £15 and production £25 a month, alerts to Alex at 50 and 100 percent of actual spend. The earlier £10 and £20 were set before the estimate existed and would have alerted in an ordinary month.

Two things considered and not done. Azure's free offer for one serverless database per subscription (100,000 vCore-seconds and 32 GB a month) would cover most of staging's database time, but it can only be set when a database is created and both databases exist; it is noted for the next time one is created. And `apiMinReplicas` 0 in production would save the £4 to £6 of the warm replica at the cost of a cold start on every quiet visit; the warm replica stays until there is a reason to prefer the saving.

## The bill

The first real bill is Alex's to read from Cost Management, by resource group, and to add here against the estimate; the staging group dates from 20 October and the production group from 24 November 2026, so November's figures include a partial month and the days before the probe change. The budget alerts are the ongoing check; a 100 percent alert means the estimate was wrong and this record is revisited.

## Consequences

Everything runs in containers from the start, Static Web Apps hosts the React build, the API and worker are two Container Apps sharing one consumption environment, and staging scales to zero between runs. Cost is now a design input: anything that keeps a database awake (a poller, a probe, a scheduled job) is a line in this record before it ships. Revisit if the bill exceeds a budget, if Phase 6's image generation changes the spend profile, or if a second user arrives.

## At company scale

Companies standardise on a landing zone with networking, policy and monitoring already in place, and teams deploy into it. Cost is allocated by tags and chargeback rather than kept under a personal card, estimates are a mandatory section of the design review, budgets and anomaly alerts are set per workload by a FinOps function, and the monthly bill is reconciled against the estimate as a matter of routine rather than once.
