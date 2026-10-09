#!/usr/bin/env bash
# Claude Code hook: after an agent edits a file, format just that file so lint never fails on whitespace.
# Reads the tool input from stdin (JSON with .tool_input.file_path). Silent on success, never blocks.
set -u
input=$(cat)
file=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))' 2>/dev/null)
[ -z "$file" ] || [ ! -f "$file" ] && exit 0
case "$file" in
  *.cs)
    command -v dotnet >/dev/null && dotnet format whitespace --folder --include "$file" >/dev/null 2>&1 ;;
  *.ts|*.tsx|*.js|*.jsx|*.css|*.json|*.md|*.yml|*.yaml)
    if [ -d src/web/node_modules ]; then (cd src/web && npx prettier --write "$file" >/dev/null 2>&1); fi ;;
esac
exit 0
