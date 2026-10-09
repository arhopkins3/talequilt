# Learning log

One entry per phase: what was built, what it prevents, what it costs, how a company would do it differently, and three interview talking points in Alex's voice.

## Phase 0: Foundations (October 2026)

**What was built.** A public repository with a founding brief, an operating model, thirteen ADRs, issue and pull request templates, a CODEOWNERS file, the MIT licence, and a ruleset on `main` that requires a pull request and blocks direct and force pushes.

**What it prevents.** Unreviewed change to the trunk, by a person or an agent. Undocumented decisions. Agents editing their own controls without the owner noticing (CODEOWNERS now, enforced in Phase 4).

**What it costs.** Nothing in money. In time, every change now takes a branch, a pull request and a merge click, which is the point.

**How a company would do it differently.** Organisation-level rulesets that teams cannot override; CODEOWNERS pointing at teams; a central ADR index and review board; required approvals from day one because a team has more than one person.

**Drill result (9 October 2026).** Ruleset applied, then from a local clone: a direct push to `main` was rejected, a force push was rejected, and deleting `main` was rejected. The fourth check, that a pull request with an unresolved review thread cannot merge, is run on the pull request that carries this entry. The live ruleset read back through the API matched the table in the Phase 0 brief rule for rule: deletion blocked, non-fast-forward blocked, pull request required with zero approvals, stale approvals dismissed on push, review threads must be resolved, and an empty list of required status checks ready for Phase 1.

**What went wrong and what changed.**

1. The first push from the agent landed on an empty repository, so GitHub made the agent's feature branch the default branch. Alex seeded `main` by hand, as a platform team would, and set it as default. The ADRs now say explicitly that bootstrap is a human act.
2. `main` was created from the agent's branch rather than as an empty branch, so the brief and the survey reached `main` without a pull request. Harmless for two documents, but it is exactly the kind of thing the gate exists to stop, and it happened before the gate existed. Lesson: switch the ruleset on before the first merge, not after.
3. GitHub forbids self-approval, and until Phase 4 every pull request is authored under Alex's account. Required approvals are therefore zero until agent-authored pull requests exist, recorded in ADR 0013 rather than worked around with an admin bypass.
4. The Phase 0 and Factory Console pull requests were both merged before the ruleset was applied, so the exit test was passed after the fact rather than by the merges themselves. The drill proved the gate; the order of events did not. In a company the ruleset is part of creating the repository, so no merge can precede it.
5. The first Pages deployment failed because GitHub Pages had not been switched on for the repository. The workflow deliberately lacks the administration permission that would let it enable Pages itself, so the fix was a one-time human setting, after which a re-run succeeded. One-time platform setup belongs to a person; workflows only deploy.

**Interview talking points.**

- *A decision I made:* "I made the repository public even though it is a learning project, because the controls I wanted to demonstrate, required reviewers and code scanning, are free only on public repositories. I treated the cost of visibility as lower than the cost of a paid plan or a weaker demo."
- *A trade-off I accepted:* "My branch rule has zero required approvals for now. The honest reason is that GitHub will not let an author approve their own pull request and I am the only author until the agents open pull requests. I chose to document that gap and close it in Phase 4 rather than hide it behind an admin bypass that I would use on every merge."
- *Something that went wrong:* "I merged the first two pull requests before the branch ruleset was switched on, so for a day the gate existed on paper and not in GitHub. Running the drill afterwards proved the rule worked, but it also proved I had done things in the wrong order. In a company I would make the ruleset part of repository creation, so no merge can ever precede it."

### Background reading introduced this phase

**SOC 2 and ISO 27001 change management.** Both frameworks ask the same questions of a pipeline: is every production change authorised, tested, reviewed by someone other than its author, and traceable from request to deployment? Auditors sample merged changes and ask for the evidence. A protected trunk with required pull requests, linked issues and recorded approvals is the evidence. Phase 0 puts the first of those controls in place and Phases 1 to 4 add the rest.

## Phase 1: Skeleton and CI (October 2026)

**What was built.** A thin working system: a React app that shows API health and books, an ASP.NET Core API with three endpoints and one table, and a worker that beats on a timer. Around it, the first automated gate: a CI workflow whose three jobs are required status checks on `main` (build, format, tests and an 80 percent coverage floor for .NET; format, lint, types, tests with the same floor and a production build for the web; a docs and status check). Then the first agent in the pipeline, the review triage agent, which reads every Copilot finding, verifies it against the code and replies with a verdict, with no power to edit, resolve, approve or merge. And the Factory Console grew a live flow: one animated lane per open pull request, from push through checks, Copilot, the agent, Alex's gate and merge, then `main`'s own lane, where Pages now deploys only after CI is green.

**What it prevents.** A pull request that does not build, fails a test, breaks a lint rule or drops coverage cannot merge, whoever or whatever opened it. A reviewer's finding no longer sits unread: each gets a verdict with reasoning, a `fix-now` keeps the agent's check red until the diff proves the fix, and a "fixed in the next commit" comment proves nothing. The docs site cannot publish a commit CI has not passed.

**What it costs.** CI minutes are free on a public repository. The agent costs model spend per pull request, visible in the Console; today's work ran it about a dozen times. In time, every finding now costs a verdict to read, and every fix a re-verification round, which is the price of not trusting comments.

**How a company would do it differently.** Pipeline templates owned by a platform team so no product team can drop a check; reviewer agents with their own identities and least-privilege tokens rather than the repository token; findings stored as data for metrics, not only as comments; and a merge queue once there is more than one author.

