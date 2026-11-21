#!/usr/bin/env bash
# Fails when line coverage in coverage/lcov.info is below a threshold.
# Usage: tool/check_coverage.sh [minimum-percent]   (default 80)
set -euo pipefail

min="${1:-80}"
file="coverage/lcov.info"

if [[ ! -f "$file" ]]; then
  echo "Missing $file. Run: flutter test --coverage" >&2
  exit 2
fi

awk -F: -v min="$min" '
  /^LF:/ { found += $2 }
  /^LH:/ { hit += $2 }
  END {
    if (found == 0) { print "No instrumented lines found." > "/dev/stderr"; exit 2 }
    pct = 100 * hit / found
    printf "Line coverage: %.1f%% (%d of %d lines), minimum %s%%\n", pct, hit, found, min
    if (pct + 0 < min + 0) exit 1
  }
' "$file"
