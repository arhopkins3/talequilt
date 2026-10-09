# 0016. Entity Framework Core with SQL Server, integration tests against a real SQL Server

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 1

## Context

The database is Azure SQL (ADR 0007). The schema will change often as chapters, scenes, the book bible and generation versions arrive. Tests must exercise the API against a database, and the choice of test database decides which bugs are found before Azure.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| EF Core with migrations; integration tests start SQL Server in a container with Testcontainers | Tests the engine Azure SQL runs; migrations are versioned with the code | About a minute slower per test run; needs Docker, or an existing SQL Server |
| EF Core; SQLite for tests | Fast, no Docker | SQLite differs in types, collation and concurrency, so some bugs only appear in Azure |
| Dapper with hand-written SQL | Full control of queries | No migrations tool; more code to write and test for a fast-changing schema |

## Decision

Entity Framework Core 10 with the SQL Server provider in `TaleQuilt.Core`, schema managed by EF migrations. Integration tests in `TaleQuilt.Api.Tests` host the API in-process with `WebApplicationFactory` and run against a real SQL Server: by default a `mcr.microsoft.com/mssql/server:2025-latest` container started by Testcontainers, or, when the environment variable `TALEQUILT_TEST_CONNECTION` names an existing server, a freshly created database on that server, dropped afterwards. The second path serves machines without Docker and keeps the tests runnable anywhere a SQL Server is reachable.

Local development uses `compose.yaml`, which starts the same SQL Server image with a throwaway password that matches `appsettings.Development.json`. That password is for a local container only and never appears in any deployed configuration; deployed connection strings come from Key Vault (ADR 0007).

## Consequences

CI runs Docker, so the container path is the default there. Each test class gets its own database, so tests are isolated without sharing state. Phase 1 uses `EnsureCreated` in tests for speed; the first real migration lands with the Phase 5 schema, after which tests apply migrations so the migration path itself is tested.

## At company scale

Companies often provide shared ephemeral databases per pipeline run or a database-per-branch service, and treat migrations as deployable artefacts reviewed by a database owner. The container-per-run approach here is the single-team version of the same idea.
