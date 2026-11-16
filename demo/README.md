# Demo fixtures

Five self-contained failures, one per failure class subset. Try fix-ci without risking your own repo.

| Fixture | Class | Red because |
|---|---|---|
| `01-missing-dependency` | dependency | `Cannot find module 'left-pad'` |
| `02-failing-test` | test | `AssertionError: -1900 !== 80` |
| `03-flaky-test` | flaky | intermittent failure (~50% per run) |
| `04-oom-kill` | oom | `JavaScript heap out of memory` (exit 134) |
| `05-missing-secret` | permissions | `401 Unauthorized — DEPLOY_TOKEN is not set` |

Each fixture contains a `FIXTURE.md` with the expected root cause, the expected minimal fix, and the forbidden shortcuts. Use it to grade what your agent finds.

## Try locally (no GitHub needed)

```bash
cd demo/fixtures/02-failing-test
node test.js   # fails with a real assertion error
```

Then ask your agent (with fix-ci installed): “这个测试挂了，帮我修”.

- `01` — run `node index.js` (no `npm install` needed to see the error)
- `03` — run `node test.js` a few times; it fails randomly by design
- `04` — crashes the process by design (capped at 64MB heap)
- `05` — fails until a secret is configured; fix-ci should tell you it is a settings problem, not a code problem

## Try on GitHub Actions (full loop)

```bash
mkdir fix-ci-demo && cd fix-ci-demo && git init
cp -R <path-to>/fix-ci/demo/fixtures/02-failing-test/. .
git add -A && git commit -m "broken fixture"
gh repo create fix-ci-demo --private --source=. --push
```

Watch the run go red, then ask: “CI 挂了，帮我看看” / “fix the failing CI”.

For `05-missing-secret`, do **not** configure the secret — the correct behavior is a triage report naming the missing secret and where to add it.
