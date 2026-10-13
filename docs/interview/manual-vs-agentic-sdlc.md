# Manual SDLC versus an agentic software factory

Interview preparation for Alex. A side-by-side of how a change travels through a ten-year-old company's manual delivery process and through a modern agentic software factory, with the risks, the metrics, the adoption path and the objections an interviewer will raise. Where TaleQuilt provides evidence, it is cited, because a story you lived beats a principle you read.

## 1. The two worlds in one paragraph each

**The manual company (founded about 2016).** Work arrives as tickets. A business analyst writes a requirements document, a refinement meeting turns it into stories, a developer works on a long-lived branch for one to three weeks, a colleague reviews the pull request when they have time, QA tests by hand in a shared environment that is often broken by someone else's change, security runs a scan once a quarter or before a big release, a change advisory board meets on Thursdays to approve the release, operations deploys on Sunday night from a runbook, and when something breaks a developer with production access fixes it live. Continuous integration probably exists for the build; the rest is people, meetings and judgement. Lead time from idea to production is weeks to months, releases are events, and the evidence an auditor needs lives in emails, tickets and memory.

**The agentic software factory.** The pipeline is the product. Every rule is enforced by configuration, not by instruction: branch rulesets, required status checks, environment protection, code owners, workflow permissions. Agents with narrow roles do the mechanical work: turn an issue into a specification, propose a plan, write code and tests on a branch, review, triage findings, deploy. A named human approves at a small number of gates and nowhere else. Every step leaves machine-readable evidence (checks, verdicts, SBOMs, attestations, ADRs). Lead time is hours, releases are routine, and the audit trail is the pipeline itself. The humans are not removed; they are moved to the decisions that need a human, and freed from the ones that do not.

## 2. Stage by stage

| Stage | Manual company | Software factory | What TaleQuilt shows |
| --- | --- | --- | --- |
| Intake | Ticket in a tracker, often vague; priority set in a meeting | Issue with a template; a spec agent turns it into a user story with testable acceptance criteria; a human approves (G1) | Issue templates with required fields; G1 as a label gate (Phase 4) |
| Requirements and design | Word document, design review meeting, architecture decisions in people's heads or a wiki nobody updates | Planner agent proposes design, task list, test plan and a draft ADR; a human approves (G2); small changes skip G2 by rule | 20 ADRs in four days, each with options, decision, consequences and "at company scale" |
| Build | Developer on a two-week branch; merge conflicts at the end; "works on my machine" | Builder agent on a short-lived branch, small pull request, tests written with the code; pre-commit hooks for format, lint and secrets | Small PRs reviewable in one sitting; lefthook with Prettier, ESLint, dotnet format and gitleaks |
| Integration | CI builds; tests may be flaky and ignored; coverage not measured or not enforced | Required checks: restore from lock files, build with warnings as errors, format, tests, coverage floor per project; nothing merges red | Three required checks; Phase 1 drill: failing test, lint error and coverage drop each blocked by the intended check |
| Code review | One colleague, when free; "LGTM"; findings addressed by "will fix in next commit" | Independent reviewer (vendor review bot, then reviewer agents); a triage agent verifies every finding against the code and posts a verdict; a fix is confirmed from the diff, never from a comment | Review triage agent (ADR 0018, 0020); its first live run trusted "fixed in <sha>" and was corrected the same afternoon; Copilot found eight real faults in the agent's own pull requests |
| Security | Annual pen test; dependency upgrades when something breaks; secrets in config files; a quarterly scan report nobody reads | Shift-left gates on every pull request: SAST (CodeQL), dependency review with licence policy, secret scan with push protection, infrastructure scan, SBOM, actions pinned by SHA | Phase 2: all of these as checks; the secret scan found no leaks across 33 commits and caught planted tokens pre-commit |
| Test environments | Shared, fragile, booked by email; data copied from production | Ephemeral per change or per branch; integration tests against a real database in a container; environments defined in code | Tests create and drop their own SQL Server database; staging and production as Bicep (Phase 3) |
| Release approval | Change advisory board, weekly, evidence presented verbally; risk assessed by seniority | Evidence is the gate: green checks, review verdicts, SBOM, provenance; a human approves production (G4) in a protected environment; the approval is recorded with the evidence | G3 (merge) and G4 (production) are Alex's acts; GitHub environments with required reviewers (Phase 3) |
| Deploy | Runbook on a Sunday night; a person with production credentials; rollback is "restore the backup" | Pipeline deploys with short-lived identity (OpenID Connect, no stored cloud secrets); smoke tests; automatic rollback on failure; nothing deploys ahead of CI | Pages deploys only after CI is green; the lane that lied about it was made true; ADR 0007 OIDC for Azure |
| Operate | Monitoring by complaint; incidents handled by heroes | Health checks, structured logs, dashboards, cost budgets; agents bounded by turns, timeouts and spend limits | Factory Console: live flow per pull request, agent runs visible with cost; `/api/health` |
| Learn | Post-mortems rarely written, rarely read | Debrief per phase: what went wrong, what changed, metrics; decisions recorded as ADRs | Learning log with ten "went wrong" items for Phase 1 and three talking points |

