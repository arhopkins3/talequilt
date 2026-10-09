#!/usr/bin/env bash
# Review triage helper (ADR 0018): record a thread without posting a reply.
#   eng/triage/note-skip.sh <pr-number> <comment-database-id> <reason> [verdict]
# [verdict] defaults to in-discussion (someone other than the reviewer bot spoke last; never blocking).
# It may also be fix-now or needs-alex, to carry forward a finding this agent raised earlier that a later
# commit has not fixed, so the status check stays red without a new comment on every push.
set -euo pipefail
pr="${1:?pull request number}"; comment_id="${2:?comment database id}"; reason="${3:?reason}"; verdict="${4:-in-discussion}"
[[ "$pr" =~ ^[0-9]+$ && "$comment_id" =~ ^[0-9]+$ ]] || { echo "pull request and comment ids must be numeric" >&2; exit 2; }
case "$verdict" in
  in-discussion) blocking=false ;;
  fix-now|needs-alex) blocking=true ;;
  *) echo "verdict must be in-discussion, fix-now or needs-alex (got '$verdict')" >&2; exit 2 ;;
esac
mkdir -p .triage
python3 - "$pr" "$comment_id" "$verdict" "$blocking" "$reason" <<'PY' >> .triage/findings.jsonl
import json, sys
pr, cid, verdict, blocking, reason = sys.argv[1:6]
print(json.dumps({"pr": int(pr), "comment_id": int(cid), "verdict": verdict, "blocking": blocking == "true", "summary": reason[:200], "issue": None}))
PY
