# 0012. Domains: subdomains of alexhopkins.app, DNS at GoDaddy

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (implemented in Phase 3)

## Context

Alex owns `alexhopkins.app` with DNS hosted at GoDaddy, and already runs other Azure-hosted apps on its subdomains. The `.app` top-level domain is on the HSTS preload list, so every host under it must serve HTTPS.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| `talequilt.alexhopkins.app` and `staging.talequilt.alexhopkins.app` | Free; follows the existing pattern | Ties the app to a personal domain | £0 |
| A new domain | Clean brand | Purchase and renewal; needs the trademark check first | About £1 |
| Azure default hostnames only | Nothing to configure | Google and Apple redirect URIs change when a domain is added later | £0 |

## Decision

Production at `talequilt.alexhopkins.app`, staging at `staging.talequilt.alexhopkins.app`. DNS records are added at GoDaddy; Azure Container Apps and Static Web Apps provide managed certificates. The records are documented in the Phase 3 runbook, since GoDaddy DNS is the one piece of infrastructure that cannot be in Bicep.

## Consequences

Sign-in redirect URIs are registered against the final hostnames from the start. HTTPS is mandatory everywhere, which the `.app` domain enforces anyway.

## At company scale

DNS is usually a controlled zone owned by a platform or network team, changed through tickets or infrastructure as code (for example Azure DNS in Bicep), never by hand in a registrar console.
