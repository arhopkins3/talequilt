# CLAUDE.md

Project standards for every agent and person working in this repository. Keep this file short; detail lives in `docs/`.

## What this is

TaleQuilt: a React + ASP.NET Core + Azure app that turns a manuscript into an illustrated, print-ready PDF. It is built through an agentic delivery pipeline with human gates. The pipeline is the primary deliverable. Read `docs/operating-model.md` before changing anything about how work flows.

## Rules that are never relaxed

1. **No direct commits to `main`.** Every change goes through a branch, a pull request and the gates. Agents write only to feature branches.
2. **Never weaken a gate to get a change through.** If a check blocks you, fix the cause or raise it with Alex. Deleting, skipping or loosening a test, lowering a coverage threshold, or editing anything under `.github/` to pass is prohibited.
3. **Agents never approve or merge.** Approval and merging are Alex's acts.
4. **Record decisions.** Any significant choice gets an ADR in `docs/adr/` using the template there. Architecture changes without an ADR are not mergeable.
5. **Tests are the contract.** Every feature ships with tests. Coverage is 80 percent per project and may only rise.
6. **Book text is untrusted input.** It is sent to a model, so it can carry prompt injection. Keep it separate from instructions, and never let model output trigger an action without a check.
7. **Every model sits behind an interface.** Swapping a provider is a configuration change. A fake provider exists for CI and local development; tests never call a paid model.
8. **No stored cloud credentials.** CI signs in to Azure with OpenID Connect. Runtime secrets live in Key Vault and are read through managed identity. Nothing is created in the Azure portal by hand; all infrastructure is Bicep.
9. **Text rights.** Only text Alex wrote. Never prompt for the style of a named living artist or for existing characters.

## How to work

- Small pull requests, reviewable in one sitting. Each description says what to look at and why.
- Link every pull request to its issue, approved spec and plan.
- After a substantial change, summarise: what changed, assumptions taken, next candidates.
- Explain before doing: what a step is, why it exists, the alternatives, and how it differs at company scale.
- Prefer current, well-supported libraries to hand-rolled code.
- Flag improvement opportunities for the codebase, security or flexibility as you see them.
- Name agent workflows `Agent: <role>` and use the `gate/*` labels, so the Factory Console can show them (ADR 0014).

## Layout

```
docs/handover-brief.md     The founding brief
docs/operating-model.md    Stages, gates, roles, guardrails
docs/index.html            Factory Console: live view of gates, backlog, checks, agents and ADRs (GitHub Pages)
docs/pipeline-map.html     The same, as a status-coloured map
docs/factory-status.js     Static status shared by both pages; update it with each change
docs/adr/                  Architecture decision records
docs/phases/               One brief per phase
docs/learning-log.md       Debrief per phase
.github/                   Templates, CODEOWNERS, workflows (Alex is code owner)
.claude/agents/            Agent role definitions; review-triage is live (ADR 0018)
```

src/TaleQuilt.Core/        Domain model and EF Core data access (shared)
src/TaleQuilt.Api/         ASP.NET Core minimal APIs, endpoints grouped by feature
src/TaleQuilt.Worker/      Background worker host (jobs from Phase 6)
src/web/                   Vite + React + TypeScript single-page app
tests/                     One xunit v3 test project per source project
eng/test.sh                .NET tests with the 80% coverage gate (what CI runs)
infra/                     Bicep (Phase 3)
```

## Commands

```
docker compose up -d                      SQL Server for local development
dotnet build TaleQuilt.slnx               Build everything; warnings are errors
dotnet format TaleQuilt.slnx              Format .NET code (CI verifies with --verify-no-changes)
eng/test.sh                               All .NET tests with coverage thresholds (set TALEQUILT_TEST_CONNECTION to skip Docker)
dotnet run --project src/TaleQuilt.Api    API on http://localhost:5080
cd src/web && npm ci && npm run dev       Web app on http://localhost:5173
cd src/web && npm run lint && npm run typecheck && npm run coverage
```

Required status checks on `main`: `API build and test`, `Web build and test` and `Docs and status check` (`.github/workflows/ci.yml`). Their job names are part of the gate; do not rename them. `eng/check-docs.sh` runs the docs check locally.
