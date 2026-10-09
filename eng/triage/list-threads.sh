#!/usr/bin/env bash
# Review triage helper (ADR 0018): list the unresolved review threads on a pull request as JSON. Read-only.
#   eng/triage/list-threads.sh <pr-number>
# Output: one JSON object per line: {thread, path, line, isResolved, comments:[{id, databaseId, author, body, url}]}
set -euo pipefail
pr="${1:?pull request number}"
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "pull request number must be numeric" >&2; exit 2; }
owner="${GITHUB_REPOSITORY_OWNER:-${GITHUB_REPOSITORY%%/*}}"
repo="${GITHUB_REPOSITORY#*/}"
gh api graphql -F owner="$owner" -F repo="$repo" -F pr="$pr" -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            id isResolved isOutdated path line
            comments(first: 20) { nodes { id databaseId url body author { login } } }
          }
        }
      }
    }
  }' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved | not)
    | {thread: .id, path, line, isOutdated,
       comments: [.comments.nodes[] | {id, databaseId, author: .author.login, url, body}]}'
