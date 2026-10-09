#!/usr/bin/env bash
# Runs every .NET test project with line coverage and fails below the threshold (ADR 0009, ADR 0017).
#
#   eng/test.sh                 build, then test all projects with coverage
#   eng/test.sh --no-build      reuse the existing Release build
#
# Each test project measures only the assembly it exists to test (TaleQuilt.X.Tests -> TaleQuilt.X).
# Exclusions are generated EF migrations and anything marked [ExcludeFromCodeCoverage] (entry points only).
# The threshold may only rise. Alex owns this file through CODEOWNERS.
set -euo pipefail
cd "$(dirname "$0")/.."

THRESHOLD=80
CONFIGURATION=Release
BUILD=1
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

if [ "$BUILD" = "1" ]; then
  dotnet build TaleQuilt.slnx -c "$CONFIGURATION" --nologo
fi
dotnet tool restore >/dev/null

status=0
for project in tests/*/; do
  name=$(basename "$project")
  assembly="${name%.Tests}"
  dll="$project/bin/$CONFIGURATION/net10.0/$name.dll"
  out="$project/TestResults/coverage/"
  rm -rf "$out"
  echo "::group::$name (coverage of [$assembly], threshold $THRESHOLD% lines)"
  if dotnet coverlet "$dll" \
      --target dotnet --targetargs "exec $dll" \
      --include "[$assembly]*" \
      --exclude-by-file "**/Migrations/*.cs" \
      --exclude-by-attribute GeneratedCodeAttribute --exclude-by-attribute ExcludeFromCodeCoverageAttribute \
      --format cobertura --output "$out" \
      --threshold "$THRESHOLD" --threshold-type line --threshold-stat total; then
    echo "::endgroup::"
  else
    echo "::endgroup::"
    echo "::error::$name failed: tests failed or coverage of [$assembly] is below $THRESHOLD% lines"
    status=1
  fi
done

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  dotnet reportgenerator "-reports:tests/*/TestResults/coverage/coverage.cobertura.xml" \
    "-targetdir:TestResults/coverage-report" "-reporttypes:MarkdownSummaryGithub;Cobertura" >/dev/null
  { echo "## .NET coverage (threshold ${THRESHOLD}% lines per project)"; cat TestResults/coverage-report/SummaryGithub.md; } >> "$GITHUB_STEP_SUMMARY"
fi
exit $status
