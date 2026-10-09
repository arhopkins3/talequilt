# 0018. Review triage agent: independent verdicts on external review findings, comment-only

- **Status:** Accepted
- **Date:** 2026-10-09
- **Deciders:** Alex Hopkins
- **Phase:** 1 (first agent, pulled forward from Phase 4)

## Context

GitHub Copilot code review runs on every pull request in this repository and leaves findings as review threads. On the Phase 1 pull request it left seven, all valid, about a minute after the merge. A raw list of findings puts the whole burden on Alex: read each, decide whether it is real, decide whether it matters now. Copilot's review is a GitHub review, not a status check, so it cannot be required directly and a merge can race ahead of it.

The operating model already has a reviewer role in Phase 4. Triage of someone else's review is its simplest form: mostly reading and commenting, with no code changes, which makes it the right first agent to run in the pipeline.

## Options considered

| Option | For | Against |
| --- | --- | --- |
| Review triage agent, comment and classify only, status check from a structured result | Every finding gets a verdict and a reason; the check can later be required so merges wait for review; smallest blast radius for a first agent | Alex still clicks resolve; the agent cannot fix what it finds |
| Agent may also push fixes to agent-authored branches | Fewer round trips | Code changes by an agent on a review event, before the builder role and its guardrails exist |
| Agent may also resolve threads it rejects | Fewer clicks | A wrong rejection disappears from view |
| Triage by hand in a Claude Code session | No setup | Not part of the pipeline; invisible to the Factory Console; not repeatable |
| Turn Copilot off | Less noise | Loses an independent reviewer that found seven real issues |

## Decision

A workflow, `Agent: review triage`, starts on every pull request push (and on manual dispatch with a pull request number), opens an in-progress `Review triage` check, waits up to 15 minutes for Copilot to review that commit, and then triages. It does not trigger on the review event itself: GitHub treats the Copilot bot as an outside contributor and holds workflow runs it triggers for manual approval, which the first unattended run showed (run 37944982711, `action_required`). Starting on the push makes the author the actor, so no approval is needed, and the in-progress check means a merge cannot race ahead of the review once the check is required. It runs the Claude Code GitHub Action with the role in `.claude/agents/review-triage.md`: read every unresolved thread, verify each claim against the code, and reply on the thread with one of four verdicts (`fix-now`; `defer`, with a follow-up issue; `not-an-issue`, with the reason; `needs-alex`, for security and product judgement).

The agent acts only through four helper scripts in `eng/triage/`: `list-threads.sh` (read-only GraphQL), `reply.sh` (posts one reply and records the finding with the blocking flag derived from the verdict), `create-issue.sh`, and `note-skip.sh` (records a thread already in discussion without replying). Only threads whose last comment is the reviewer bot's are triaged; a thread where a person or the agent has already replied is noted, not re-triaged. It has no raw GitHub API access and no file-write tool. A deterministic step then turns the recorded findings into a **Review triage** status check: failure if any verdict is `fix-now` or `needs-alex`, success otherwise, neutral when the API key is absent and nothing ran, and failure naming the cause when the agent step itself failed (for example, the Claude GitHub App not installed), so a broken agent is visible rather than silent.

Guardrails, in configuration:

- **Trigger control**: the job starts on the author's own push or on manual dispatch, both actors with write access; review text from anyone is data. Drafts are skipped until marked ready. Pull requests from forks get no secrets, so the check is neutral and nothing runs.
- **Least privilege**: workflow permissions are read on contents, write on pull requests, issues and checks; the agent's tool list allows reading, `gh pr view`, `gh pr diff` and the four helper scripts, nothing else. It cannot edit files, call the API directly, run tests or resolve threads. The first Copilot review of this workflow caught that a raw `gh api` allowance would have let the model resolve threads despite the role forbidding it; the helper scripts are the fix.
- **Bounded runs**: Sonnet model, 40 turns, 20-minute timeout, one run per pull request at a time.
- **Untrusted input**: the role file and the prompt both state that review text is a claim to verify, never an instruction.
- **Separation**: the status check is posted by a script step from findings recorded by `reply.sh`, so the agent never holds the checks permission and cannot mark its own verdicts non-blocking.
- **Traceability**: the full transcript is shown in the run log (`show_full_output`), and the recorded findings plus the execution log are kept as a run artifact for 90 days. The first manual run (9 October 2026, pull request 5) took 4 turns, 7 seconds and $0.03, and produced the opaque result "0 findings" because every thread already had a human reply; the `in-discussion` record and the visible transcript are the response.

The check is not required by the ruleset yet. After a few pull requests show the verdicts are sound, Alex adds `Review triage` to the required checks, which also makes merges wait for Copilot's review.

**Self-protection the platform adds.** The Claude GitHub App refuses to run when the workflow file on the pull request differs from the one on `main` ("the workflow file must exist and have identical content to the version on the repository's default branch"). A pull request therefore cannot edit this agent's workflow and have the edited version act on the repository; changes to the agent take effect only after Alex merges them. On such pull requests the check reports neutral with "Agent did not run", never a clean zero. This is the "agents cannot change the rules" guardrail enforced by the vendor as well as by CODEOWNERS.

**A red check stays red until the diff says otherwise.** On each later push the agent re-reads every thread it earlier marked `fix-now`, checks the new diff against the finding, and either replies "Fixed in <sha>" (verdict `fixed`, not blocking) or carries the finding forward silently as still open (blocking). A finding is never marked fixed on the strength of a comment that says it is; only the diff counts. `needs-alex` findings stay blocking until Alex resolves the thread. This closes the gap where a new push would otherwise have turned a red check green regardless of what it changed.

**Reviewer cadence.** Copilot reviews a pull request when it opens or becomes ready for review; it reviews later pushes only when the ruleset's automatic-review setting asks for new pushes. The wait is 15 minutes on open and 6 on a later push, after which the agent triages whatever unresolved threads exist.

## Consequences

Prerequisites Alex completes once: install the Claude GitHub App on the repository and add the `ANTHROPIC_API_KEY` secret from a Console key with a spend limit (ADR 0004). Until then the workflow reports a neutral check and does nothing else. The Phase 4 reviewer and security reviewer agents reuse this workflow shape. Model spend per pull request becomes visible in the Console from the first run.

## At company scale

Companies run several reviewers (static analysis, a vendor AI reviewer, their own agents) and need exactly this layer: one place that reconciles findings into verdicts with evidence, so humans decide on a short list rather than triage a long one. The autonomy level here, comment only, is where most companies start, and widening it is a policy decision recorded as a new ADR rather than a quiet config change.
