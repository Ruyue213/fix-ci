# Fixture: flaky test

- **Class:** flaky
- **Symptom in CI:** `failure: event not received before deadline` on some runs, passes on rerun
- **Expected root cause:** the test uses a fixed 10ms deadline to poll an event with up to 20ms random latency — a race between two timers
- **Expected minimal fix:** wait for the event properly (await its completion / poll until a generous timeout) instead of racing a fixed deadline; keep the deadline only as an upper bound
- **Verification:** run `node test.js` in a loop ≥20 times — all pass
- **Forbidden shortcuts:** rerunning CI until green; wrapping the test in automatic retries; deleting the test
