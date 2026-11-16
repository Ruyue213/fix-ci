---
name: fix-ci
description: Diagnose and fix failing GitHub Actions CI runs. Use this skill whenever CI is red — a failed workflow run, a failing job or step, red status checks on a PR, or when the user says "CI 挂了", "帮我修 CI", "why did my build fail", "fix the failing tests on CI", or asks to triage GitHub Actions logs. Fetches failed-run logs, classifies the failure (build, test, flaky, dependency, OOM/timeout, permissions/secrets, config, infra), reproduces it locally, applies a minimal verified fix, and reports evidence. Do not use for authoring new CI pipelines from scratch or for non-GitHub CI providers.
---

# fix-ci — on-call for your CI

Diagnose red CI, reproduce it locally, fix the root cause minimally, and prove the fix with verification output. A fix must change the reason CI is red — never the way red is reported.

## Hard rules

1. Never make CI green by weakening checks: no skipped/deleted tests, no `continue-on-error`, no `--no-verify`, no assertions edited to match buggy output.
2. Never raise a timeout, retry count, or memory limit as the "fix" before proving the root cause.
3. Never push, rerun workflows, or open PRs without explicit user confirmation.
4. Never claim a fix without verification output from `scripts/verify-cmd.sh` or a green rerun id.
5. When the root cause cannot be determined, deliver a triage report — never guess-edit.

Full rationale and edge cases: `references/anti-cheat.md`.

## Workflow

### 1. Locate the failed run

Do not ask the user to paste logs — fetch them yourself:

```bash
scripts/analyze-run.sh                     # latest failed run on current branch
scripts/analyze-run.sh --run-id 12345678   # a specific run
scripts/analyze-run.sh --branch feature/x --max-lines 300
```

It prints failed jobs/steps, a keyword-filtered error excerpt, and the path to the full raw log. Read the excerpt first; drill into the raw log with `grep -n` only for specifics. Never `cat` the full log into context.

### 2. Classify the failure

| Class | Typical symptoms in the excerpt |
|---|---|
| build | `error TS####`, `SyntaxError`, compiler/lint errors |
| dependency | `MODULE_NOT_FOUND`, `ERESOLVE`, lockfile out of sync |
| test | `AssertionError`, `expected ... received`, a specific failing test |
| flaky | passes on rerun, different tests fail per run, timing-sensitive |
| oom | `heap out of memory`, `Killed`, `SIGKILL`, step timeout |
| permissions | `401`/`403`, missing secret, `Resource not accessible` |
| config | `Invalid workflow file`, expression error, unknown action input |
| infra | `runner lost communication`, external service outage |

Read only the matching section of `references/failure-playbooks.md`. Each section has: symptoms, diagnosis commands, minimal-fix patterns, verification.

### 3. Reproduce locally

Extract the failing step's command from the workflow file:

```bash
scripts/repro-hint.sh .github/workflows/ci.yml "Run tests"
```

Run the extracted command locally with the same toolchain versions the workflow uses. If reproduction is impossible (environment-only failure), state why explicitly in the report and rely on a CI rerun for verification.

### 4. Fix minimally

- Smallest diff that changes the root cause; match repository conventions.
- No opportunistic refactors, no formatting churn in the same commit.
- For flaky tests: remove the nondeterminism. If genuinely out of scope, quarantine with an explicit tracking issue — never silent retries.

### 5. Verify

```bash
scripts/verify-cmd.sh -- npm test        # exact failing command from CI
```

`VERDICT: PASS` is required before claiming a fix. Then, **after user confirmation**, push and rerun:

```bash
gh run rerun <run-id> --failed
```

Confirm the new run is green with `scripts/analyze-run.sh --run-id <new-id>`.

### 6. Report

```
Root cause: one sentence.
Evidence: the exact log line(s) proving it.
Fix: files changed and why this is the minimal change.
Verification: command run + result (or rerun id + conclusion).
Residual risk: what could still break; what was intentionally not touched.
```

## When you cannot fix it

Deliver a triage report instead of edits:

- Failure class and the evidence for it
- What you tried and ruled out
- Whether the fix belongs in code, repo settings, or infrastructure
- Recommended next action and owner (e.g. "needs repo admin to add secret `DEPLOY_TOKEN`")

An honest blocked report is a success. A green run achieved by weakening checks is a failure.

## Scope

v0.1 targets GitHub Actions. For other providers (GitLab, CircleCI, Jenkins), the playbooks still apply, but scripts cannot fetch logs — ask the user for the failing log file and analyze it directly.

## Resources

- `scripts/analyze-run.sh` — fetch and summarize a failed run (gh CLI)
- `scripts/repro-hint.sh` — extract a failing step's command from workflow YAML
- `scripts/verify-cmd.sh` — run the failing command and report PASS/FAIL with evidence
- `references/failure-playbooks.md` — per-class diagnosis and fix patterns
- `references/anti-cheat.md` — forbidden shortcuts, why, and what to do instead
