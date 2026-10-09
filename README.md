# TaleQuilt

TaleQuilt turns the text of a book into an illustrated, print-ready PDF. An author pastes a manuscript, approves how it splits into chapters and scenes, defines a book bible of characters, settings and one art style, then generates, compares and approves an illustration per scene before laying out pages and exporting for print.

The app is the workload. The real deliverable is the way it is built: an agentic software delivery pipeline in which AI agents specify, plan, build, test, review and release, and a named human approves at four defined gates. Everything here, including this file, reaches `main` only through a reviewed pull request.

## Where to start

| If you want to | Read |
| --- | --- |
| Understand the project and its rules | [`docs/handover-brief.md`](docs/handover-brief.md) |
| See how changes flow and where humans decide | [`docs/operating-model.md`](docs/operating-model.md) |
| See the same thing as one colour-coded picture | [`docs/pipeline-map.html`](docs/pipeline-map.html), published at the Pages site |
| Watch the factory live: gates, backlog, checks, agents, ADRs | [`docs/index.html`](docs/index.html), the Factory Console on the Pages site |
| See why each significant choice was made | [`docs/adr/`](docs/adr/README.md) |
| Follow the build phase by phase | [`docs/phases/`](docs/phases/) and [`docs/learning-log.md`](docs/learning-log.md) |
| Work on the code as an agent or a person | [`CLAUDE.md`](CLAUDE.md) |

## Run it locally

Prerequisites: .NET 10 SDK, Node 24, Docker. Then:

```bash
docker compose up -d
dotnet run --project src/TaleQuilt.Api
cd src/web && npm ci && npm run dev
```

Tests: `eng/test.sh` for .NET with the coverage gate, `npm run coverage` in `src/web` for the web app. Details in [`docs/phases/phase-1-skeleton-and-ci.md`](docs/phases/phase-1-skeleton-and-ci.md).

## Stack

React single-page app, ASP.NET Core API, Azure SQL, Azure Blob Storage and Storage queues with a background worker, all defined in Bicep and deployed to Azure through GitHub Actions. Text work uses Claude. Images come from a separate image model behind a provider interface, with a fake provider for tests and local development.

## Status

Phase 0, Foundations, complete. Phase 1, Skeleton and CI, in review: first application code and the CI gate. Live view: [Factory Console](https://arhopkins3.github.io/talequilt/) and [map](https://arhopkins3.github.io/talequilt/pipeline-map.html).

## Licence

Code is released under the [MIT Licence](LICENSE). Book text and generated images are not covered by it and are tracked separately.
