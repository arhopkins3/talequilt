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
