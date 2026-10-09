# 0008. Sign-in with Google and Apple through libraries, allow-listed accounts

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (implemented in Phase 5)

## Context

A single author uses the app at first, designed so more users can be added. Alex's standing default is sign-in through a library with no identity broker. The app is on a public URL, so sign-in must also gate who may use it.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| Google and Apple via ASP.NET Core authentication handlers | Covers most personal accounts; no broker to run | Apple Sign In needs Apple Developer Programme enrolment and a Services ID | Apple Developer Programme about £79 ($99) a year |
| Google only | Simplest | One provider; Apple users excluded | £0 |
| Microsoft Entra External ID as broker | Closest to company practice | More setup; another service to own | Free to 50,000 monthly users |

## Decision

Google and Apple, each through the corresponding ASP.NET Core authentication handler, with an allow-list of permitted account identifiers so that a public URL does not mean public access. Google is built first in Phase 5; Apple follows in the same phase once the Apple Developer Programme enrolment is in place.

## Consequences

**No public deployment before sign-in.** The book endpoints have no authorisation until this ADR is implemented in Phase 5, so Phase 3 must either keep ingress private (for example Container Apps internal ingress or an IP allow-list) or bring sign-in forward; it may not expose the API or the web app on a public hostname without one of the two. Raised by the Copilot review of the Phase 1 pull request, 9 October 2026.

Every sign-in and every approval is written to the audit log with the signed-in identity. Adding a user is a configuration change, not a code change. Changes to sign-in are never classed as small and always get the security reviewer.

## At company scale

Companies use their corporate identity provider with single sign-on and conditional access, and role-based authorisation defined centrally. The library approach here maps to the same abstraction with a different provider.
