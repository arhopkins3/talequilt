# 0006. Print target: Lulu, 8.5 in square and 6 x 9 in

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 0 (implemented in Phase 7)

## Context

Trim size, bleed, colour profile and PDF standard depend on the print service. Lulu publishes its specification: 0.125 in bleed, 0.25 in safety margin (0.75 in for hardcover casewrap), images at 300 to 600 pixels per inch, sRGB or CMYK, fonts embedded, no crop marks, PDF/X-1a preferred. It offers print on demand, an API, and ships to the UK.

## Options considered

| Option | For | Against | Monthly cost |
| --- | --- | --- | --- |
| Lulu | Published spec, API, print on demand, UK delivery | Unit price higher than offset for large runs | £0 until a copy is ordered |
| Amazon KDP | Widest distribution, cheap author copies | Stricter file review, fewer square formats | £0 until a copy is ordered |
| UK printer such as Mixam | Offset quality, UK based | Less automation, no API | £0 until a copy is ordered |

## Decision

Build to Lulu's published specification. Trim sizes: 8.5 x 8.5 in for the picture book template, 6 x 9 in for the illustrated chapter book template, to be confirmed against Lulu's current size list when Phase 7 begins. Preflight fails any page whose images fall below 300 pixels per inch at the printed size, so an upscaling step is part of the export path.

## Consequences

Page geometry (trim plus bleed) is a template property, so adding another service later means a new template, not a redesign. The Phase 7 exit test is an exported PDF that passes Lulu's checks.

## At company scale

A publisher would hold a profile per printer and per product line, and treat preflight as a contract test against each printer's specification.
