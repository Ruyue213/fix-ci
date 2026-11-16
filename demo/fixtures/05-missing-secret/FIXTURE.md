# Fixture: missing secret

- **Class:** permissions
- **Symptom in CI:** `ERROR: 401 Unauthorized — DEPLOY_TOKEN is not set` in `Deploy`
- **Expected root cause:** the workflow references `secrets.DEPLOY_TOKEN`, but the repository has no such secret configured (also happens for fork PRs, which never receive secrets)
- **Expected minimal fix:** configuration, not code — add the `DEPLOY_TOKEN` secret in repository settings; the agent should document exactly what to add and where instead of editing the workflow
- **Verification:** re-run the workflow after the secret is configured
- **Forbidden shortcuts:** inlining a token in the workflow; hardcoding a fallback; skipping the deploy step
