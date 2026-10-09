# 0015. Application skeleton: Vite React TypeScript front end, ASP.NET Core minimal APIs, three .NET projects

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 1

## Context

The stack is decided (React, ASP.NET Core, Azure). Phase 1 needs the first concrete shape: how the front end is built and tested, how the API is written, and how the .NET code is divided so that the 80 percent coverage rule applies to units that make sense. The skeleton must be thin enough to review in one sitting and real enough that later phases extend it rather than replace it.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| Vite + React + TypeScript, Vitest and Testing Library | Fast builds, static output for Static Web Apps, types catch agent mistakes early | None material |
| Next.js | Server rendering and routing conventions | A Node runtime to host and test that a single-author authenticated app does not need |
| Vite + React in JavaScript | Less to type | Loses the type checking that makes agent-written code safer to review |
| Minimal APIs, three projects (Api, Worker, Core) | Current ASP.NET Core style; shared domain and data in Core; each project has one test project | None material |
| MVC controllers | Familiar | More boilerplate per endpoint for no gain |
| Clean Architecture, five projects | Textbook separation | Five projects to keep above 80 percent for a skeleton; ceremony before there is complexity to manage |
| One project | Fastest start | Worker and shared code become awkward in Phase 6 |

## Decision

- **Front end:** Vite with React 19 and TypeScript 5.9 in `src/web`, tests with Vitest, Testing Library and jsdom. Node 24 LTS and npm.
- **API:** ASP.NET Core minimal APIs on .NET 10 in `src/TaleQuilt.Api`, endpoints grouped by feature (`Endpoints/BookEndpoints.cs`), typed results, problem details for errors, built-in OpenAPI in development.
- **Worker:** a .NET Worker Service in `src/TaleQuilt.Worker`, today a heartbeat, from Phase 6 the host for generation and export jobs.
- **Core:** `src/TaleQuilt.Core` holds the domain model and Entity Framework Core data access shared by the API and the worker.
- **Tests:** one test project per source project under `tests/`, xunit v3 and Shouldly, with `TimeProvider` injected so time is controllable.
- Central package management (`Directory.Packages.props`), lock files, warnings as errors and the latest recommended analyzers for every project.

The first slice is a `Book` with a title, and three endpoints: list, get and create. The web app shows API health, the list, and a form to add a book.

## Consequences

Phase 3 deploys two containers (API and worker) and one static site, which matches the hosting shape in ADR 0007. Author input (a title) is validated in the domain class, so the rule that book text is untrusted has a home from the first line of code. .NET 9 leaves support on 10 November 2026, so .NET 10 avoids an upgrade inside the project.

## At company scale

A company would start from an internal template repository that bakes in these choices, so teams inherit the layering, analyzers and test setup rather than deciding them. The decisions here are the content of such a template.
