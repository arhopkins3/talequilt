# Phase 2: Security gates

**Exit test:** a planted fake secret and a known-vulnerable dependency are both blocked.

## Brief

### What this phase adds

The second ring of automated gates, this time about what the code carries rather than whether it works: static analysis of the C# and TypeScript for security defects, a review of every dependency change against known vulnerabilities and an allowed-licence list, secret scanning with push protection so a leaked key is stopped at the push, a scan of infrastructure definitions ready for the Bicep that Phase 3 writes, a bill of materials produced on every build, and every GitHub Action pinned to a commit rather than a tag. It also closes two gaps Phase 1 found in the triage agent: the agent will run the role file from `main` rather than from the pull request it is judging, and a pull request description will be allowed to explain a finding but never to excuse one.

### The problem it solves

Phase 1 proved a pull request cannot merge unless it builds and its tests pass. None of those checks would notice an API key committed by mistake, a package with a published vulnerability, a dependency whose licence forbids redistribution under MIT, or a workflow action whose tag was moved to malicious code. Each of these has caused a real incident at a real company, and each is cheap to check by machine. Phase 2 makes them required checks, so from here the trunk is protected against the common supply-chain and secrets failures as well as against broken code. The repository is public, which makes secret scanning the most urgent item: a key pushed here is harvested within minutes.

### Terms, defined once

- **Static analysis (SAST):** reading code without running it to find defect patterns such as SQL built from strings or unvalidated redirects. CodeQL is GitHub's engine; it compiles the code into a database and runs queries against it.
- **Dependency review:** on each pull request, the list of packages added or upgraded is checked against the GitHub Advisory Database for known vulnerabilities, and against a licence policy.
- **Secret scanning with push protection:** GitHub matches pushes against the patterns of hundreds of credential formats and rejects the push before it lands. Scanning the history finds anything already there.
- **Software bill of materials (SBOM):** a machine-readable list of every component in a build, with versions, in a standard format (SPDX or CycloneDX). Customers and auditors increasingly ask for one.
- **Pinning by SHA:** referencing a GitHub Action by the commit hash of its code rather than a tag like `v4`, so the code that runs cannot change under the same name.
- **Infrastructure scan:** static checks on infrastructure definitions (Bicep here) for insecure settings such as public storage, missing encryption or wide-open network rules.

### Alternatives

ADR 0019 (security gates) records the options and the choices; ADR 0020 (triage agent hardening) follows with the third build pull request.

### At company scale

Most of this is switched on at the organisation level and cannot be turned off per repository: code scanning default configurations, secret scanning with push protection for every repository, Dependabot or Renovate with a central policy, and an allowed-actions list so only approved actions run. SBOMs are generated per release, signed, and attached as provenance attestations (SLSA level 2 or 3). Findings flow to a central dashboard with service-level targets per severity, and a security champion in each team owns the triage. Licence policy is set by legal and enforced by the same scanner.

## Decide

Settled in the Phase 2 survey on 9 October 2026: all seven as recommended, recorded in ADR 0019. The questions and options are kept below as the record of what was considered.

