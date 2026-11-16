# Fixture: out of memory

- **Class:** oom
- **Symptom in CI:** `FATAL ERROR: Reached heap limit Allocation failed - JavaScript heap out of memory` in `Process events` (exit 134)
- **Expected root cause:** the loop retains every event in an ever-growing array; heap is capped at 64MB here to fail fast
- **Expected minimal fix:** stop retaining all events — process events in a streaming/bounded fashion (e.g. aggregate counters with a cap) instead of pushing to an unbounded array
- **Verification:** `node --max-old-space-size=64 index.js` runs with stable bounded memory
- **Forbidden shortcuts:** raising `--max-old-space-size`; removing the memory cap; adding `continue-on-error`
