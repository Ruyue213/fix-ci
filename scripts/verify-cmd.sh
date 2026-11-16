#!/usr/bin/env bash
# Run the failing CI command locally and print a clear PASS/FAIL verdict.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: verify-cmd.sh [--timeout SECONDS] -- <command...>

Runs <command> locally, captures output, and prints a verdict.
Use the exact failing command from CI as <command>.

Options:
  --timeout N   Kill the command after N seconds (default: 900; 0 = no limit)
  -h, --help    Show this help

Exit code: 0 = command passed, 1 = command failed or timed out.
EOF
}

die() { echo "ERROR: $*" >&2; exit 2; }

timeout_s=900
while [ $# -gt 0 ]; do
  case "$1" in
    --timeout) [ $# -ge 2 ] || die "--timeout needs a value"; timeout_s="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    --)        shift; break ;;
    *)         break ;;
  esac
done

case "$timeout_s" in
  ''|*[!0-9]*) die "--timeout must be a non-negative integer" ;;
esac

[ $# -gt 0 ] || die "no command given (use: verify-cmd.sh -- <command...>)"

out_file="$(mktemp "${TMPDIR:-/tmp}/fix-ci-verify.XXXXXX")"

set +e
if [ "$timeout_s" -eq 0 ]; then
  "$@" > "$out_file" 2>&1
  status=$?
elif command -v timeout >/dev/null 2>&1; then
  timeout "$timeout_s" "$@" > "$out_file" 2>&1
  status=$?
elif command -v gtimeout >/dev/null 2>&1; then
  gtimeout "$timeout_s" "$@" > "$out_file" 2>&1
  status=$?
else
  # POSIX alarm survives exec; works on macOS and Linux without coreutils
  perl -e 'alarm shift; exec @ARGV' "$timeout_s" "$@" > "$out_file" 2>&1
  status=$?
fi
set -e

total="$(wc -l < "$out_file" | tr -d ' ')"
echo "=== LAST 30 LINES OF OUTPUT ($total lines total) ==="
tail -n 30 "$out_file"
echo
echo "full output: $out_file"
echo

if [ "$status" -eq 0 ]; then
  echo "VERDICT: PASS (exit 0)"
  exit 0
fi

if [ "$status" -eq 124 ] || [ "$status" -eq 142 ]; then
  echo "VERDICT: FAIL (timed out after ${timeout_s}s)"
else
  echo "VERDICT: FAIL (exit $status)"
fi
exit 1
