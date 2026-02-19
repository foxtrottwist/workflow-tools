---
name: tdd
description: "Enforce RED-GREEN-REFACTOR discipline during implementation. Use when starting feature work, bug fixes, refactoring, or any task that will produce production code."
---

# TDD

Enforce RED-GREEN-REFACTOR discipline. No production code without a failing test first.

## Iron Law

Never write production code without a failing test that demands it. This is non-negotiable. If you catch yourself writing production code first, stop and write the test.

## The Cycle

### RED — Write a failing test
- Write the smallest test that expresses the next behavior needed
- Run it. Watch it fail. Read the failure message.
- If it passes without new code, the test isn't testing anything new — rewrite it
- If it fails for the wrong reason (syntax error, import missing), fix the test, not the production code

### GREEN — Make it pass
- Write the minimum production code to make the test pass
- "Minimum" means ugly is fine — hardcoded values, obvious implementations
- Don't optimize, don't generalize, don't clean up
- Run the test. It must pass. All previous tests must still pass.

### REFACTOR — Clean up
- Now improve the code: remove duplication, improve names, extract functions
- Tests must stay green throughout refactoring
- If a test breaks during refactor, you changed behavior — undo and try again
- Refactoring means changing structure without changing behavior

## Test Lifecycle

Tests have two classifications. See `references/test-lifecycle.md` for details.

| Type | Purpose | In repo? |
|------|---------|----------|
| **Specification** | Defines expected behavior, prevents regressions | Yes — permanent |
| **Hypothesis** | Verifies assumptions during development | Clean up after |

Hypothesis tests use prefix: `test_hypothesis_*` (e.g., `test_hypothesis_apiReturnsEmptyArray`). Before merge: promote to specification (rename) or delete. Never leave hypothesis-prefixed tests in the repo.

## Rationalization Table

These are excuses. Recognize and reject them.

| Rationalization | Why it's wrong |
|----------------|---------------|
| "Too simple to test" | Simple things break. If it's too simple to test, it's too simple to get wrong — so the test takes 30 seconds. |
| "I'll write tests after" | You won't. And if you do, you'll test what you built rather than what was needed. |
| "Already manually tested" | Manual testing proves it works now. Tests prove it keeps working. |
| "Tests slow me down" | Tests slow you down less than debugging. TDD is faster over any non-trivial timeframe. |
| "It's just a prototype" | Prototypes become production code. If it's worth building, it's worth testing. |
| "The existing code doesn't have tests" | Then you're starting to fix that. One tested function is better than zero. |
| "I know this works" | You know it works in the case you're thinking of. Tests cover the cases you aren't. |

## Red Flags

Stop and reassess if:
- You wrote more than 10 lines of production code without running a test
- A test passes on first run (might not be testing what you think)
- You're testing implementation details (method calls, internal state) instead of behavior
- You need to modify tests to accommodate refactoring (tests are coupled to implementation)
- You're mocking more than 2 dependencies (design problem — too many collaborators)
- You feel the urge to "just get the code working first" (that's the urge TDD exists to counter)

## Common Mistakes

- **Testing implementation, not behavior:** Test what the code does, not how it does it. Assert on outputs and side effects, not internal method calls.
- **Tests that mirror production code:** If your test reads like a restatement of the production code, it tests nothing. Test from the caller's perspective.
- **Giant test setup:** If setup takes 20+ lines, the code under test has too many dependencies. Fix the design.
- **One assertion per test (taken too far):** Multiple related assertions in one test are fine. "One logical concept per test" is the real rule.
- **Skipping the RED step:** Writing code and test together means you don't know if the test actually catches failures. Always see red first.

## iter Integration

iter maps `tdd` to implementation tasks during planning. When dispatched by iter, the agent invokes this skill before starting implementation work.
