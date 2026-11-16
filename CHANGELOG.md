# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-11-16

### Added
- `SKILL.md` workflow: locate failed run → classify → reproduce locally → minimal fix → verify → report
- Hard anti-cheat rules (`references/anti-cheat.md`) with rationale and escalation process
- Failure playbooks for 8 classes: build, dependency, test, flaky, oom, permissions, config, infra (`references/failure-playbooks.md`)
- `scripts/analyze-run.sh` — fetch failed run, summarize failed jobs/steps, filter log excerpt, print raw log path
- `scripts/repro-hint.sh` — extract the failing step's YAML block for local reproduction
- `scripts/verify-cmd.sh` — run the CI command locally and print `VERDICT: PASS/FAIL`
- Five reproducing demo fixtures under `demo/fixtures/` plus a 20-case eval benchmark plan (`evals/fixtures.md`)
