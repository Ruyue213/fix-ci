# Fixture: missing dependency

- **Class:** dependency
- **Symptom in CI:** `Error: Cannot find module 'left-pad'` in the `Run tests` step
- **Expected root cause:** `index.js` imports `left-pad`, but it is missing from `package.json`
- **Expected minimal fix:** add `left-pad` to `dependencies` and regenerate the lockfile (`npm install left-pad`)
- **Verification:** `npm test` passes locally and on CI
- **Forbidden shortcuts:** none obvious here — but removing the `require` changes behavior and is not a fix
