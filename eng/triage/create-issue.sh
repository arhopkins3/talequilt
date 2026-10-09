#!/usr/bin/env bash
# Review triage helper (ADR 0018): open a follow-up issue for a deferred finding. Prints the issue URL.
#   eng/triage/create-issue.sh <pr-number> <title> < body.md
# Labels: type/bug plus from-review (created if missing). Body gets a trailer linking the pull request.
set -euo pipefail
pr="${1:?pull request number}"; title="${2:?title}"
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "pull request number must be numeric" >&2; exit 2; }
[ "${#title}" -le 120 ] || { echo "title too long" >&2; exit 2; }
body=$(cat)
full_body="$body

Raised from a review finding on #${pr} by the review triage agent (ADR 0018).

---
_Review triage agent · [Claude Code](https://claude.ai/code)_"
gh label create from-review --color BFD4F2 --description "Opened by the review triage agent for a deferred finding" --force >/dev/null 2>&1 || true
gh issue create --title "$title" --body "$full_body" --label from-review