## 3. A day in the life of one change

**Manual.** Monday: ticket refined, estimated at five points. Tuesday to the following Friday: developer builds on a branch, rebasing twice. Next Monday: pull request opened; reviewer gets to it Wednesday; two rounds of comments, the second answered with "will fix in the next commit". Thursday: merged to develop. Following week: QA picks it up in the shared environment, which is broken by another team's change for two days. Regression run by hand takes a week. The Thursday after that: CAB approves. Sunday night: release. Monday: a null reference in production; a developer hot-fixes it directly on the server; the fix reaches the repository a week later. Elapsed: five to seven weeks. Evidence: scattered.

**Factory.** 09:00: issue opened. 09:05: spec agent proposes the story; Alex approves (G1) in two minutes. 09:10: planner proposes design and tests; small change, G2 skipped by rule. 09:15: builder opens a pull request with code and tests. 09:18: CI, security checks and the review bot run in parallel; the triage agent verifies three findings, marks one fix-now. 09:40: builder pushes the fix; the agent re-verifies from the diff and replies "fixed". 09:45: Alex reviews the diff and the verdicts, merges (G3). 09:50: staging deploys, smoke tests pass. 10:00: Alex approves production (G4). 10:05: live, with a bill of materials, provenance and a complete trail. Elapsed: about an hour of wall clock, ten minutes of Alex's attention. If anything fails, the failure is red before it reaches anyone.

## 4. What changes and what does not

**Changes.** Lead time from weeks to hours. Review from a social act to an evidence act. Security from a quarterly event to a per-change gate. Environments from scarce to disposable. Approvals from meetings to protected environments with evidence attached. Documentation from an afterthought to a by-product (ADRs, learning log, generated specs). The developer's job from typing code to specifying, reviewing and supervising. The QA job from executing test scripts to designing tests, evaluations and drills. The operations job from running runbooks to owning the platform the pipeline runs on.

**Does not change.** A named human is accountable for every production change. Change management controls (SOC 2, ISO 27001) still ask: authorised, tested, reviewed by someone other than the author, traceable. Segregation of duties still matters; it is now enforced by configuration rather than by org chart. Judgement at the gates is still human. Bad requirements still produce bad software faster.

## 5. Risks that are new, and the guardrails for each

These are the things an interviewer who knows the field will probe. Each one has a TaleQuilt story.

- **Prompt injection.** Anything a model reads is a potential instruction: review comments, pull request descriptions, book text. Guardrail: treat model-read text as data, keep the model's powers minimal, require a human for consequential actions, never let a claim stand in for a check. Story: in the Phase 1 drill a pull request description saying "this is a drill" turned an accurate finding into "not an issue" on one pull request and not on another; the fix is a rule that intent explains but never excuses, with the human deciding.
- **Agents changing their own rules.** Guardrail: the agent's role, settings, hooks and scripts come from the trunk at run time, and the workflow file is protected by the vendor. Story: ADR 0020; a pull request could add a settings file with a hook that ran commands with the agent's token, until the directories were removed and restored from `main`.
- **Trusting comments over evidence.** Guardrail: a "fixed" claim is verified against the diff; the check stays red until the diff says otherwise; after "fixed" it keeps re-checking in case a later push regresses it. Story: the agent built to stop "fixed in the next commit" had the same habit in another form on its first live run.
- **Model non-determinism.** The same finding can get a different verdict on a different day. Guardrail: measure verdict consistency; write rules that remove the judgement where possible; keep humans on anything where the rule is unclear.
- **Least privilege for agents.** Guardrail: per-agent identities, read-only tokens where possible, a short allow-list of tools, helper scripts that validate inputs instead of raw API access. Story: the first review of the triage agent found a raw API allowance that would have let it resolve threads despite the role forbidding it.
- **Supply chain.** Guardrail: actions pinned by commit SHA, dependency review with a licence policy, SBOM on every build, provenance attestations (SLSA) at release, Dependabot for bumps so pinning is not freezing. Story: the pin check itself had a bug (overlay regex) that a reviewer caught.
- **Secrets and data.** Guardrail: no stored cloud credentials (OIDC), secrets in a vault read by managed identity, push protection, full-history secret scans, the repository public only because nothing sensitive is in it.
- **Cost.** Guardrail: bounded runs (turns, timeout, concurrency), cheaper models for simpler roles, spend visible per pull request. Story: the triage agent's first manual run cost three cents and four turns.
- **Review fatigue and automation bias.** Humans rubber-stamp when everything looks green. Guardrail: small pull requests, verdicts with reasons, drills that prove gates still work, metrics on escaped defects.
- **Regulation.** EU AI Act, NIST AI Risk Management Framework, ISO/IEC 42001: an AI use policy, an inventory of where models are used, human oversight, logging. The factory produces the logs and the oversight points as a by-product.

