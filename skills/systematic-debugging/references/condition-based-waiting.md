# Condition-Based Waiting

Replace arbitrary timeouts with condition polling.

## The Problem

Arbitrary timeouts are a debugging anti-pattern:
- `sleep(2000)` — Why 2 seconds? Will it always be enough?
- `setTimeout(fn, 500)` — Works on your machine, fails in CI
- `Thread.sleep(1000)` — Masks the real issue: you don't know when the operation completes

Timeouts that are "long enough" become flaky tests, intermittent failures, and "it works if you wait a bit."

## The Fix: Poll for Conditions

Instead of waiting a fixed time, wait for the condition you actually need.

### Generic Pattern

```
function waitFor(condition, { interval = 100, timeout = 5000 } = {}) {
  const start = Date.now()
  while (Date.now() - start < timeout) {
    if (condition()) return true
    wait(interval)
  }
  throw new Error(`Timed out waiting for condition after ${timeout}ms`)
}
```

### Common Applications

**Waiting for a file:**
```
waitFor(() => fileExists(path))
```

**Waiting for a process:**
```
waitFor(() => processReady(pid))
```

**Waiting for UI state:**
```
waitFor(() => element.visible && element.enabled)
```

**Waiting for data:**
```
waitFor(() => database.query(id) !== null)
```

## Rules

1. **Name the condition.** "Wait for user record to exist" not "wait 2 seconds."
2. **Set a maximum timeout.** Condition polling still needs an upper bound to prevent hanging.
3. **Use reasonable intervals.** 100ms is usually fine. Don't poll every 1ms — it's wasteful.
4. **Timeout error messages must explain what was expected.** "Timed out waiting for database record 'user-123' to exist after 5000ms" not "timeout."
5. **Log on timeout.** Include the current state when the timeout fires — it tells you how close you were.

## When Fixed Waits Are OK

- Rate limiting (waiting between API calls) — the delay is the point, not a workaround
- Animation timing in production code — visual design choice
- Debouncing user input — intentional delay

These are deliberate design choices, not workarounds for unknown timing.
