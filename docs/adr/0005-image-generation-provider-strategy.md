# 0005. Image generation behind a provider interface, OpenAI first, Azure second

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (implemented in Phase 6)

## Context

Claude does the text work and does not generate raster images. OpenAI removed DALL-E 2 and 3 from its API on 12 May 2026; third-party sources report that gpt-image-1 shuts down on 23 October 2026 and gpt-image-1.5 on 1 December 2026, leaving GPT Image 2 as the current model. Providers retire models, so a swap must be a configuration change. Image generation costs money per image.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| OpenAI API directly | Simplest setup; current models first | Data leaves Azure; separate billing account | About $0.03 to $0.20 per image depending on size and quality; capped at £20 |
| Azure AI Foundry hosted image model | Inside Alex's subscription; managed identity; Azure data terms | Quota and region availability; model availability lags | Similar per-image pricing |
| Another provider (Stability, Google Imagen) | Different style strengths | Another account and interface to maintain | Similar |

## Decision

An `IImageProvider` interface (name to be confirmed in the Phase 6 plan) with three implementations: a fake provider returning placeholder images for CI and local development, OpenAI direct using GPT Image 2 as the first real provider, and an Azure AI Foundry provider as the second, proving the swap. Caps: a £20 monthly limit on the OpenAI account, and a configurable per-book budget defaulting to £5 with running cost shown in the app. Every generation is versioned with prompt, model, cost and approver.

## Consequences

Tests never call a paid model. The current model ID is checked against OpenAI's deprecations page at build time. The provider interface also carries Claude for text, so the same discipline applies to both.

## At company scale

Companies decide which data may leave their cloud and under what retention terms, so the Azure-hosted path is often the only permitted one. An internal model gateway handles keys, logging and budgets for every team.
