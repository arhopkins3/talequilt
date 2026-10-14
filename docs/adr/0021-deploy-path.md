# 0021. Deploy path: two environments from one Bicep, OIDC per environment, compatible migrations, revision rollback

- **Status:** Accepted
- **Date:** 2026-10-13
- **Deciders:** Alex Hopkins
- **Phase:** 3

## Context

Phases 1 and 2 made `main` a trunk that nothing broken, vulnerable or leaked can reach. Nothing yet proves that what reaches `main` can run, or that production changes only when a named human says so. Phase 3 builds that road under the same controls as the code: infrastructure declared in Bicep and created by the pipeline, a pipeline identity with no stored secret (CLAUDE.md rule 8), a human gate before production (G4), and a rollback that is automatic rather than hoped for. Two constraints shape it. ADR 0007 fixed the hosting shape as a working assumption to be priced and accepted here. ADR 0008 forbids a public hostname for the API or the web app until sign-in exists in Phase 5.

The Phase 3 brief put eight questions to Alex on 13 October 2026. Seven were taken as recommended. On the second, environments, Alex first chose production only, to keep cost down until the app was established, then reversed when the seventh question asked where the end-to-end, security and accessibility tests would run before a change took traffic: the honest answer with one environment is "on production, or not at all". That exchange is the reason this ADR records staging as a decision rather than a default.

## Options considered

| Decision | Chosen | Also considered | Why |
| --- | --- | --- | --- |
| Compute shape | ADR 0007 option 1: Container Apps (consumption) for API and worker, Static Web Apps for the React build, Azure SQL serverless with auto-pause, Storage, Key Vault, Log Analytics | App Service B1; Container Apps with PostgreSQL; Functions | Scales to zero, about £5 to £20 a month idle for both environments, and revisions give cheap rollback. Priced from the calculator and accepted in build pull request 4 |
| Environments | Staging and production from one Bicep, a parameter file each, two resource groups | Production only, tests against a temporary deployment | A bad deploy needs somewhere to fail before Alex sees it; one template for two environments is the pattern a company uses; auto-pause and scale to zero keep the second environment's idle cost small |
| Public exposure before sign-in (ADR 0008) | API ingress restricted to an IP allow-list; web app routes behind Static Web Apps' built-in authentication (GitHub provider, invited users only). A stopgap removed in Phase 5; changes to it are never classed as small | Bring Google sign-in forward; deploy API and worker only with internal ingress | Keeps the phase about deployment while satisfying the rule's intent |
| Pipeline identity | A user-assigned managed identity per environment, each with a federated credential trusting this repository and that GitHub environment only, Contributor on its own resource group only | One app registration with a client secret; one identity for both environments | No secret exists to store or rotate, and the staging workflow cannot touch production |
| Database migrations | The deploy workflow runs an EF Core migration bundle before the new revision takes traffic. Every migration must be compatible with the revision still serving: add now, remove in a later release once nothing reads it | The API applies migrations at startup | A schema failure fails in a pipeline step with its own log, before users see it; the compatibility rule is what makes the rollback below safe |
| Rollback | On a failed production smoke test the workflow shifts traffic back to the previous Container Apps revision and marks the run failed. Rollback moves traffic only; database recovery is point-in-time restore, a separate rehearsed path | Redeploy the previous image | Seconds rather than minutes, and the previous revision is already warm |
| Tests before production | Playwright end-to-end, OWASP ZAP baseline and axe accessibility checks run against staging and must pass before promotion is offered; production gets the smoke test only | Test the new revision at zero per cent traffic in production; smoke test only | Staging exists for this; the zero-traffic revision trick is kept as the fallback if staging is ever dropped |
| Budget | An Azure budget per resource group with alerts at £10 and £20 a month; SQL auto-pause on both environments; staging scaled to zero between runs | Alerts without auto-pause | Cost is a guardrail, not a surprise; cold starts are acceptable for a single author |

## Decision

Build the deploy path as the table says, in four pull requests (infrastructure; staging deploy; verify and promote; accept and price), with the one-time acts that only Alex can perform recorded in the Phase 3 brief: an Azure subscription, a bootstrap script that creates the two managed identities and their federated credentials (the pipeline cannot create the identity it signs in with), the two GitHub environments with Alex as required reviewer on `production`, and the budget alerts.

## Consequences

Every production change now has a Bicep diff in its pull request, a deploy run, a recorded approval and an automatic rollback, which is the evidence an auditor asks for. Two environments double the idle footprint, kept small by auto-pause and scale to zero; the real figure goes into ADR 0007 when the first bill exists. The expand-then-contract rule on migrations is a discipline every schema change must follow from now on, and the Phase 3 drill includes a pull request that breaks it. The exposure stopgap is a known temporary control with a named removal point (Phase 5), and any change to it gets the security reviewer. Revisiting this ADR is triggered by sign-in arriving (the stopgap goes), by a second author (the approval count on `production` may rise), or by cost exceeding the budget alerts.

**Amendment, 13 October 2026.** Images are built by the .NET SDK's container publish rather than a Dockerfile, on Microsoft's chiseled Ubuntu base (no shell, no package manager, non-root), and stored in GitHub Container Registry rather than an Azure Container Registry. Both are reversible choices: the SDK can target any registry, and the image names are Bicep parameters. The reasons: one fewer artefact to maintain and scan, a smaller attack surface, and a registry that is free for a public repository where a Basic ACR would cost about £4 a month for nothing the pipeline needs.

**Amendment, 14 October 2026.** Two details settled while building the Deploy workflow. The SQL server's Entra administrator is the environment's deploy identity, not Alex: the pipeline then runs migrations and grants the app identity its read and write roles and Alex `db_owner` with an idempotent script, and no human ever runs SQL by hand. Alex keeps full access through the role the pipeline grants, and adding a person is a variable change. And images are published to the registry by the Deploy workflow after CI has succeeded on `main`, not by the pull request time build, so an image tagged `main` is always one CI has passed; pull requests still build both images to archives to prove they build.

## At company scale

A platform team owns the landing zone and the Bicep modules; product teams deploy into it from templates they do not edit, and policy-as-code blocks a non-compliant resource before it exists. Workload identities are issued centrally with federated credentials scoped to repository, environment and branch, and there is no path to a client secret. Environments are many and approvals are tied to change tickets, with deployment windows enforced by the pipeline. Migrations follow the same expand-then-contract rule, reviewed by a database owner, and rollback is a tested runbook with a stated recovery time. Budgets are tagged, charged back and alerted to a team channel, not an inbox.
