# TaleQuilt

TaleQuilt turns the text of a book into an illustrated, print-ready PDF. An author pastes a manuscript, approves how it splits into chapters and scenes, defines a book bible of characters, settings and one art style, then generates, compares and approves an illustration per scene before laying out pages and exporting for print.

The app is the workload. The real deliverable is the way it is built: an agentic software delivery pipeline in which AI agents specify, plan, build, test, review and release, and a named human approves at four defined gates. Everything here, including this file, reaches `main` only through a reviewed pull request.

## Where to start

| If you want to | Read |
| --- | --- |
| Understand the project and its rules | [`docs/handover-brief.md`](docs/handover-brief.md) |
| See how changes flow and where humans decide | [`docs/operating-model.md`](docs/operating-model.md) |
| See the same thing as one colour-coded picture | [`docs/pipeline-map.html`](docs/pipeline-map.html), open it in a browser |
| See why each significant choice was made | [`docs/adr/`](docs/adr/README.md) |
| Follow the build phase by phase | [`docs/phases/`](docs/phases/) and [`docs/learning-log.md`](docs/learning-log.md) |
| Work on the code as an agent or a person | [`CLAUDE.md`](CLAUDE.md) |

## Stack

React single-page app, ASP.NET Core API, Azure SQL, Azure Blob Storage and Storage queues with a background worker, all defined in Bicep and deployed to Azure through GitHub Actions. Text work uses Claude. Images come from a separate image model behind a provider interface, with a fake provider for tests and local development.

## Status

Phase 0, Foundations. No application code yet. See [`docs/phases/phase-0-foundations.md`](docs/phases/phase-0-foundations.md).

## Licence

Code is released under the [MIT Licence](LICENSE). Book text and generated images are not covered by it and are tracked separately.
