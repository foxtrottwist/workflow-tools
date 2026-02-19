# Test Lifecycle: Specification vs Hypothesis

## Specification Tests

Tests that define and protect expected behavior. They live in the repo permanently.

**Characteristics:**
- Describe what the system should do from a user/caller perspective
- Named descriptively: `test_userCanLogin`, `test_emptyCartShowsZeroTotal`
- Survive refactoring — if behavior doesn't change, tests don't change
- Failing means a regression or intentional behavior change

**Examples:**
- Unit tests asserting function input/output contracts
- Integration tests verifying component interaction
- Behavior tests encoding business rules
- Edge case tests documenting known boundary conditions

## Hypothesis Tests

Tests that verify assumptions during development. They exist to answer "does this work the way I think it does?"

**Characteristics:**
- Prefixed with `test_hypothesis_` — grep-friendly, visible in test output
- Answer specific questions about APIs, libraries, or runtime behavior
- Temporary by design — created during development, reviewed before merge
- No production behavior depends on them

**Examples:**
- `test_hypothesis_fetchReturnsEmptyArrayNotNull` — verifying API contract
- `test_hypothesis_sqliteHandlesConcurrentWrites` — checking library behavior
- `test_hypothesis_dateParserAcceptsISO8601` — confirming format support

## Lifecycle Rules

1. **During development:** Create hypothesis tests freely to validate assumptions
2. **Before PR/merge:** Review every `test_hypothesis_*` test
3. **Promote or delete:** Each hypothesis test either:
   - Becomes a specification test (rename, removing the prefix) — the assumption is worth protecting
   - Gets deleted — the assumption was one-time, no ongoing regression risk
4. **Never merge hypothesis tests:** If `grep -r "test_hypothesis_"` finds anything in a PR, the review isn't done

## Why This Matters

Hypothesis tests left in the repo become mystery tests. Nobody remembers why they exist, nobody maintains them, and when they break, developers either:
- Waste time investigating something irrelevant
- Delete them without understanding, possibly removing useful protection
- Blindly fix them, possibly cementing incorrect assumptions

The prefix convention makes the intent explicit. A `test_hypothesis_*` that survived to main is a process failure, not a test failure.