**Drill result (9 October 2026).** Three pull requests, each with one deliberate fault, each verified locally to fail exactly one thing before it was pushed. All three were stopped by the check they were built to trip, with every other check green and the merge button disabled, and were closed unmerged.

| Pull request | Fault | Red | Copilot | Triage agent |
| --- | --- | --- | --- | --- |
| #14 | A Core test for behaviour nobody implemented | `API build and test`, 1 of 10 Core tests failed | Nothing found | Nothing to judge; green |
| #15 | `let` for a value never reassigned | `Web build and test`, one ESLint error | Found it | Accurate, then excused it because the description said "drill" |
| #16 | A worker retry calculator with no tests | `API build and test`, Worker coverage 36 percent against 80 | Found the missing tests and a real bug in the calculator | Two `fix-now`; confirmed the fix was safe; corrected Copilot's line reference |

Two things the drill taught beyond what it was built to prove. The failing test on #14 was invisible to every reader, human or model, because the diff looks like a reasonable test; only running it exposed the lie. Review and tests are different gates and neither replaces the other. And the code on #16 carried an unplanned bug (an exponent clamp that stops the delay growing before it reaches its cap) which a single test for the cap would have caught: the coverage floor is not about a number, it is about that test existing.

**What went wrong and what changed.**

1. The first web CI run failed on ESLint after the agent read local output as passing without checking the exit code. The rule since: a check has passed when its exit code says so, not when the output looks fine.
2. The .NET 10 SDK runs xunit v3 through a new test platform, and the usual coverage package does not run under it. Coverage moved to a script Alex owns, which also made the threshold visible in one place.
3. Copilot's review of the triage agent's own pull request found that the agent could run arbitrary API calls, that its blocking decision was trusted from the model, and that it looked for the wrong reviewer login. The agent now acts only through four helper scripts, the check derives blocking from recorded verdicts, and the login is right.
4. The agent's first unattended run was held by GitHub because a bot had triggered it. It now starts on the push and waits for the reviewer instead.
5. The Claude GitHub App refuses to run when the agent's own workflow file differs from `main`, which is a guardrail; the check now says "Agent did not run" rather than reporting a clean zero.
6. The agent's first live run exposed the loophole it was built to close: once the author replied "fixed in <sha>", the thread was filed as in discussion and the check went green with no one reading the diff. Re-verification now takes precedence over every other rule, the agent recognises its own verdicts by login and footer together, and it keeps re-checking after `fixed` so a regression turns the check red again. The fix proved itself the same afternoon: the agent replied `fixed`, stating that it had confirmed the change in the diff and not from the author's comment.
7. The live flow panel squeezed every panel below it into a strip 265 pixels wide, because a rule written for the twelve-column grid was applied to a panel outside it. Rendering checks at phone width did not catch it; desktop width did.
8. The `main` lane drew CI then Pages as a sequence while the two ran in parallel, so the site showed as live before CI had finished. Alex chose to make the pipeline match the picture: Pages now runs after CI succeeds and deploys the commit CI tested.
9. In the drill, the same agent role gave two answers to a pull request that called itself a drill: on #15 the description excused an accurate finding, on #16 it did not. Pull request descriptions are untrusted input, and the role currently reads them for intent. Phase 2 adds the rule that a description can explain a finding but never excuse one.
10. The agent reads its role file from the pull request's own checkout, so a pull request can change how the agent judges that same pull request. Only the workflow file is pinned to `main`. Phase 2 closes this.

**Interview talking points.**

- *A decision I made:* "I put an AI agent into the review loop, but I gave it no hands. It can read the code and it can reply on a thread through four small scripts that validate what it passes them. It cannot edit a file, resolve a thread, approve or merge. Its verdicts feed a status check, so its judgement is visible and overridable, and the thing it is not allowed to do is exactly the thing I would least want to discover it had done."
- *A trade-off I accepted:* "The docs site now deploys a couple of minutes later than it could, because I made the deploy wait for CI. The site is static and the merge gate already required green CI, so the old parallel deploy was arguably fine. I changed it because the dashboard drew the deploy as waiting for CI when it was not, and a dashboard that implies a control that does not exist is worse than no dashboard. In a pipeline that ships software, a deploy that does not wait for CI is a finding, so I wanted the habit in place before Phase 3."
- *Something that went wrong:* "I built the agent to stop a specific bad habit, trusting a comment that says 'fixed in the next commit'. Its first live run showed it had the same habit in a different form: when the author replied 'fixed in abc123', it filed the thread as in discussion and turned its check green without reading the diff. The fix was a precedence rule, re-verify first, whoever spoke last, and it proved itself the same afternoon. The lesson I keep is that a guardrail is a hypothesis until a real run has tried to get round it."

### Background reading introduced this phase

**OWASP Top 10 for LLM Applications.** The first item on that list is prompt injection: an attacker puts instructions where a model will read them as data, and the model acts on them. Phase 1 met it twice in miniature. The triage agent reads review comments and the pull request description, both written by whoever opened the pull request, and in the drill a description saying "this is a drill" was enough to turn an accurate finding into "not an issue". The defences the list recommends are the ones this pipeline is building: treat model-read text as untrusted, keep the model's powers minimal (here, four scripts and no write tools), require a human for consequential actions (Alex resolves, approves and merges), and never let a claim in the text stand in for a check against the ground truth (the diff).
