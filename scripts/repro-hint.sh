#!/usr/bin/env bash
# Extract the YAML block of a failing step from a GitHub Actions workflow file,
# as a heuristic hint for local reproduction.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: repro-hint.sh <workflow-file> <failing-step-name>

Prints the YAML block of the step whose name matches <failing-step-name>
(substring match). Verify the extracted command against the CI log before
running it locally — YAML parsing here is heuristic, not exact.

Options:
  -h, --help   Show this help
EOF
}

die() { echo "ERROR: $*" >&2; exit 2; }

[ $# -ge 2 ] || { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

workflow="$1"
step="$2"

[ -f "$workflow" ] || die "workflow file not found: $workflow"

if ! grep -q "name:.*$step" "$workflow" 2>/dev/null; then
  echo "ERROR: no step whose name contains \"$step\" found in $workflow" >&2
  echo "Steps defined in this file:" >&2
  grep -n -E '^[[:space:]]*-?[[:space:]]*name:' "$workflow" | sed 's/^/  /' >&2 || true
  exit 1
fi

echo "--- step block (heuristic extraction, verify against the CI log) ---"
awk -v pat="$step" '
  {
    line = $0
    if (!found && index(line, pat) > 0 && line ~ /name:/) {
      found = 1
      match(line, /^[[:space:]]*/)
      base = RLENGTH
      print line
      next
    }
    if (found) {
      if (line ~ /^[[:space:]]*$/) { print line; next }
      match(line, /^[[:space:]]*/)
      ind = RLENGTH
      if (ind <= base && line ~ /^[[:space:]]*(-[[:space:]]+)?[A-Za-z_]/) { exit }
      print line
    }
  }
' "$workflow"

echo "--- end of step block ---"
echo "Note: steps using 'uses:' (actions) cannot be reproduced locally;"
echo "check the action's inputs against the CI log instead."
