# Testing Anti-Patterns

Patterns that make tests fragile, slow, or useless.

## Mock Overuse

**Problem:** Mocking everything isolates the test from reality. Tests pass but integration fails.

**Rule:** Mock at system boundaries (network, file system, external APIs). Don't mock your own code unless the dependency is genuinely expensive or non-deterministic.

**Smell:** More mock setup than assertion code.

## Test-Only Methods

**Problem:** Adding methods to production code solely for test access (getters for private state, `_testReset()`, `visibleForTesting`).

**Why it's wrong:** Production code shouldn't know it's being tested. These methods increase surface area and invite misuse.

**Fix:** Test through public interfaces. If you can't test behavior through public methods, the design needs to change.

## Assertion-Free Tests

**Problem:** Tests that exercise code but don't assert anything. They pass when the code is deleted.

```
test("renders component", () => {
  render(<MyComponent />);
  // no assertions
});
```

**Fix:** Every test must assert something specific about behavior or output.

## Flaky Tests

**Problem:** Tests that pass sometimes and fail other times. Usually caused by:
- Shared mutable state between tests
- Time-dependent logic
- Network calls
- Race conditions in async code

**Fix:**
- Isolate test state completely
- Use deterministic clocks/timers
- Mock external services
- Use proper async waiting (conditions, not timeouts)

## Test Pollution

**Problem:** One test modifies global state, causing later tests to fail (or pass when they shouldn't).

**Symptoms:** Tests pass in isolation but fail when run together. Test order matters.

**Fix:** Reset all global state in setup/teardown. Better: avoid global state in production code.

## Snapshot Abuse

**Problem:** Snapshotting large outputs creates brittle tests that break on every change. Developers blindly update snapshots without reviewing diffs.

**When snapshots help:** Small, stable outputs (serialized configs, error messages).

**When snapshots hurt:** Full component renders, large JSON payloads, anything that changes frequently.

## Testing Through the UI

**Problem:** Using UI tests for logic that could be tested at a lower level. UI tests are slow, flaky, and expensive.

**Rule:** Test logic at the lowest possible level. Unit tests for business logic, integration tests for wiring, UI tests only for actual UI behavior.
