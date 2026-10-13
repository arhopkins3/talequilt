# Operating model

How a change moves from idea to production in TaleQuilt, who decides at each step, and how the rules are enforced by configuration rather than by instruction. This document is the reference for every agent and the artefact Alex uses to explain the approach. Each control is marked with the phase in which it is enforced, so the current state is never overstated.

## Principles

1. **A named human is accountable for every change.** Agents are tools, not owners. Alex approves at four gates and nowhere else is needed.
2. **Gates first, autonomy second.** The pipeline and its checks exist before agents are allowed to work unattended.
3. **Tests are the contract.** A change is acceptable when tests, checks and an independent review say so, not when its author says so.
4. **Rules are enforced in configuration.** Branch rulesets, environments, code owners and workflow permissions, not prose, stop an agent doing the wrong thing.
5. **Never weaken a gate to pass.** Fix the cause or raise it.

## Stages and gates

| Stage | Agent does | Automated checks | Human gate | Enforced from |
| --- | --- | --- | --- | --- |
| 1. Spec | Turns a GitHub issue into a user story with testable acceptance criteria | Issue template complete; criteria testable | **G1:** Alex approves the spec, applying `gate/spec-approved` and optionally `size/small` | Phase 4 (manual until then) |
| 2. Plan | Proposes design, task list, test plan; drafts an ADR if architecture changes | ADR present when architecture changes | **G2:** Alex approves the plan, applying `gate/plan-approved`. Skipped only for `size/small` (ADR 0010) | Phase 4 (manual until then) |
| 3. Build | Writes code and tests on a branch; opens a pull request | Pre-commit: format, lint, secret check | None | Phase 1 |
| 4. Verify | A separate reviewer agent critiques the pull request against the spec | Build; unit and integration tests; 80 percent coverage; lint; CodeQL; dependency review; secret scanning; infrastructure scan; licence check | **G3:** Alex reviews and merges (ADR 0013) | Phase 0 for the pull request rule; Phases 1 and 2 for the checks; Phase 4 for the reviewer agent |
| 5. Staging | Deploys on merge; writes release notes | Playwright end-to-end tests; OWASP ZAP baseline scan; accessibility checks; AI evals | None | Phase 3 (AI evals Phase 6) |
| 6. Production | Prepares the release summary and rollback steps | Smoke tests after deploy; automatic rollback on failure | **G4:** Alex approves the deployment as required reviewer on the `production` environment | Phase 3 |
| 7. Operate | Triages alerts and failed runs into issues | Monitoring, audit log, cost alerts | Alex prioritises the backlog | Phase 8 |

## How the gates are enforced

- **G1 and G2** use issue labels. The build agent starts only on an issue carrying `gate/spec-approved` and either `gate/plan-approved` or `size/small`. Labels can be applied only by people with write access, so issue text from anyone else is untrusted input. Label-driven workflows arrive in Phase 4.
- **G3** uses a ruleset on `main`: pull request required, direct pushes blocked, force pushes and deletion blocked, conversations resolved, all status checks passing, no bypass actors. Required approvals are zero until Phase 4 because Alex authors every pull request until then and GitHub forbids self-approval; from Phase 4, pull requests are authored by the Claude GitHub App, required approvals become one, review from code owners is switched on, and stale approvals are dismissed on new pushes. See ADR 0013.
- **G4** uses a GitHub environment named `production` with Alex as required reviewer, available on public repositories on the free plan.

### Labels

| Label | Meaning | Applied by |
| --- | --- | --- |
| `type/feature`, `type/bug` | Kind of issue | Issue template |
| `gate/needs-spec` | Awaiting the spec agent | Issue template |
| `gate/spec-approved` | G1 passed | Alex |
| `gate/plan-approved` | G2 passed | Alex |
| `size/small` | Skips G2; subject to the hard floor in ADR 0010 | Alex |
| `area/security` | Needs the security reviewer | Alex or the spec agent |

Labels are created in Phase 4 together with the workflows that read them.

## Agent roles

Each role is a separately configured Claude Code subagent in `.claude/agents/`, with its own instructions and the narrowest tool access that lets it do its job. The review triage role is live from Phase 1; the rest arrive in Phase 4.

| Role | Triggered by | Produces | Access |
| --- | --- | --- | --- |
| Spec agent | New issue | User story and acceptance criteria, as an issue comment | Read code; write issue comments |
| Planner | G1 approval | Design, task list, test plan, draft ADR | Read code; write issue comments |
| Builder | G2 approval or `size/small` | Branch, code, tests, pull request | Write to feature branches only |
| Review triage | External review submitted (Copilot today) | A verdict and reason on every review thread; follow-up issues; the `Review triage` status check | Read code; reply to threads; create issues. Live since Phase 1 (ADR 0018) |
| Reviewer | Pull request opened or updated | Review comments against spec and standards | Read code; write review comments |
| Security reviewer | Pull requests touching sign-in, secrets, infrastructure or AI calls | Threat-focused review comments | Read code; write review comments |
| Release agent | Merge to `main` | Release notes and rollback steps | Read code; write release notes |
| Triage agent | Failed run or alert | Issue with diagnosis and suggested fix | Read logs; write issues |

