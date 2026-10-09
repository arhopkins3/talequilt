# 0007. Hosting shape: Container Apps, Static Web Apps, Azure SQL serverless

- **Status:** Proposed; full costing and acceptance in Phase 3
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (decided in detail in Phase 3)

## Context

The architecture guardrails fix the shape: a React single-page app, an ASP.NET Core API, a relational database, blob storage, and a queue with a background worker. Hosting must be as cheap as Azure allows and scale to zero where possible, with staging and production built from the same Bicep templates. Region: UK South. Billing: pay-as-you-go.

## Options considered

| Option | For | Against | Monthly cost, both environments idle |
| --- | --- | --- | --- |
| Azure Container Apps (consumption) for API and worker, Static Web Apps free tier, Azure SQL serverless with auto-pause, Storage queues and blobs, Key Vault, Log Analytics | Scales to zero; representative of company systems; one container model for API and worker | Cold starts; SQL auto-pause adds a few seconds on first request | About £5 to £20 |
| App Service B1 for API and worker, Azure SQL Basic | Always on, simplest to debug | Fixed cost regardless of use | About £30 to £40 |
| Container Apps with PostgreSQL Flexible Server B1ms | Open-source database | No auto-pause | About £25 |
| Azure Functions for API and worker | Cheapest | Awkward home for an ASP.NET Core API; less representative | About £5 |

## Decision

Proceed on the first option as the working assumption. Phase 3 produces real prices from the Azure pricing calculator, a budget alert, and the accepted version of this ADR.

## Consequences

Phase 1 code is written to run in containers from the start. Static Web Apps hosts the React build; the API and worker are two Container Apps sharing one environment. Staging may be scaled to zero replicas between test runs.

## At company scale

Companies standardise on a landing zone with networking, policy and monitoring already in place, and teams deploy into it. Cost is allocated by tags and chargeback rather than kept under a personal card.
