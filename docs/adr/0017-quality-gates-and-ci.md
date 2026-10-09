# 0017. Quality gates: format, lint, build, tests and coverage as required status checks

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 1

## Context

ADR 0009 sets the coverage threshold at 80 percent per project. Phase 1 has to turn that and the other quality rules into status checks the `main` ruleset requires, so a pull request with a failing test or a lint error cannot merge. The tools must work for agents in CI and for Alex locally, and the thresholds must live in files Alex owns.

Two constraints shaped the tooling. First, xunit v3 on the .NET 10 SDK runs through Microsoft.Testing.Platform, and `dotnet test` in that mode does not run the coverlet MSBuild integration, so coverage needs a different path. Second, the ruleset requires status checks by name, so check names are part of the contract.

## Options considered

| Area | Chosen | Alternatives and why not |
| --- | --- | --- |
| Web lint and format | ESLint (typescript-eslint, react-hooks) and Prettier | Biome: one fast tool, but fewer rules and plugins today |
| .NET format and style | `dotnet format` with `.editorconfig`, analyzers at `latest-recommended`, style enforced in build, warnings as errors | StyleCop: more rules, more noise, overlaps with built-in analyzers |
| .NET coverage | coverlet command-line tool (local tool manifest) run by `eng/test.sh` with `--threshold 80 --threshold-type line --threshold-stat total` per test project | coverlet.msbuild: does not run under Microsoft.Testing.Platform mode. Microsoft code coverage extension: produces reports but enforces no threshold |
| Web coverage | Vitest with the V8 provider and thresholds of 80 percent for lines, statements, functions and branches | Istanbul provider: slower, no benefit here |
| Coverage reporting | Job summaries from ReportGenerator and the Vitest JSON summary, artifacts kept 14 days | Codecov: adds patch coverage and history, at the cost of a third-party token; revisit in Phase 8 |
| Local hooks | lefthook pre-commit for Prettier, ESLint and `dotnet format`; a Claude Code hook formats each file an agent edits | Husky: Node-only; pre-commit (Python): another runtime |

## Decision

**Status checks.** One workflow, `CI`, with two jobs whose names are the required checks: **API build and test** and **Web build and test**. Alex adds both to the `main` ruleset's required status checks. Renaming a job is a change to the gate and is reviewed as such.

**API job.** Restore in locked mode (lock files committed), build with warnings as errors, `dotnet format --verify-no-changes`, then `eng/test.sh`, which runs every test project under coverlet with the 80 percent line threshold, measuring only the assembly each project exists to test (`TaleQuilt.X.Tests` measures `TaleQuilt.X`).

**Web job.** `npm ci`, Prettier check, ESLint, TypeScript, Vitest with coverage thresholds, then the production build.

**Exclusions**, the complete list: generated EF migrations (`**/Migrations/*.cs`), code marked `[ExcludeFromCodeCoverage]`, which is permitted only on process entry points and design-time factories, the web entry point `src/main.tsx`, test helpers and the Vite type declaration. Adding anything else needs an ADR.

**Ownership.** `eng/`, `Directory.Build.props`, `tests/Directory.Build.props`, `.editorconfig`, `src/web/vite.config.ts`, `src/web/eslint.config.js`, `lefthook.yml` and `.github/` are listed in CODEOWNERS, so an agent cannot lower a threshold or drop a check without Alex seeing it in review.

**Local.** `eng/test.sh` is the same command CI runs. `lefthook.yml` runs format and lint on staged files before a commit. `.claude/settings.json` registers a hook that formats each file an agent edits, so formatting never reaches review.

## Consequences

The Phase 1 exit test is mechanical: a pull request with a failing test or a lint error shows a red required check and the merge button is disabled. Coverage is enforced per project, so a well-tested Core cannot hide an untested API. The API job needs Docker for the test database (ADR 0016); GitHub's Ubuntu runners have it.

## At company scale

Companies express the same gates as shared, versioned workflow templates owned by a platform team, add patch coverage so each change is judged on its own lines, and track flaky tests as defects. Mutation testing (Stryker) is the usual next step when line coverage stops being informative.
