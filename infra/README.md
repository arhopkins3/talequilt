# Infrastructure

Bicep for one TaleQuilt environment, deployed twice: staging and production, each from its own parameter file
(ADR 0007 for the shape, ADR 0021 for the decisions). Nothing in Azure is created by hand in the portal
(CLAUDE.md rule 8); the one exception is `bootstrap.sh`, which Alex runs once per environment from his own
signed-in Azure CLI, because the pipeline cannot create the identity it signs in with.

## Layout

```
main.bicep                  The environment: wires the modules, takes the parameters, emits the outputs
modules/logs.bicep          Log Analytics workspace
modules/storage.bicep       Storage account (blobs and queue), shared keys off, app identity granted data roles
modules/keyvault.bicep      Key Vault, RBAC, purge protection, audit to Log Analytics
modules/sql.bicep           Azure SQL serverless with auto-pause, Entra-only authentication, auditing on
modules/containerapps.bicep Container Apps environment, the API (ingress behind an IP allow-list) and the worker
modules/staticwebapp.bicep  Static Web Apps, free tier, for the React build
modules/budget.bicep        Budget on the resource group with alerts at 50 and 100 percent
parameters/*.bicepparam     Staging and production; identity and account values come from GitHub environment variables
bootstrap.sh                The one-time, per-environment setup Alex runs; safe to re-run, it updates in place
```

## Checks

- `Infrastructure build` (`.github/workflows/infra.yml`): `bicep build` and `bicep lint` on every pull request
  that touches `infra/`, with the Bicep CLI pinned by version and SHA-256. Warnings fail the build.
- `Infrastructure scan` (`.github/workflows/security.yml`): Checkov over the Bicep. It reports without blocking
  until Phase 3 decides whether to require it; its findings and the reasons for any accepted ones are listed in
  the Phase 3 brief.
- `what-if` against the real environment arrives with the Deploy workflow in build pull request 2, once the
  bootstrap identities exist for it to sign in with.

## Local

```
bicep build infra/main.bicep --stdout > /dev/null && bicep lint infra/main.bicep
```

The parameter files read GitHub environment variables; to build one locally, set the variables named in
`parameters/staging.bicepparam` to any placeholder values first.
