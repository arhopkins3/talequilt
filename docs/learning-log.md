# Learning log

One entry per phase: what was built, what it prevents, what it costs, how a company would do it differently, and three interview talking points in Alex's voice.

## Phase 0: Foundations (October 2026)

**What was built.** A public repository with a founding brief, an operating model, thirteen ADRs, issue and pull request templates, a CODEOWNERS file, the MIT licence, and a ruleset on `main` that requires a pull request and blocks direct and force pushes.

**What it prevents.** Unreviewed change to the trunk, by a person or an agent. Undocumented decisions. Agents editing their own controls without the owner noticing (CODEOWNERS now, enforced in Phase 4).

**What it costs.** Nothing in money. In time, every change now takes a branch, a pull request and a merge click, which is the point.

**How a company would do it differently.** Organisation-level rulesets that teams cannot override; CODEOWNERS pointing at teams; a central ADR index and review board; required approvals from day one because a team has more than one person.

**Drill result.** To be recorded by Alex after running the drill in `docs/phases/phase-0-foundations.md`.

**What went wrong and what changed.**

1. The first push from the agent landed on an empty repository, so GitHub made the agent's feature branch the default branch. Alex seeded `main` by hand, as a platform team would, and set it as default. The ADRs now say explicitly that bootstrap is a human act.
2. `main` was created from the agent's branch rather than as an empty branch, so the brief and the survey reached `main` without a pull request. Harmless for two documents, but it is exactly the kind of thing the gate exists to stop, and it happened before the gate existed. Lesson: switch the ruleset on before the first merge, not after.
3. GitHub forbids self-approval, and until Phase 4 every pull request is authored under Alex's account. Required approvals are therefore zero until agent-authored pull requests exist, recorded in ADR 0013 rather than worked around with an admin bypass.

**Interview talking points.**

- *A decision I made:* "I made the repository public even though it is a learning project, because the controls I wanted to demonstrate, required reviewers and code scanning, are free only on public repositories. I treated the cost of visibility as lower than the cost of a paid plan or a weaker demo."
- *A trade-off I accepted:* "My branch rule has zero required approvals for now. The honest reason is that GitHub will not let an author approve their own pull request and I am the only author until the agents open pull requests. I chose to document that gap and close it in Phase 4 rather than hide it behind an admin bypass that I would use on every merge."
- *Something that went wrong:* "The first content reached main without a pull request, because main was branched from the agent's branch before the ruleset existed. It taught me that the order matters: the gate has to exist before the first merge, and in a company I would make the ruleset part of repository creation, not a follow-up task."

### Background reading introduced this phase

**SOC 2 and ISO 27001 change management.** Both frameworks ask the same questions of a pipeline: is every production change authorised, tested, reviewed by someone other than its author, and traceable from request to deployment? Auditors sample merged changes and ask for the evidence. A protected trunk with required pull requests, linked issues and recorded approvals is the evidence. Phase 0 puts the first of those controls in place and Phases 1 to 4 add the rest.
