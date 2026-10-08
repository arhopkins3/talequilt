# Phase 0 survey: open questions for Alex

Status: awaiting answers. No code is written until these are settled. Each answer becomes an ADR in `docs/adr/`.

Repository state found on 8 Oct 2026: `arhopkins3/talequilt` exists on GitHub, is public, has default branch `main`, and holds no commits on any branch.

## Already settled by the repository itself (please confirm)

1. **Name.** The repository is `talequilt`. A web search for "talequilt" / "tale quilt" found no app, product or registered mark using the name; quilting books with "tale" in the title exist but are not a conflict for software. Recommendation: keep TaleQuilt as the working name and run a formal search at the UK IPO, EUIPO and USPTO before buying a domain or publishing publicly.
2. **Visibility.** The repository is already public, which unlocks required reviewers on environments, code scanning and branch protection on the free plan. Recommendation: keep it public.

## Decisions needed

3. **Job spec platform.** Options: (a) GitHub Actions throughout; (b) mirror Azure DevOps; (c) mirror GitLab. Recommendation: (a). It is free for a public repo and has the Claude Code Action. If the role names Azure DevOps or GitLab, say so and the operating-model document will carry a "how this maps" section instead of switching tools.
4. **Claude sign-in for the pipeline.** Options: (a) Console API key, pay per use, with a monthly spend limit; (b) Claude Pro/Max subscription token from `claude setup-token`; (c) Workload Identity Federation: the workflow exchanges its GitHub OpenID Connect token for a short-lived Anthropic token, no stored secret. Recommendation: (a) for Phase 4, because spend is separable and auditable and the token does not expire with a personal login; try (c) later as the corporate answer, since it needs Console organisation admin.
5. **Image provider and cap.** Options: (a) OpenAI directly, GPT Image 2 (third-party sources say gpt-image-1 shuts down 23 Oct 2026 and 1.5 on 1 Dec 2026; verify on OpenAI's deprecations page when building); (b) the same models hosted in Azure AI Foundry inside your subscription, using managed identity and your data-residency terms, subject to quota and region availability. Recommendation: (a) first behind the provider interface, (b) as the documented second implementation that proves the swap. Cap: roughly $0.03 to $0.20 per image depending on quality; suggest a £20 monthly ceiling on the OpenAI account and a default per-book budget of £5, both configurable.
6. **Print service and trim sizes.** Options: (a) Lulu: published spec (0.125 in bleed, 0.25 in safety margin, 300 to 600 PPI images, sRGB or CMYK, PDF/X-1a preferred, no crop marks), print-on-demand, an API, ships to the UK; (b) Amazon KDP: widest distribution, stricter review; (c) a UK printer such as Mixam. Recommendation: (a). Proposed trims to confirm against Lulu's current list: 8.5 x 8.5 in square for the picture book, 6 x 9 in for the chapter book.
7. **First book.** Options: (a) a text of your own; (b) Aesop's Fables for the picture-book path (short, scene-rich, public domain); (c) Alice's Adventures in Wonderland for the chapter-book path (public domain, clear scenes). Recommendation: (a) if you have one, otherwise (b) for Phase 5 and 6 and (c) when layout templates arrive in Phase 7.
8. **Database and hosting.** Preliminary, pending the full costed ADR in Phase 3. Options: (a) Azure Container Apps on the consumption plan for API and worker (scale to zero), Static Web Apps free tier for React, Azure SQL serverless with auto-pause, Storage queues and blobs, Key Vault, Log Analytics: about £5 to £20 a month for both environments when idle; (b) App Service B1 plus Azure SQL Basic: always on, simpler, about £30 to £40 a month; (c) Azure Functions for API and worker: cheapest but an awkward home for an ASP.NET Core API. Recommendation: (a). Also needed: which Azure region (UK South assumed) and whether the subscription is pay-as-you-go or has credits.
9. **Domain.** Options: (a) a subdomain of your personal domain for production and another for staging, free; (b) a new domain, about £10 a year. Recommendation: (a) now, (b) only if the name becomes a product.
10. **Sign-in.** Options: (a) Google only, via ASP.NET Core's built-in Google handler with an allow-list of permitted accounts; (b) Google and Apple, which needs the Apple Developer Programme at $99 a year; (c) Microsoft Entra External ID, an identity broker. Recommendation: (a). Apple is only mandatory for native iOS apps.
11. **Coverage threshold.** Options: 60, 70 or 80 percent line coverage, measured per project with tests excluded. Recommendation: 70 percent on the API and 60 percent on the React app to start, ratcheted upward and never downward; add patch coverage on changed lines once a coverage service is chosen.
12. **What counts as small (skips G2).** Options: (a) a `size/small` label you apply at G1; (b) a mechanical rule such as under 50 changed lines and no new files; (c) a path rule. Recommendation: (a) plus a hard floor: nothing touching `.github/`, infrastructure, sign-in, AI calls, the database schema or tests' thresholds is ever small. Docs-only and dependency bumps are always small.

## Found while reading the repository

13. **Bootstrapping main.** The repository has no commits, so there is no branch to open a pull request against. The very first commit must land on main directly. Options: (a) you create main from the GitHub web UI with a README, as a company platform team would seed a repo; (b) the agent pushes a single root commit holding the brief, README and licence, then protection is switched on. Recommendation: (a), so the rule "agents never commit to main" is true from the first commit.
14. **Licence.** Options: MIT, Apache 2.0 (adds a patent grant), or no licence (all rights reserved, unusual for a public portfolio repo). Recommendation: MIT for the code; book text and generated images are tracked separately.
15. **Standing assumptions.** Confirm the eight rows marked Assumed in the brief's decision table as a block, or name the ones to change.
16. **GitHub App installation.** `/install-github-app` has to run from Claude Code on your machine, not from this cloud session. It is a Phase 4 prerequisite, not urgent.

## Verified claims from the brief

- GitHub blocks pull request authors from approving their own pull request: confirmed in GitHub's documentation.
- Print at about 300 PPI with bleed: confirmed against Lulu's PDF creation settings.
- The Claude Code GitHub Action accepts an API key, a subscription OAuth token, or OpenID Connect federation.
