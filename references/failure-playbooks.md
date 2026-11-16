# CI failure playbooks

One section per failure class. Read only the section matching your classification from SKILL.md.

## build — compilation, type, or lint errors

**Symptoms:** exit 1 with `error TS####`, `SyntaxError`, `cannot find symbol`, `error CS####`, lint rule failures.

**Diagnose:**
- Identify the first error, not the cascade — later errors are usually fallout.
- Check whether the default branch is also red: `gh run list --branch main --limit 5`. A pre-existing break is not caused by this branch.
- Compare toolchain versions: `setup-node`/`setup-python` version vs local `node --version`.

**Minimal fix:** fix the offending code or type error. Do not loosen config (`strict: false`, disabling lint rules) unless repository policy says so and the user confirms.

**Verify:** same compiler/linter command and version as CI.

## dependency — install or resolution failures

**Symptoms:** `MODULE_NOT_FOUND`, `Cannot find module`, `ERESOLVE`, `No matching distribution found`, `Could not resolve dependency`, `npm ci` lockfile mismatch.

**Diagnose:**
- Reproduce with the exact install command from the workflow (`npm ci`, `pip install -r requirements.txt`), not an approximation.
- For `ERESOLVE`, read the first peer-dependency complaint — it is the real conflict; the rest is fallout.
- Check the lockfile is committed and in sync with the manifest; check caret ranges that now resolve to a new release.

**Minimal fix:**
- Missing package: add it to the manifest, regenerate the lockfile with the repo's package manager — never hand-edit lockfiles.
- Stale lockfile: run the repo's lock command (`npm install --package-lock-only`, `poetry lock`, `bundle lock`) and commit the diff.
- Peer conflict: align versions or use the documented resolution mechanism (`overrides`). `--force` / `--legacy-peer-deps` are not fixes unless the user confirms they are the repo standard.

**Verify:** exact install command + the failing build/test command.

## test — deterministic test failures

**Symptoms:** `AssertionError`, `expected ... received ...`, `FAILED tests/...`, non-zero exit tied to a specific test name.

**Diagnose:**
- Extract the failing test name and the first assertion diff. The first failure is the signal.
- Run that single test locally with the same runner and flags.
- Read the test and the code under test: which one is wrong? Check `git log`/`git blame` on both — recently changed production code vs recently changed test.

**Minimal fix:** fix whichever side is wrong per the assertion's intent. Never edit expected values to match buggy output; never delete assertions.

**Verify:** the single test, then the full suite with the CI command.

## flaky — intermittent failures

**Symptoms:** passes on rerun; different tests fail on different runs; timing- or random-dependent failures; await timeouts.

**Diagnose:**
- Confirm flakiness: compare recent runs (`gh run list --branch <branch>`) or rerun failed jobs with user consent.
- Look for: missing `await`, time-based assertions, shared mutable state between tests, real network calls, `sleep`-based waits, unseeded randomness, order dependence.

**Minimal fix:** remove the nondeterminism (proper awaits, seeding, state isolation, polling instead of sleeps). If the true fix is out of scope, quarantine with an explicit tracking issue — silent retries mask, not fix.

**Verify:** loop the test ≥20 times locally, or rerun CI ≥3 times, before claiming fixed.

## oom — out of memory, SIGKILL, timeouts

**Symptoms:** `JavaScript heap out of memory`, `Killed`, `signal: killed`, `runner lost communication`, step timeout.

**Diagnose:**
- Distinguish true OOM from infra timeout: OOM names the heap/allocation; timeout shows elapsed time over the limit.
- Find the growing structure: unbounded arrays/maps, whole files read into memory, recursive accumulation, listeners attached in loops.
- Reproduce under a memory cap: `node --max-old-space-size=256 <cmd>`; measure with `/usr/bin/time -v` where available.

**Minimal fix:** bound or stream the data (chunking, pagination, caps). Raise runner resources or heap limits only if the workload genuinely needs it AND the user confirms the cost tradeoff. Never raise `timeout-minutes` to hide a hang.

**Verify:** same command under the same constraint; memory usage stays bounded.

## permissions — auth, secrets, 403/401

**Symptoms:** `401 Unauthorized`, `403 Forbidden`, `Resource not accessible by integration`, secret not found, expired token.

**Diagnose:**
- Check the workflow `permissions:` block — the default `GITHUB_TOKEN` is read-only for many scopes.
- Check the secret name in the workflow matches repository/environment settings. Fork PRs never receive secrets.
- Determine whether the correct fix is code (env var name, permissions) or repo settings.

**Minimal fix:** code-side: correct name/permissions. Settings-side: document exactly which secret or permission to add and where. Never print secrets, never inline them in workflows.

**Verify:** rerun after the user applies settings changes; confirm the step passes.

## config — workflow syntax, expressions, action inputs

**Symptoms:** workflow fails at startup: `Invalid workflow file`, `Unexpected value`, expression errors, `Input required and not supplied`.

**Diagnose:**
- Validate YAML locally: `yamllint <file>` or `python3 -c 'import yaml,sys;yaml.safe_load(open(sys.argv[1]))' <file>`.
- Check the action's documented inputs for the pinned version; verify the `uses: owner/action@vN` tag exists.
- Expression mistakes: `env` vs `secrets` vs `inputs` context; quoting of `if:` expressions.

**Minimal fix:** correct the YAML/expression/input with the smallest edit.

**Verify:** `gh workflow view <file> --ref <branch>` accepts it, then trigger the workflow.

## infra — runner or provider outage

**Symptoms:** `runner lost communication`, image pull failures, `ECONNRESET` fetching external hosts, third-party service unavailable.

**Diagnose:** check the provider status page; rerun the same job unmodified (with user consent); compare other workflows failing at the same timestamps.

**Minimal fix:** none in code. Report outage evidence and recommend rerun/monitoring. Do not change code to "fix" an outage.