## 6. Metrics an interviewer expects you to name

- **DORA four keys:** lead time for changes, deployment frequency, change failure rate, time to restore. Baseline them before rollout; the manual company typically sits at weeks, monthly, 15 to 30 percent, days. A factory targets hours, daily or on demand, under 10 percent, under an hour.
- **Factory-specific:** cost per merged change (CI minutes plus model spend), human minutes per change at the gates, review-finding precision (how many agent verdicts a human overturned), escaped defects per release, time from finding to verified fix, percentage of changes with a complete evidence trail.
- **Adoption:** share of changes that went through the pipeline unaided, number of gate bypasses (should be zero and visible), drill pass rate.

## 7. How to introduce it in a real company

1. **Gates before autonomy.** Rulesets, required checks, environments and code owners at the organisation level first, so no team can opt out. Nothing autonomous until the gates have been drilled.
2. **One pilot team, one repository.** Pick a team with good tests and a sympathetic lead. Measure the baseline.
3. **Comment-only agents first.** Triage and review before build. They cannot damage anything and they teach the team what agent output looks like.
4. **Drill every gate.** Plant a failing test, a secret, a vulnerable dependency, a floating tag, a rule edit. Close unmerged. Repeat after every change to the pipeline.
5. **Central agent policy.** Roles, tool allow-lists and hooks in one owned repository, fetched at run time; product repositories cannot alter them.
6. **Train the reviewers.** The scarce skill becomes reading a diff and a verdict quickly and well.
7. **Widen in stages,** from triage to reviewer to builder on small changes to builder on larger ones, each step with its own drill and its own metrics.
8. **Publish the debriefs.** The learning log is the change-management evidence and the adoption story in one.

## 8. Objections and answers

- *"AI writes bad code."* Tests are the contract and review is independent. The pipeline does not care who wrote the code; it cares whether the evidence is green. Bad code written fast is caught fast.
- *"It is a security risk."* Less so than a developer with production credentials and a runbook. Every agent is least privilege, every action logged, every rule in configuration, no stored cloud secrets. The risks that are new (injection, self-modification) have specific guardrails and drills.
- *"The auditors will not accept it."* They will prefer it. Every change carries the request, the approval, the tests, the review verdicts, the scan results and the deployer's identity, as data. The manual company reconstructs this from email.
- *"It replaces developers."* It replaces typing. The developer becomes the specifier, reviewer and supervisor; the QA engineer designs tests and evaluations; operations owns the platform. The accountable human is still there at every gate.
- *"We are locked into one vendor."* Every model sits behind an interface and swapping is a configuration change; actions are pinned and reviewed; the pipeline is plain GitHub Actions.
- *"What about cost?"* Visible per pull request, bounded per run, and a fraction of the cost of a week of a developer's time on a change that takes an hour.
- *"Our process is regulated."* The controls map one to one: authorisation (G1, G2), testing (required checks), independent review (reviewer agent plus human), segregation of duties (agents cannot approve or merge), traceability (the trail). The factory is the control framework, enforced.

## 9. Stories worth telling in an interview

- The gate existed on paper before it existed in GitHub: two pull requests merged before the ruleset was on. Lesson: the ruleset is part of creating the repository.
- The dashboard drew a deploy waiting for CI that did not wait. Choice: make the pipeline match the picture, because a dashboard that implies a control that does not exist is worse than none.
- The agent built to distrust "fixed in the next commit" trusted it in another form on its first live run. Lesson: a guardrail is a hypothesis until a real run has tried to get round it.
- The same role excused a finding on one pull request and not on another because a description said "drill". Lesson: anything a model reads is untrusted; write the rule, keep the human on the judgement.
- The drill code carried an unplanned bug that a single test for the cap would have caught. Lesson: the coverage floor is about that test existing, not about a number.
- Every one of the agent's own pull requests was improved by the independent reviewer: eight real findings in a day, including a regex that would have broken the gate the first time a local action was added. Lesson: the factory reviews its own changes with the same rigour as product changes.

## 10. Terms, defined once

Gate (a human decision point with evidence attached); ruleset and required status check (GitHub's enforcement of "nothing merges red"); CODEOWNERS (who must review which paths); ADR (architecture decision record); DORA (the four delivery metrics); SAST (static analysis for security); SBOM (bill of materials); SLSA (supply-chain levels, provenance attestations); OIDC (short-lived identity for pipelines, no stored secrets); least privilege; prompt injection; human in the loop; drill (a planted fault to prove a gate); evidence trail.