## Guardrails

| Guardrail | Enforced by | From |
| --- | --- | --- |
| Agents never approve or merge | They hold no approval permission; merging is Alex's act; the `production` environment names only Alex | Phase 0 / Phase 3 |
| Agents cannot change the rules | `.github/CODEOWNERS` names Alex for `.github/`, `.claude/`, `CLAUDE.md`, `docs/adr/`, this document and `infra/`; code owner review switched on in Phase 4 | Phase 0 file; Phase 4 enforcement |
| Reviewer independence | The reviewer runs in a fresh context on the pull request event and never on its own branch | Phase 4 |
| Least privilege | Each workflow declares minimal `permissions` and an explicit allowed-tools list | Phase 1 onward |
| Trigger control | Workflows start only for actors with write access; everyone else's text is data | Phase 4 |
| Bounded runs | Turn limit, job timeout and concurrency group on every agent workflow | Phase 4 |
| Traceability | The pull request template links issue, spec, plan and run log | Phase 0 |
| Tests are the contract | Reviewer flags any pull request that deletes or loosens tests; coverage threshold may only rise | Phase 1 / Phase 4 |
| Secrets never stored for cloud access | OpenID Connect federation to Azure; Key Vault with managed identity at runtime | Phase 3 |

## Traceability record for a change

Every merged pull request should let an auditor reconstruct: the issue, the approved spec (G1 label and comment), the approved plan or `size/small` label (G2), the pull request with its checks and review (G3), the staging deployment and its test results, and the production approval (G4). Phase 4 adds run metrics: lead time from approved spec to production, deployment frequency, change failure rate, time to restore, share of agent pull requests merged without rework, review comments per pull request, what each gate caught and how long it waited, and model spend and CI minutes per merged pull request.

## How a company would differ

| Topic | This project | A company |
| --- | --- | --- |
| Accountability | Alex at G1 to G4 | A named change owner per team, recorded in the change system |
| Autonomy levels | ADR 0010 and the hard floor | A risk-tiered matrix of what agents may do unattended, by system criticality |
| Segregation of duties | Agent authors, Alex approves (from Phase 4) | Enforced by required approvals, code owners and no admin bypass; sampled by auditors |
| Data and intellectual property | Provider interface; Azure-hosted path available | Model calls routed through the company's cloud account and gateway with agreed retention |
| Agent security | Guardrails above; security reviewer; code owner rule | Least-privilege identities per agent, prompt-injection testing, secrets scanning, central policy |
| Supply chain | Actions pinned by SHA with Dependabot bumps, dependency review with a licence allow list, CycloneDX bill of materials on every run (ADR 0019) | SLSA levels, provenance attestations, internal registries |
| Quality of AI output | Tests as contract, independent reviewer, AI evals | Eval suites per prompt, review fatigue managed by small pull requests and sampling |
| Cost | Bounded runs, spend caps, cost metrics | Budgets per team, cheaper models for simpler roles, chargeback |
| Measurement | Phase 4 metrics, Phase 8 case study | Baseline before rollout; DORA metrics compared before and after |
| Adoption | Gates first, agents fourth | One pilot team, guardrails before autonomy, reviewer training, staged widening |
| Regulation and policy | This document | An AI use policy and mapping to existing change management (SOC 2, ISO 27001) |

## Seeing the factory

Two pages on the GitHub Pages site, both in `docs/` and deployed after CI passes on `main`: the **Factory Console** (`index.html`) reads the GitHub API live and shows a live flow lane per open pull request (push, CI, Copilot review, triage agent, threads, Alex's gate, merge, then main's CI and Pages), the `main` ruleset, backlog by gate label, open pull requests with their checks, workflow runs with agent runs highlighted, ADRs with status, deployments and recent activity; the **factory map** (`pipeline-map.html`) shows the same pipeline as a colour-coded picture. Static status for both lives in `factory-status.js`. See ADR 0014.

## Current state

Phase 1 closed, Phase 2 in progress. The pull request rule on `main` is live and drilled. The application skeleton (API, worker, web) exists, and the three CI jobs (`API build and test`, `Web build and test`, `Docs and status check`) are required status checks, drilled with a failing test, a lint error and a coverage drop. The review triage agent runs on every pull request and posts a `Review triage` check that is not yet required. The Factory Console shows a live flow per pull request, and Pages deploys only after CI passes on `main`. Phase 2 is adding the security gates (ADR 0019): actions pinned by SHA, Dependabot, dependency review, CodeQL, secret scanning, SBOM. No deployments of the application yet. Each phase's brief in `docs/phases/` says what it adds and the learning log records what was built.