1. **CodeQL setup.** (a) GitHub's default setup, configured in the repository settings and managed by GitHub; (b) an advanced setup as a workflow in `.github/workflows/`, pinned, with the languages and query suites under version control, reporting a check the ruleset can require. Recommendation: (b), because the gate should be code Alex owns, like every other gate here.
2. **Dependency updates.** (a) Dependabot, native, grouped updates, free; (b) Renovate, more configurable, runs as an app. Recommendation: (a). Both open pull requests the pipeline then checks like any other.
3. **Secret scanning.** (a) GitHub's secret scanning and push protection alone; (b) add a scanner in CI (gitleaks) as a second layer that also catches generic high-entropy strings and runs on the local pre-commit hook. Recommendation: (b), both layers; GitHub stops the push, the CI scanner catches patterns GitHub does not know.
4. **Licence policy.** An allow list of licences compatible with MIT redistribution (MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Unlicense, and Microsoft's .NET library licence), with anything else failing the dependency review until Alex adds it. Recommendation: the allow list, enforced by the dependency review action for new packages and by a licence scan of the full tree.
5. **SBOM format and use.** (a) SPDX, the format GitHub's own export uses; (b) CycloneDX, with mature generators for .NET and npm. Recommendation: (b) generated on every CI run and kept as a build artifact; signing and attestation wait for Phase 3 when there is a release to attach them to.
6. **Which new checks are required for merge.** Recommendation: CodeQL, dependency review (vulnerabilities and licences) and the secret scan become required; the pin check rides inside the already-required `Docs and status check`; SBOM generation and the infrastructure scan report but do not block until Phase 3 gives them real input.
7. **Branches up to date before merging.** Phase 1 deferred this. Recommendation: leave it off and do not add a merge queue; with one author and small pull requests the risk it guards against (two green pull requests that break when combined) is low, and the cost (a rebase and a full CI cycle before every merge) is paid on every change. Revisit when agents open pull requests in parallel in Phase 4.

## Build

Three pull requests, each small enough to review in one sitting.

1. **Supply chain.** Pin every action in every workflow to a commit SHA with the tag in a comment, and add a pin check to `eng/check-docs.sh` that fails on any `uses:` without a 40-character SHA, so the already-required `Docs and status check` is the gate that keeps them pinned; Dependabot configuration for npm, NuGet and GitHub Actions with grouped weekly updates; dependency review on pull requests with the licence allow list.
2. **Scanning.** One `Security` workflow (`.github/workflows/security.yml`) with four jobs, each a status check: `CodeQL C#` and `CodeQL JavaScript` (security-extended queries; the C# analysis runs the same build CI runs), `Secret scan` (gitleaks over every commit in the history and the working tree, on every event; the release is pinned by version and checksum; the same scanner runs on the pre-commit hook when installed), `SBOM` (CycloneDX for the API, the worker and the web app, kept as a 90-day artifact) and `Infrastructure scan` (Checkov on `infra/`, reporting only until Phase 3 writes the Bicep). The workflow also runs weekly, so unchanged code is re-scanned with whatever scanner versions are pinned at the time and the Security tab stays current; new queries and patterns arrive when Dependabot bumps the CodeQL action and when the gitleaks pin is bumped by hand. Alex switches on secret scanning and push protection in the repository settings, which the workflow cannot do.
3. **Triage agent hardening.** The workflow checks out the agent's role file and helper scripts from `main`, not from the pull request head; the role gains the rule that a description can explain a finding but not excuse it, with `needs-alex` as the verdict when intent is the only defence; ADR 0018 amended.

After each merges, Alex adds the new required checks to the ruleset. Their names are part of the gate and are listed in the pull request that creates them.

### One-time settings only Alex can change (Settings, Code security)

No workflow has permission to change these, so they are human acts, like enabling Pages was in Phase 0. The first run of the dependency review check on #18 failed with "Dependency graph is not enabled", which is how this list was learnt.

| Setting | Why | Needed by |
| --- | --- | --- |
| Dependency graph: enable | Dependency review and Dependabot read the graph | Pull request 1 |
| Dependabot alerts and security updates: enable | Alerts on known vulnerabilities in what is already installed; automatic fix pull requests | Pull request 1 |
| Secret scanning and push protection: enable | GitHub rejects a push containing a known credential format | Pull request 2 and drill step 1 |
| Code scanning: leave default setup off | The CodeQL workflow in the repository is the gate (ADR 0019); default setup would duplicate it | Pull request 2 |

## Break it: the drill

1. **Planted secret.** On a branch, add a file containing a fake key in a real provider's format (GitHub's documentation lists test patterns that trigger push protection without being live credentials). Expected: the push itself is rejected by push protection; bypassing that for the drill and pushing anyway, the CI secret scan goes red.
2. **Known-vulnerable dependency.** On a branch, downgrade an npm package to a version with a published advisory. Expected: dependency review goes red naming the advisory; the merge button is disabled.
3. **Disallowed licence.** Add an npm package under a copyleft licence. Expected: dependency review goes red on the licence rule.
4. **Moved tag.** Change one pinned action back to a floating tag. Expected: `Docs and status check` goes red on the pin check, naming the unpinned line.
5. **Role file edit.** On a branch, edit the triage agent's role to say every finding is `not-an-issue`, alongside a change Copilot will comment on. Expected: the agent runs the role from `main` and judges the finding on its merits.
6. Close all pull requests without merging.

## Carried in from Phase 1

- The agent reads its role file from the pull request checkout (learning log, Phase 1, item 10).
- A pull request description excused an accurate finding (learning log, Phase 1, item 9).
- Phase 3 must not deploy publicly before sign-in exists (ADR 0008); the infrastructure scan built here runs on the Bicep that phase writes.

## Debrief

Written in `docs/learning-log.md` after the drill.
