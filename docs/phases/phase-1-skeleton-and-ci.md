# Phase 1: Skeleton and CI

**Exit test:** a pull request with a failing test or a lint error cannot merge.

## Brief

### What this phase adds

The first application code, kept thin, and the first automated gate. A React app that shows API health and a list of books with a form to add one. An ASP.NET Core API with three endpoints (list, get, create) and a database with one table. A worker process that starts, beats on a timer and stops cleanly. Around them, continuous integration: format, lint, build, unit and integration tests, and the 80 percent coverage threshold, reported as two status checks that the `main` ruleset requires.

### The problem it solves

Phase 0 proved that nothing reaches `main` without a pull request. Phase 1 makes the pull request mean something: it cannot merge unless the code builds, the tests pass and coverage holds. From here on, "tests are the contract" is enforced by GitHub rather than by anyone's diligence. The skeleton exists so the checks have something real to check, and so later phases add to a working system.

### Terms, defined once

- **Continuous integration (CI):** every push runs the same build and tests on a clean machine.
- **Status check:** a named pass or fail a workflow reports on a commit; the ruleset requires named checks.
- **Coverage threshold:** the share of code lines executed by tests, measured per project; the build fails below it.
- **Integration test:** a test that runs the API against a real database, started in a container for the test run.
- **Lock file:** a record of the exact dependency versions resolved, so CI installs what the developer tested.

### Alternatives

See ADRs 0015 (stack and layering), 0016 (data access and test database) and 0017 (quality gates and CI).

### At company scale

CI runs on self-hosted runners inside the company network with caches and an internal package feed. Pipelines are shared templates owned by a platform team, so a product team cannot quietly drop a check. Coverage is one signal among several, with patch coverage or mutation testing layered on, and flaky tests are tracked as defects.

## Decide

Settled in the Phase 1 survey: Vite + React + TypeScript with Vitest; minimal APIs in three projects; EF Core with SQL Server in a container for tests; ESLint and Prettier. Defaults taken: .NET 10, Node 24, npm, thresholds enforced in the workflow, lefthook and a Claude Code hook locally. Recorded as ADRs 0015 to 0017.

## Build

One pull request with the skeleton, tests, CI workflow, hooks and docs. After it merges, Alex adds the two checks to the ruleset.

### Required status checks (Alex applies in GitHub: Settings, Rules, Rulesets, `main-protection`, Require status checks to pass)

| Check name | Job | What it proves |
| --- | --- | --- |
| `API build and test` | `.github/workflows/ci.yml`, job `api` | Restore locked, build with warnings as errors, format clean, all .NET tests pass, every project at or above 80 percent line coverage |
| `Web build and test` | `.github/workflows/ci.yml`, job `web` | Dependencies locked, Prettier clean, ESLint clean, types check, all web tests pass with 80 percent coverage, production build succeeds |
| `Docs and status check` | `.github/workflows/ci.yml`, job `docs` | The factory status file loads with valid statuses, Markdown links resolve, workflow YAML parses |

Tick "Require branches to be up to date before merging" off for now; Phase 2 revisits it with a merge queue discussion.

### Running locally

```bash
docker compose up -d                       # SQL Server on localhost:1433
dotnet run --project src/TaleQuilt.Api     # http://localhost:5080, /api/health, /api/books, /openapi/v1.json
dotnet run --project src/TaleQuilt.Worker  # heartbeat every 30 seconds
cd src/web && npm ci && npm run dev        # http://localhost:5173, proxies /api to the API
eng/test.sh                                # all .NET tests with the coverage gate
cd src/web && npm run coverage             # all web tests with the coverage gate
```

Without Docker, point the integration tests at any SQL Server: `TALEQUILT_TEST_CONNECTION="Server=...;User Id=...;Password=...;TrustServerCertificate=True" eng/test.sh`. The tests create and drop their own database.

## Break it: the drill

Run after the checks are required. Each pull request should show a red check and a disabled merge button; fixing it turns the check green.

1. **Failing test.** On a branch, change the expected title in `tests/TaleQuilt.Core.Tests/BookTests.cs` so it no longer matches, push, open a pull request. `API build and test` fails on the test step.
2. **Lint error.** On another branch, add an unused variable to `src/web/src/App.tsx` (for example `const unused = 1;`), push, open a pull request. `Web build and test` fails on the lint or type-check step.
3. **Coverage drop.** Add a new public method to `Book` with no test. `API build and test` fails on the coverage step with the project's percentage in the log.
4. Fix each, push, and watch the checks go green. Close the pull requests without merging.

## Review findings and what came of them

Copilot code review left seven findings on the Phase 1 pull request after it merged. All seven were valid. Six were fixed in the follow-up pull request (loopback-only SQL Server port, the initial EF migration applied at startup, a form guard against the list overwriting a new book, light-only colour scheme, generated TypeScript build cache removed and ignored). The seventh, no authorisation on the book endpoints before Phase 5, is carried into Phase 3 as a hard requirement in ADR 0008. The episode led to the first agent in the pipeline, the review triage agent (ADR 0018).

## Debrief

Written in `docs/learning-log.md` after the drill.
