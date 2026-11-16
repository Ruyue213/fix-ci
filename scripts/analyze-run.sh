#!/usr/bin/env bash
# Fetch and summarize a failed GitHub Actions run: failed jobs/steps,
# keyword-filtered error excerpt, and the path to the full raw log.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: analyze-run.sh [options]

Options:
  --run-id ID      Analyze a specific run (default: latest failed run)
  --branch NAME    Limit the "latest failed" lookup to a branch (default: current branch)
  --max-lines N    Max filtered log lines to print (default: 150)
  -h, --help       Show this help

Requires: gh CLI, authenticated (check with: gh auth status)
EOF
}

die() { echo "ERROR: $*" >&2; exit 2; }

command -v gh >/dev/null 2>&1 || die "gh CLI not found. Install it first: https://cli.github.com"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated. Run: gh auth login"

run_id=""
branch=""
max_lines=150

while [ $# -gt 0 ]; do
  case "$1" in
    --run-id)    [ $# -ge 2 ] || die "--run-id needs a value";    run_id="$2";    shift 2 ;;
    --branch)    [ $# -ge 2 ] || die "--branch needs a value";    branch="$2";    shift 2 ;;
    --max-lines) [ $# -ge 2 ] || die "--max-lines needs a value"; max_lines="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
done

case "$max_lines" in
  ''|*[!0-9]*) die "--max-lines must be a positive integer" ;;
esac

if [ -z "$run_id" ]; then
  if [ -z "$branch" ]; then
    branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
  fi
  echo "No --run-id given; looking up latest failed run${branch:+ on branch $branch}..."
  if [ -n "$branch" ]; then
    run_id="$(gh run list --branch "$branch" --limit 30 --json databaseId,conclusion \
      --jq '[.[] | select(.conclusion == "failure")][0].databaseId // empty' 2>/dev/null || true)"
  fi
  if [ -z "$run_id" ]; then
    run_id="$(gh run list --limit 30 --json databaseId,conclusion \
      --jq '[.[] | select(.conclusion == "failure")][0].databaseId // empty' 2>/dev/null || true)"
  fi
  [ -n "$run_id" ] || die "no failed run found in the last 30 runs for this repository"
fi

echo
echo "=== RUN ==="
gh run view "$run_id" --json displayTitle,workflowName,headBranch,conclusion,url \
  --jq '"\(.workflowName) — \(.displayTitle)\nbranch: \(.headBranch)\nconclusion: \(.conclusion)\nurl: \(.url)"' \
  2>/dev/null || die "could not load run $run_id (is this the right repository?)"

echo
echo "=== FAILED JOBS & STEPS ==="
jobs_out="$(gh run view "$run_id" --json jobs --jq '
  [.jobs[] | select(.conclusion == "failure") |
   "JOB: \(.name)\n" + ([.steps[] | select(.conclusion == "failure") | "  STEP: \(.name)"] | join("\n"))
  ] | join("\n\n")' 2>/dev/null || true)"
if [ -n "$jobs_out" ]; then
  echo "$jobs_out"
else
  echo "(no failed jobs reported — the run may still be in progress or was cancelled)"
fi

raw_log="$(mktemp "${TMPDIR:-/tmp}/fix-ci-run-${run_id}.XXXXXX")"
if ! gh run view "$run_id" --log-failed > "$raw_log" 2>/dev/null; then
  gh run view "$run_id" --log > "$raw_log" 2>/dev/null \
    || die "could not fetch logs for run $run_id"
fi
log_lines="$(wc -l < "$raw_log" | tr -d ' ')"

pattern='error|Error|ERROR|fail|Fail|FAIL|fatal|Fatal|exception|Exception|Traceback|assert|denied|killed|Killed|SIGKILL|out of memory|MODULE_NOT_FOUND|not found|not supplied|Invalid workflow'

echo
echo "=== FILTERED LOG EXCERPT (error lines, max $max_lines) ==="
excerpt="$(grep -n -E "$pattern" "$raw_log" 2>/dev/null | head -n "$max_lines" || true)"
if [ -n "$excerpt" ]; then
  echo "$excerpt"
else
  echo "(no error keywords matched — showing the last 40 lines instead)"
  tail -n 40 "$raw_log"
fi

echo
echo "=== LAST 15 LINES ==="
tail -n 15 "$raw_log"

echo
echo "=== FULL LOG ==="
echo "$raw_log ($log_lines lines)"
echo "Drill in with: grep -n -C 5 '<pattern>' $raw_log"
