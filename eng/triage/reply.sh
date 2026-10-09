#!/usr/bin/env bash
# Review triage helper (ADR 0018): post one verdict reply on a review thread and record the finding.
#   eng/triage/reply.sh <pr-number> <comment-database-id> <verdict> <summary> [issue-url] < reply-body.md
# <verdict> must be one of: fix-now | defer | not-an-issue | needs-alex | fixed
#   fixed = a finding this agent earlier marked fix-now has been fixed by a later commit (name it in the body)
# The reply gets the agent footer appended. The finding is appended to .triage/findings.jsonl with the
# blocking flag derived here from the verdict (fix-now and needs-alex block), never supplied by the caller.
# Set TRIAGE_DRY_RUN=1 to record without posting.
set -euo pipefail
pr="${1:?pull request number}"; comment_id="${2:?comment database id}"; verdict="${3:?verdict}"; summary="${4:?one-line summary}"; issue="${5:-}"
[[ "$pr" =~ ^[0-9]+$ && "$comment_id" =~ ^[0-9]+$ ]] || { echo "pull request and comment ids must be numeric" >&2; exit 2; }
case "$verdict" in
  fix-now|needs-alex) blocking=true ;;
  defer|not-an-issue|fixed) blocking=false ;;
  *) echo "verdict must be fix-now, defer, not-an-issue, needs-alex or fixed (got '$verdict')" >&2; exit 2 ;;
esac
if [ -n "$issue" ] && [[ ! "$issue" =~ ^https://github\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/issues/[0-9]+$ ]]; then
  echo "issue must be a github.com issue URL" >&2; exit 2
fi
body=$(cat)
[ -n "$body" ] || { echo "reply body is empty" >&2; exit 2; }
if [ "${#body}" -gt 1500 ]; then echo "reply body too long (${#body} > 1500 characters)" >&2; exit 2; fi
full_body="$body

---
_Review triage agent · verdict: ${verdict} · [Claude Code](https://claude.ai/code)_"
if [ "${TRIAGE_DRY_RUN:-0}" != "1" ]; then
  gh api --method POST "repos/${GITHUB_REPOSITORY}/pulls/${pr}/comments/${comment_id}/replies" -f body="$full_body" --jq .html_url
fi
mkdir -p .triage
python3 - "$pr" "$comment_id" "$verdict" "$blocking" "$summary" "$issue" <<'PY' >> .triage/findings.jsonl
import json, sys
pr, cid, verdict, blocking, summary, issue = sys.argv[1:7]
print(json.dumps({"pr": int(pr), "comment_id": int(cid), "verdict": verdict, "blocking": blocking == "true", "summary": summary[:200], "issue": issue or None}))
PY
