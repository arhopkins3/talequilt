# Illustrated Book Studio: Agentic SDLC Handover Brief

Oct 7, 2026 · @Alex

Build an app that turns book text into an illustrated, print-ready book, and deliver it through an agentic SDLC in which agents do the work and Alex approves at defined gates. The pipeline is the main deliverable; the app is the workload that exercises it. This brief is addressed to the Claude Code session that will run the project.

## Mission and working agreement

Alex is preparing for a role introducing agentic AI delivery across a software company's SDLC. This project is his working example and his way of learning the subject. Success means a pipeline he can demo, explain and defend, with a real app flowing through it.

You have three jobs, in this order of priority:

1. **Build the delivery system.** Agents specify, plan, build, test, review and release. Automated gates check quality and security. Alex approves at the human gates.
2. **Teach as you go.** Before each step, explain what it is, why it exists, the alternatives, and how it differs at company scale.
3. **Build the app.** Deliver it only through the pipeline, one small slice at a time.

Working rules:

- **Ask before deciding.** Put every major decision to Alex as a short survey of options with a recommendation. He prefers twenty questions to a wrong turn.
- **No direct commits to main.** This overrides Alex's usual habit. Every change goes through a branch, a pull request and the gates, because the gates are the thing being demonstrated.
- **Never weaken a gate to get a change through.** If a check blocks you, fix the cause or raise it with Alex.
- **Record decisions.** Write an architecture decision record (ADR) for each significant choice, in `docs/adr/`.
- **Summarise after each substantial change:** what changed, assumptions taken, and the next candidate features or fixes.
- **Report tests on demand.** Alex can ask at any time for a report of all tests and their status.
- **Flag improvements.** Raise opportunities to improve the codebase, security or flexibility as you see them.
- **Start with the open questions** at the end of this brief. Write no code until Alex has answered them.

## Product

The app takes the text of a book and helps one author turn it into an illustrated, print-ready PDF, working chapter by chapter and scene by scene. The author reviews and refines every step, so the product has its own human-in-the-loop gates.

| Slice | The author can | Human gate in the product |
| --- | --- | --- |
| 1. Manuscript | Paste or upload text; have it split into chapters, then scenes or pages; edit the split | Approve the structure |
| 2. Book bible | Define characters, settings and one art style, with reference images | Approve the bible |
| 3. Illustration | Get a proposed illustration brief per scene; generate, compare, regenerate and edit images; keep every version | Approve each image |
| 4. Layout | Choose a page template per book type; place text and images; preview spreads | Approve each chapter |
| 5. Export | Run print preflight and export a print-ready PDF | Sign off the book |

Both book types are in scope, through layout templates:

- **Picture book:** an illustration on most pages, with short text.
- **Illustrated chapter book:** mostly text, with an illustration per chapter or scene.

Product constraints:

- **Consistency is the hard problem.** Characters and style must look the same across the whole book. The book bible and reference images exist to solve this.
- **Every generation is versioned** with its prompt, model, cost and approver, so any page can be reproduced or rolled back.
- **Spend is capped.** Image generation costs money per image; enforce a per-book budget and show running cost.
- **Text rights.** Use only text Alex wrote or public-domain text. Do not prompt for the style of a named living artist or for existing characters.

## Decisions and assumptions

Alex has decided the first four rows. The rest are assumptions drawn from his standing defaults; confirm each before relying on it.

| Topic | Position | Status |
| --- | --- | --- |
| Book types | Picture books and illustrated chapter books, through layout templates | Decided |
| Stack | React front end, ASP.NET Core API, hosted in Azure | Decided |
| Working style | Agents build; Alex approves specs, reviews every pull request and gates releases | Decided |
| Timeline | No fixed deadline; build in phases and learn each step properly | Decided |
| Source control | New GitHub repository, public, with protected main | Assumed |
| Hosting cost | As cheap as Azure allows; scale to zero where possible | Assumed |
| Sign-in | Google sign-in through a library, with no identity broker | Assumed |
| Auditing | Who did what, visible in Azure Monitor and Log Analytics | Assumed |
| Testing | Every feature has tests; the build fails below an agreed coverage threshold | Assumed |
| Libraries | Current, well-supported libraries in preference to hand-rolled code | Assumed |
| Naming | "Illustrated Book Studio" is a working title; the final name must avoid existing trademarks | Assumed |
| Users | Single author at first, designed so more users can be added | Assumed |

The repository should be public for two reasons. GitHub's free plan offers deployment approval by required reviewers, and code scanning, only on public repositories. A public repository also serves as the portfolio piece.

## Architecture guardrails

These are constraints, not a design. Propose the design as ADRs, each with options, a recommendation and a monthly cost estimate, and wait for Alex's approval.

