#!/usr/bin/env bash
# Review triage helper (ADR 0018): record a thread the agent is deliberately not replying to, without posting.
#   eng/triage/note-skip.sh <pr-number> <comment-database-id> <reason>
# Use it for threads whose last comment is not the reviewer's (a person or the agent already replied), so the
# status check shows the thread was seen. Recorded as verdict "in-discussion", never blocking.
set -euo pipefail
pr="${1:?pull request number}"; comment_id="${2:?comment database id}"; reason="${3:?reason}"
[[ "$pr" =~ ^[0-9]+$ && "$comment_id" =~ ^[0-9]+$ ]] || { echo "pull request and comment ids must be numeric" >&2; exit 2; }
mkdir -p .triage
python3 - "$pr" "$comment_id" "$reason" <<'PY' >> .triage/findings.jsonl
import json, sys
pr, cid, reason = sys.argv[1:4]
print(json.dumps({"pr": int(pr), "comment_id": int(cid), "verdict": "in-discussion", "blocking": False, "summary": reason[:200], "issue": None}))
PY
