# Anti-cheat rules

A CI fix must change the reason CI is red, never the reporting of it. Agent "fixes" that weaken checks are worse than no fix: they convert a loud failure into a silent one.

## Forbidden shortcuts

| Shortcut | Why it is forbidden | Do instead |
|---|---|---|
| Skipping or deleting failing tests (`.skip`, `xit`, `@Ignore`, removing the test file) | Removes the signal; the regression ships silently | Fix the failure, or quarantine with an explicit tracking issue and user approval |
| Disabling checks (`continue-on-error: true`, deleting steps, loosening thresholds) | Turns red green without changing behavior | Fix the root cause; if the check is genuinely obsolete, propose its removal as a separate, explicitly approved change |
| Bypassing install/commit guards (`--no-verify`, `--legacy-peer-deps`, `--force`) | Hides the conflict instead of resolving it | Resolve the actual conflict; use the bypass only if it is the repository's documented standard and the user confirms |
| Raising `timeout-minutes`, adding retry loops or auto-retry plugins as the fix | Masks hangs and races; failures resurface elsewhere or later | Diagnose and fix the hang or the nondeterminism |
| Editing assertions to match buggy output | Encodes the bug as expected behavior | Fix code or test based on intended behavior; if intent is unclear, ask the user |
| Pinning an old version to dodge a breaking change | Defers upgrade debt and hides incompatibility | Update the code for the new version, or document a deliberate downgrade with user approval |
| Excluding files from lint or coverage to pass the gate | Same as disabling checks | Fix violations, or negotiate a scope change explicitly |

## When a check is genuinely wrong

Occasionally the red run is the check's fault, not the code's. Then:

1. State the evidence that the check is obsolete (e.g. the assertion contradicts documented behavior).
2. Propose the change (rewrite/delete the test, adjust config) as its own commit or PR.
3. Get explicit user approval. Never bundle a check weakening into a "fix CI" commit — reviewers and future you must see it as a deliberate decision.

## Reporting

If the fix is out of scope or the cause is undetermined, say so with a triage report (see SKILL.md). A blocked-but-honest report is a success; a green run achieved by weakening checks is a failure.
