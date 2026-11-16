# Eval fixtures

A fixed corpus of failing-CI scenarios used to measure fix quality per release. A case passes only if **all** of these hold:

1. The reported root cause matches the expected root cause.
2. The diff is minimal and violates none of the anti-cheat rules (`references/anti-cheat.md`).
3. The verification command passes (`VERDICT: PASS`) or the case is explicitly expected to end in a triage report.

## Run protocol

Cases are currently run manually from `demo/fixtures/` (copy into a scratch repo, push, point the skill at the red run). An automated harness that replays each case in CI is the v0.2 milestone; scores will be published per release.

Status legend: **impl** = implemented under `demo/fixtures/`, **plan** = planned.

| ID | Class | Scenario | Expected root cause | Expected fix | Status |
|---|---|---|---|---|---|
| demo-01 | dependency | Node project imports a package missing from the manifest | missing `left-pad` dependency | add dependency + regenerate lockfile | impl |
| demo-02 | test | discount function returns -1900 instead of 80 | percent treated as fraction | divide percent by 100 | impl |
| demo-03 | flaky | event-poll test races a fixed deadline | fixed deadline vs random latency race | wait properly; deadline only as upper bound | impl |
| demo-04 | oom | event loop retains every item, heap capped | unbounded array retention | stream/aggregate instead of retaining | impl |
| demo-05 | permissions | deploy step gets 401 | `DEPLOY_TOKEN` secret not configured | triage report: add secret in repo settings | impl |
| build-01 | build | TypeScript strict-mode type error | wrong type annotation | fix annotation/code | plan |
| build-02 | build | Python `SyntaxError` on import | missing colon / bad indent | fix syntax | plan |
| build-03 | build | lint gate fails on unused import | leftover import | remove import | plan |
| dep-02 | dependency | `npm ci` fails, lockfile out of sync | stale `package-lock.json` | regenerate and commit lockfile | plan |
| dep-03 | dependency | `ERESOLVE` peer conflict on install | direct dep requires incompatible peer | align versions or use `overrides` | plan |
| test-02 | test | snapshot mismatch | outdated snapshot after intended change | update snapshot only if change is intended | plan |
| flaky-02 | flaky | order-dependent test suite | shared mutable state between tests | isolate state per test | plan |
| flaky-03 | flaky | async assertion fires before await | missing `await` | add await | plan |
| oom-02 | oom | job hits step timeout | loop never terminates | fix termination condition | plan |
| perm-02 | permissions | workflow cannot comment on PR | default token is read-only | add `permissions: pull-requests: write` | plan |
| perm-03 | permissions | deploy fails after token rotation | expired secret | triage report: rotate secret | plan |
| config-02 | config | workflow rejected at startup | invalid YAML indentation | fix YAML | plan |
| config-03 | config | expression error in `if:` | `secrets` context unavailable in that position | restructure condition | plan |
| infra-01 | infra | runner lost communication | provider outage | no code fix; rerun/monitor report | plan |
| infra-02 | infra | third-party API returns 503 | external outage | no code fix; report evidence | plan |
