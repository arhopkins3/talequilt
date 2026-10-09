# 0020. Triage agent hardening: rules from main, intent never excuses a finding, honest cancellation

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 2

## Context

The Phase 1 drill and the first day of live runs found three gaps in the review triage agent (ADR 0018). First, the agent read its role file, its Claude settings and hooks, and its helper scripts from the pull request's own checkout, so a pull request could rewrite how the agent judged that same pull request; only the workflow file was protected, by the Claude GitHub App's refusal to run a changed workflow. A hook in `.claude/settings.json` is the sharpest form of this: it runs a command on the agent's tool calls, with the agent's token. Second, the same role gave two different answers to pull requests that described themselves as drills: on #15 the description excused an accurate finding (`not-an-issue`), on #16 it did not (`fix-now`). The description is untrusted input and the role read it for intent without saying what intent may and may not do. Third, when a newer push cancelled a run in progress, the report step read the cancelled agent step as "failed to run" and left a red check on the superseded commit.

The agent also made a claim about commit history on #17 ("not in the PR head's history") that was false, because its checkout is shallow and it cannot see history.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| Take `.claude/` and `eng/triage/` from `main` at run time, after checking out the pull request head | Closes the door the App leaves open; small; the agent still reads the pull request's code | Changes to the agent take effect only after merge, so a pull request cannot test a new role on itself (already true of the workflow) |
| Rely on CODEOWNERS for `.claude/` and `eng/` | No workflow change | CODEOWNERS enforces nothing until required approvals exist (Phase 4, ADR 0013), and even then it governs merge, not the run on the pull request |
| Run the agent from a separate repository | Strongest separation | Far more moving parts for one agent |
| Intent rule: a description explains, never excuses; intent as the only defence is `needs-alex` | Consistent verdicts; the human decides when intent matters | More `needs-alex` verdicts on deliberate-fault pull requests, which is the point |
| Let the agent weigh intent itself | Fewer human decisions | The drill showed it weighs the same intent differently on different days |
| Report a cancelled run as `cancelled`, "superseded by a newer push" | Red means something again | None |

## Decision

The workflow checks out the pull request head, then replaces `.claude/` and `eng/triage/` with `main`'s copies before the agent runs, and prints the diff it discarded. The role states that the checkout is shallow and that history is not something it can judge. The role's first step now says intent can explain a finding but never excuse one, and that an accurate finding whose only defence is the description's stated purpose is `needs-alex`. The report step concludes `cancelled` with "Superseded by a newer push" when the job was cancelled, instead of "failed to run".

## Consequences

A pull request that changes the agent's rules runs against the old rules, so the first live test of any role change happens on the next pull request after it merges; Phase 2's drill step 5 tests exactly this by editing the role in a pull request and expecting the agent to judge on its merits. Deliberate-fault pull requests (drills) will collect `needs-alex` verdicts that keep the agent's check red until Alex resolves them, which is correct: the check is not yet required, and when it is, a drill will need Alex's resolution to merge, which a drill never does. The cancellation change removes a class of misleading red checks on superseded commits.

## At company scale

Agent policy (roles, allowed tools, hooks) lives in a separate, tightly owned repository or an organisation-level configuration, versioned and signed, and the workflow fetches a pinned release of it; no product repository can alter it. Verdict consistency is measured: the same finding class should get the same verdict, and drift is a defect. Cancelled and superseded runs are first-class states in the delivery dashboard, not failures.
