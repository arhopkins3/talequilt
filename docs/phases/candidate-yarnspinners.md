# Candidate phase: Yarnspinners, a community of parents writing for their children

**Status:** candidate, not scheduled. Recorded on 25 November 2026 so the idea and its constraints are written down before anything is built towards it. It is not in the nine-phase plan (`docs/operating-model.md`) and nothing in Phases 4 to 8 depends on it.

**Exit test, if adopted:** a parent who is not Alex signs up, writes a story for their child, has it illustrated and laid out by the app, downloads the print-ready PDF, and keeps the rights to every word they wrote, without Alex touching anything by hand.

## The idea

Yarnspun makes one author's manuscript into an illustrated book. Yarnspinners would open the same tool to a community of people who want to write stories for their children, with the model helping rather than writing: illustration, layout, suggestions on request, never text the author did not ask for. The names come from the same root (ADR 0022): the maker is a yarnspinner, the book is yarnspun. Members would be able to share what they made with each other if they chose, and to keep it private if they did not.

## What it changes

Everything the current design deliberately keeps off, because the app has one author (ADR 0008):

| Area            | Today                                                                                      | With a community                                                                                                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Sign-in         | Invited GitHub users through Static Web Apps, removed in Phase 5 for the app's own sign-in | Self-service accounts for strangers, password or social sign-in, recovery, deletion                                                                                                                   |
| Who may write   | Alex (CLAUDE.md rule 9: only text Alex wrote)                                              | Each member writes their own text and keeps the rights to it; the rule becomes "only text the author wrote", and the app must be able to prove whose text is whose                                    |
| Untrusted input | Book text is untrusted on its way to the model (rule 6)                                    | The same, now from people who may be hostile; prompt injection attempts become routine, and model output shown to other members is a second untrusted channel                                         |
| Children        | None involved as users; the book is about a child the author knows                         | Still parents as users, but content about children at scale: UK GDPR, the Age Appropriate Design Code, and the question of whether any child ever uses the app directly (if yes, a different product) |
| Cost            | A budget per environment, alerts to Alex                                                   | Model spend per member, so the budget becomes pricing, quotas or both; abuse of the image model is a cost attack                                                                                      |
| Moderation      | None needed                                                                                | Reporting, review, takedown, and what a model may refuse to illustrate; a published-content policy                                                                                                    |
| Legal           | None published                                                                             | Terms, privacy notice, content licence, age statement, complaints route                                                                                                                               |
| Operations      | One person watching                                                                        | Support, incident response for other people's data, backups that matter                                                                                                                               |

## Constraints the factory already satisfies

Nothing in the pipeline cares how many users there are. The API treats book text as untrusted input, every model sits behind an interface with a fake for CI, the deploy path is the same for one user or a thousand, production is behind G4, and promotion is gated by end-to-end, accessibility and security scans. A community phase would add tests, not gates.

## Prerequisites

1. Phases 4 to 8 complete: the single-author app works end to end, with sign-in (Phase 5), illustration and layout (Phases 6 and 7) and operations (Phase 8). A community built on an unfinished tool inherits every gap.
2. A decision record on identity for strangers (provider, recovery, deletion), which Phase 5's sign-in decision should keep open rather than close.
3. A decision record on data protection: what is stored about whom, for how long, where, and how a member leaves with their data.
4. A pricing or quota decision, so the model spend of a member who is not Alex has a ceiling before the first one arrives.
5. The name checks in ADR 0022 done.

## Open questions

- Is sharing between members part of the first version, or does the community start as many private authors with a shared front door? The second is far cheaper and most of the value may be there.
- Does the model ever write? The idea says no; the product pressure will say yes. The answer shapes rule 9 and the licence.
- Who moderates at the start, and what happens when Alex is away?
- Would a member pay, and for what: the book, the illustrations, the print?

## Decision needed

None now. When Phase 8 is in sight, Alex decides whether this becomes Phase 9, replaces something, or stays a note. The brief then gets the house treatment: survey with a recommendation, build, drill, debrief.