- **Shape:** React single-page app, ASP.NET Core API, a relational database, blob storage for images and PDFs, and a queue with a background worker for generation jobs.
- **Long-running work is asynchronous.** Image generation and PDF export run as queued jobs with status, retry and cancel.
- **Infrastructure as code.** Define all Azure resources in Bicep. Create nothing by hand in the portal.
- **No stored cloud credentials.** GitHub Actions signs in to Azure through OpenID Connect federation. Runtime secrets live in Key Vault and are read through managed identity.
- **Environments:** staging and production, built from the same templates.

AI providers:

- **Text work uses Claude:** splitting the manuscript, extracting characters and settings, and writing illustration briefs.
- **Images come from a separate image model.** Claude does not generate raster images.
- **DALL-E is not an option.** OpenAI removed DALL-E 2 and 3 from its API on 12 May 2026; its GPT Image models replace them. Check the current model and its ID when you build.
- **Put every model behind an interface.** The DALL-E removal is the reason: providers retire models, so a swap must be a configuration change. Offer Alex the choice between calling OpenAI directly and using an Azure-hosted image model.
- **Supply a fake provider** that returns fixed text and placeholder images. CI and local development use it, so tests are free, fast and repeatable.
- **Treat book text as untrusted input.** It is passed to a model, so it can carry prompt injection. Keep it separate from instructions and never let model output trigger actions unchecked.

Print output:

- **Resolution.** Print commonly needs about 300 dots per inch plus bleed, which is more pixels than image models return. Plan an upscaling step and a preflight check that fails low-resolution pages.
- **Printer spec.** Trim size, bleed, colour profile and PDF standard depend on the print service. Ask Alex which service he intends to use and build to its published spec.
- **PDF engine.** Compare a .NET PDF library with HTML-to-PDF through a headless browser, and record the choice as an ADR.

## Delivery pipeline

Every change follows the same seven stages, and four of them stop for Alex. Tool names are candidates to confirm with him, not decisions.

| Stage | Agent does | Automated checks | Human gate |
| --- | --- | --- | --- |
| 1. Spec | Turns a GitHub issue into a user story with testable acceptance criteria | Issue template complete; criteria are testable | **G1:** Alex approves the spec |
| 2. Plan | Proposes the design, task list and test plan; drafts an ADR if architecture changes | ADR present when architecture changes | **G2:** Alex approves the plan for anything beyond a small change |
| 3. Build | Writes code and tests on a branch; opens a pull request | Pre-commit: format, lint, secret check | None |
| 4. Verify | A separate reviewer agent critiques the pull request against the spec | Build; unit and integration tests; coverage threshold; lint; static analysis (CodeQL); dependency review; secret scanning; infrastructure scan; licence check | **G3:** Alex reviews and approves the pull request |
| 5. Staging | Deploys on merge; writes release notes | End-to-end tests (Playwright); dynamic security scan (OWASP ZAP baseline); accessibility checks; AI evals | None |
| 6. Production | Prepares the release summary and rollback steps | Smoke tests after deploy; automatic rollback on failure | **G4:** Alex approves the deployment |
| 7. Operate | Triages alerts and failed runs into issues | Monitoring, audit log, cost alerts | Alex prioritises the backlog |

How the gates are enforced:

- **G1 and G2** use issue labels. The build agent starts only on an issue labelled as approved.
- **G3** uses a branch rule on main: pull request required, all status checks passing, one approving review.
- **G4** uses a GitHub environment named production with Alex as required reviewer.

Points to settle in Phase 0:

- **Who authors the pull request.** GitHub does not let an author approve their own pull request. Agent-authored pull requests, opened by the Claude GitHub App, leave Alex free to approve. Confirm this behaviour and design G3 around it.
- **Checks on agent commits.** GitHub does not start workflows for commits pushed with the default workflow token. Let the action authenticate as the Claude GitHub App so CI runs on agent commits.
- **AI evals are a test type.** Keep a small set of sample chapters with expected scene splits and briefs, score model output against them, and fail the stage on regression. This is how a prompt or model change gets tested.

## Agent roles and guardrails

Each role is a separately configured agent with its own instructions and the narrowest tool access that lets it do its job.

| Role | Triggered by | Produces | Access |
| --- | --- | --- | --- |
| Spec agent | New issue | User story and acceptance criteria, as an issue comment | Read code; write issue comments |
| Planner | G1 approval | Design, task list, test plan, draft ADR | Read code; write issue comments |
| Builder | G2 approval | Branch, code, tests, pull request | Write to feature branches only |
| Reviewer | Pull request opened or updated | Review comments against spec and standards | Read code; write review comments |
| Security reviewer | Pull requests touching sign-in, secrets, infrastructure or AI calls | Threat-focused review comments | Read code; write review comments |
| Release agent | Merge to main | Release notes and rollback steps | Read code; write release notes |
| Triage agent | Failed run or alert | Issue with diagnosis and suggested fix | Read logs; write issues |

