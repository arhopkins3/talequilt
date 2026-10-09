# 0019. Security gates: CodeQL, dependency review with a licence allow list, two-layer secret scanning, CycloneDX SBOM, actions pinned by SHA

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 2

## Context

Phase 1 made the pull request mean "it builds and the tests pass". None of those checks notices a committed credential, a dependency with a published vulnerability, a licence that forbids redistribution under MIT (ADR 0011), or a workflow action whose tag has been moved to different code. The repository is public (ADR 0002), so a pushed secret is harvested within minutes, and the pipeline runs third-party actions with write permissions, so a moved tag is a supply-chain path into the repository. The handover brief names the Phase 2 gates: static analysis, dependency review, secret scanning with push protection, infrastructure scan, licence check and a bill of materials. ADR 0003 already commits to pinning actions by commit SHA in this phase.

The constraint that shapes every choice here is the one from Phase 0: a gate is code Alex owns, visible in the repository, required by the ruleset, and testable by a drill. A setting toggled in a web page is a weaker gate than a workflow under CODEOWNERS.

## Options considered

| Decision | Chosen | Alternatives | Why |
| --- | --- | --- | --- |
| Static analysis | CodeQL as a workflow in the repository (advanced setup), C# and JavaScript/TypeScript, pinned | GitHub's default setup, managed in settings | Under version control and CODEOWNERS; reports a check the ruleset can require |
| Dependency updates | Dependabot: npm, NuGet and Actions, grouped weekly | Renovate | Native, free, enough configuration for one repository; its pull requests run through every gate like any other |
| Vulnerability gate | Dependency review on every pull request, failing at low severity and above | Fail at moderate or high only; Dependabot alerts alone (advisory) | The exit test says a known-vulnerable dependency is blocked; severity thresholds are a later tuning if noise appears |
| Licence policy | Allow list: MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Unlicense; others fail until Alex adds them | Deny list of copyleft only; report only | Unknown licences fail closed, matching ADR 0011's redistribution requirement |
| Secret scanning | Two layers: GitHub push protection (a repository setting Alex switches on) and a gitleaks scan in CI and on the pre-commit hook | Push protection alone | GitHub stops the push for known credential formats; the CI scanner also catches generic high-entropy strings and runs locally before a commit exists |
| Bill of materials | CycloneDX, generated for .NET and npm on every CI run and kept as a build artifact | SPDX from GitHub's dependency graph; both | Mature generators for both ecosystems; signing and attestation wait for Phase 3 releases |
| Required checks | CodeQL, dependency review and the secret scan required; SBOM and infrastructure scan report only until Phase 3 | All required; all advisory for a week | Required where the input is real today; advisory where the input (Bicep, releases) arrives next phase |
| Branch freshness | Leave "require branches up to date" off; no merge queue | Require up-to-date branches; merge queue | One author and small pull requests make the guarded failure rare and the cost (a CI cycle per merge) constant; revisit in Phase 4 when agents open pull requests in parallel |
| Action pinning | Every `uses:` pinned to a 40-character commit SHA with the tag in a comment; `eng/check-docs.sh` fails on any unpinned action | Major tags with Dependabot alerts | A tag can be moved; a SHA cannot. Dependabot proposes the bumps, so pinning does not mean freezing |

## Decision

Phase 2 adds the gates in the table above as three pull requests: supply chain (pins, Dependabot, dependency review with the licence allow list), scanning (CodeQL, gitleaks, infrastructure scan wired to `infra/`, CycloneDX SBOM), and triage agent hardening (recorded separately in ADR 0020). After each merges, Alex adds the new required checks to the `main-protection` ruleset: `CodeQL`, `Dependency review` and `Secret scan`. Secret scanning and push protection are switched on by Alex in the repository settings, since no workflow has the permission to do so, and the operating model records that as a one-time human act like enabling Pages was in Phase 0.

## Consequences

Dependabot will open pull requests weekly; each costs a CI run and a Copilot review and a triage agent run, which is the first recurring cost of the pipeline and is visible in the Console. Pinned actions mean a moved or compromised tag cannot reach the repository, and also mean a fix in an action arrives only when Dependabot's pull request merges. The licence allow list will fail closed on a package with an unusual but acceptable licence; the fix is a one-line addition in a pull request Alex approves. CodeQL adds a few minutes to each pull request. The SBOM is an artifact nobody reads until Phase 3 attaches it to a release. The drill in the Phase 2 brief tests each gate with a planted fault, as Phase 1's did.

## At company scale

Code scanning, secret scanning with push protection and Dependabot are switched on at the organisation level and cannot be disabled per repository. An allowed-actions policy restricts which actions may run at all, and an internal action registry mirrors approved versions. SBOMs are generated per release, signed, and published as SLSA provenance attestations, with a central inventory so a new advisory can be matched to every affected build in minutes. Licence policy is owned by legal and encoded once. Findings land in a central dashboard with service-level targets per severity, and each team has a named security champion who owns triage, which is the role the Phase 4 security reviewer agent assists.
