# Architecture decision records

An architecture decision record (ADR) captures one significant choice: the context, the options weighed, the decision, and its consequences. ADRs are numbered, immutable once accepted, and superseded rather than edited. Start a new one from [`0000-template.md`](0000-template.md).

| # | Decision | Status |
| --- | --- | --- |
| [0001](0001-record-decisions-as-adrs.md) | Record decisions as ADRs in the repository | Accepted |
| [0002](0002-github-public-repository-protected-main.md) | GitHub, public repository, protected `main`, pull-request-only flow | Accepted |
| [0003](0003-github-actions-delivery-platform.md) | GitHub Actions as the delivery platform | Accepted |
| [0004](0004-claude-authentication-in-ci.md) | Claude authentication in CI: Console API key with a spend limit | Accepted |
| [0005](0005-image-generation-provider-strategy.md) | Image generation behind a provider interface, OpenAI first, Azure second | Accepted |
| [0006](0006-print-target-lulu.md) | Print target: Lulu, 8.5 in square and 6 x 9 in | Accepted |
| [0007](0007-hosting-shape.md) | Hosting shape: Container Apps, Static Web Apps, Azure SQL serverless | Proposed, costed in Phase 3 |
| [0008](0008-sign-in-google-and-apple.md) | Sign-in with Google and Apple through libraries, allow-listed accounts | Accepted |
| [0009](0009-test-coverage-threshold.md) | Test coverage threshold: 80 percent, ratchet only upward | Accepted |
| [0010](0010-change-size-and-plan-gate.md) | Change size classification and when the plan gate is skipped | Accepted |
| [0011](0011-mit-licence.md) | MIT licence for the code | Accepted |
| [0012](0012-domains-and-dns.md) | Domains: subdomains of alexhopkins.app, DNS at GoDaddy | Accepted |
| [0013](0013-g3-approval-before-agent-authored-prs.md) | Gate G3 before agent-authored pull requests: zero required approvals | Accepted, to be revisited in Phase 4 |
| [0014](0014-factory-console.md) | Factory Console: a live view of the pipeline, staged from static page to event stream | Accepted |
| [0015](0015-application-skeleton-stack.md) | Application skeleton: Vite React TypeScript, minimal APIs, three .NET projects | Accepted |
| [0016](0016-data-access-and-test-database.md) | EF Core with SQL Server; integration tests against a real SQL Server | Accepted |
| [0017](0017-quality-gates-and-ci.md) | Quality gates: format, lint, build, tests and coverage as required status checks | Accepted |
| [0018](0018-review-triage-agent.md) | Review triage agent: independent verdicts on external review findings, comment-only | Accepted |
| [0019](0019-security-gates.md) | Security gates: CodeQL, dependency review with a licence allow list, two-layer secret scanning, CycloneDX SBOM, actions pinned by SHA | Accepted |
| [0020](0020-triage-agent-hardening.md) | Triage agent hardening: rules from main, intent never excuses a finding, honest cancellation | Accepted |