Build the roles with Claude Code's own mechanisms:

- **`CLAUDE.md`** holds project standards that every agent reads. Keep it short.
- **Subagents** in `.claude/agents/` define the roles above.
- **Skills** in `.claude/skills/` hold repeatable procedures, such as writing an ADR or producing the test report.
- **Hooks** run format and lint after edits in local sessions.
- **The Claude Code GitHub Action** (`anthropics/claude-code-action@v1`) runs agents in the pipeline. It responds to `@claude` mentions, or runs unattended when a workflow supplies a prompt. Run `/install-github-app` in Claude Code to set it up.

Guardrails, enforced in configuration and not just in instructions:

- **Agents never approve.** They cannot approve pull requests or deployments, and cannot merge.
- **Agents cannot change the rules.** Changes under `.github/`, to branch rules, coverage thresholds or agent definitions need Alex as code owner.
- **Reviewer independence.** The reviewer runs in a fresh context and never reviews its own work.
- **Least privilege.** Each workflow declares minimal permissions and an explicit list of allowed tools.
- **Trigger control.** Only people with write access can start an agent run. Issue and comment text from anyone else is untrusted input.
- **Bounded runs.** Set a turn limit, a job timeout and a concurrency limit on every agent workflow.
- **Traceability.** Every agent pull request links its issue, approved spec, plan and run log.
- **Tests are the contract.** Flag any pull request that deletes or loosens existing tests, so an agent cannot pass by weakening them.

## Phased plan

The pipeline comes first, so every product feature is delivered through it. Finish each phase's exit test before starting the next, and branch at each phase boundary.

| Phase | Builds | Exit test |
| --- | --- | --- |
| 0. Foundations | Repository, `CLAUDE.md`, operating model document, ADR template, issue and pull request templates, branch rule on main | A one-line change reaches main only through a reviewed pull request |
| 1. Skeleton and CI | Minimal React app, API and database; format, lint, build, unit tests, coverage threshold | A pull request with a failing test or lint error cannot merge |
| 2. Security gates | Static analysis, dependency review, secret scanning with push protection, infrastructure scan, licence check, bill of materials | A planted fake secret and a known-vulnerable dependency are both blocked |
| 3. Deploy path | Bicep templates, OpenID Connect sign-in to Azure, automatic staging deploy, end-to-end, dynamic security and accessibility tests, production environment with approval | A change reaches production only after Alex approves, and a failed smoke test rolls it back |
| 4. Agent workflows | Claude Code GitHub Action, the seven agent roles, label-driven gates, guardrails, run metrics | An issue becomes a merged, deployed change with Alex acting only at G1 to G4 |
| 5. Manuscript | Text import, chapter and scene splitting, structure editor, sign-in, audit log | A sample book is imported and its structure approved |
| 6. Bible and illustration | Book bible, illustration briefs, image generation, versions, approvals, budget cap, AI evals | Ten scenes illustrated with consistent characters, within budget |
| 7. Layout and export | Both page templates, spread preview, preflight, PDF export | An exported PDF passes the chosen print service's checks |
| 8. Operate and measure | Dashboards, alerts, runbook, pipeline metrics, written case study | Alex can present the metrics and what he would change |

From Phase 5 onward, each feature is an issue that flows through all seven pipeline stages. Keep issues small enough that a pull request can be reviewed in one sitting.

Metrics to capture from Phase 4:

- **Flow:** lead time from approved spec to production, deployment frequency, change failure rate, time to restore.
- **Agent quality:** share of agent pull requests merged without rework, review comments per pull request, defects found after merge.
- **Gate value:** what each gate caught, and how long each human gate waited.
- **Cost:** model spend and CI minutes per merged pull request.

## Learning protocol

Alex learns by deciding, reviewing and breaking things, so run each phase as a lesson with the same five steps.

1. **Brief.** Before starting, explain in under a page what the phase adds, the problem it solves, and the main alternatives. Define each new term once.
2. **Decide.** Put the choices to Alex as a survey with a recommendation and the trade-offs. Record the outcome as an ADR.
3. **Build.** Work in small pull requests. In each description, say what to look at and why, so the review itself teaches.
4. **Break it.** Give Alex a drill that makes the new gate fire, such as committing a fake secret. He runs it and sees the failure.
5. **Debrief.** Add an entry to `docs/learning-log.md` covering what was built, what it prevents, what it costs, and how a company would do it differently.

Each debrief ends with three interview talking points written in Alex's voice: a decision he made, a trade-off he accepted, and something that went wrong and what he changed.

Pitch explanations at an engineer who knows software and Azure. Do not assume prior depth in pipeline design or agent tooling. Expand acronyms on first use.

## Corporate considerations

A personal project hides most of what makes this hard in a company: many teams, existing controls, auditors and risk owners. Cover each topic below in the relevant phase debrief, and note in the operating model document how this project handles it.

| Topic | What a company has to settle | Where this project shows it |
| --- | --- | --- |
| Accountability | A named human is accountable for every change. Agents are tools, not owners | G1 to G4; operating model document |
| Autonomy levels | Which tasks agents may do unattended, which need approval, and which are off limits, by risk | Agent access table; label-driven gates |
| Segregation of duties | The author of a change cannot approve it. Auditors expect evidence for each change | Agent authors, Alex approves; linked issue, spec, review and deployment record |
| Data and intellectual property | What code and data may be sent to a model provider, under what retention terms, and through which cloud | Provider interface; note on routing through a company's own cloud account |
| Agent security | Least-privilege identities, prompt injection, secrets exposure, and agents changing their own controls | Guardrails section; security reviewer; code owner rule on `.github/` |
| Supply chain | Pinned dependencies and actions, bill of materials, provenance of build outputs | Phase 2 gates |
| Quality of AI output | Tests as the contract, independent review, evals for prompts and models, and review fatigue in humans | Reviewer independence; AI evals; small pull requests |
| Cost | Token and compute budgets, cheaper models for simpler roles, and limits on runaway runs | Bounded runs; cost metrics |
| Measurement | A baseline before rollout, then flow, quality and cost measures to show the effect | Phase 4 metrics; Phase 8 case study |
| Adoption | Start with one pilot team, set guardrails before autonomy, train reviewers, and widen in stages | Phase order: gates first, agents fourth |
| Regulation and policy | An AI use policy, and how AI-assisted changes fit existing change-management controls | Operating model document |

Background reading to bring into the debriefs, each summarised in a paragraph when first relevant:

- **DORA metrics**, the four standard measures of delivery performance.
- **OWASP Top 10 for LLM Applications**, the common security risks in AI features and agents.
- **NIST Secure Software Development Framework** and **SLSA**, for secure pipelines and supply chains.
- **NIST AI Risk Management Framework** and **ISO/IEC 42001**, for governing AI use.
- **EU AI Act**, for obligations that may apply to a company's AI systems.
- **SOC 2 and ISO 27001 change management**, the controls auditors usually test in a pipeline.

Two points specific to the book app are worth raising with Alex, and neither is legal advice. Copyright in AI-generated images is treated differently across countries. Print and publishing services may require AI-generated content to be declared.

## Open questions for Alex

Ask these as one survey at the start of the first session, each with options and a recommendation.

- [ ] **Name.** What should the repository and app be called? Check the name against existing trademarks.
- [ ] **Visibility.** Is a public repository acceptable? If not, which gates need a paid plan or a different design?
- [ ] **Job spec.** Does the role name a platform, such as GitHub, Azure DevOps or GitLab? If so, should the pipeline mirror it?
- [ ] **Claude sign-in for the pipeline.** Should the GitHub Action use an API key or a Claude subscription token?
- [ ] **Image provider.** OpenAI directly, or an Azure-hosted image model? What is the monthly spending cap?
- [ ] **Print service.** Which service and trim sizes should the export target?
- [ ] **First book.** Which text will be the test manuscript, and is it Alex's own or public domain?
- [ ] **Database and hosting.** Which of the costed options in the hosting ADR does Alex choose?
- [ ] **Domain.** Should the app sit on a subdomain of Alex's personal domain, or on a new one?
- [ ] **Sign-in.** Google only at first, or Apple as well?
- [ ] **Coverage threshold.** What minimum test coverage should block a merge?
- [ ] **Small changes.** What counts as small enough to skip the plan gate, G2?

## Sources

Checked on 7 October 2026. Re-check each before relying on it, because plan limits and model line-ups change.

- [Claude Code GitHub Actions](https://code.claude.com/docs/en/github-actions): setup, trigger modes, who can start a run, sign-in secrets, cost controls, and why CI may not run on agent commits.
- [GitHub: deployments and environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments): required reviewers are limited to public repositories on Free, Pro and Team plans.
- [GitHub: about protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches): available for public repositories on the Free plan; required status checks.
- [GitHub: about code scanning](https://docs.github.com/en/code-security/code-scanning/introduction-to-code-scanning/about-code-scanning): available for public repositories; private repositories need a GitHub Code Security licence.
- [OpenAI: deprecations](https://developers.openai.com/api/docs/deprecations): DALL-E 2 and 3 removed from the API on 12 May 2026.
- [OpenAI: DALL-E 3 model page](https://developers.openai.com/api/docs/models/dall-e-3): current recommendation for image generation.

Not verified against a source: that GitHub blocks authors from approving their own pull requests, and the print resolution guidance. Both are flagged in the text for confirmation.
