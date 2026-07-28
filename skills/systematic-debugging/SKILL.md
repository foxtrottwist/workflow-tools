---
name: systematic-debugging
description: "Find root cause before proposing fixes. Use when encountering bugs, test failures, unexpected behavior, performance problems, or when something is broken, not working, or needs debugging."
---

# Systematic Debugging

Find root cause before proposing fixes. No fixes without investigation first.

## Iron Law

Never propose a fix without first identifying root cause. "Try this and see if it works" is not debugging — it's guessing. If the fix can't be explained in terms of cause and effect, the investigation isn't done.

## Mandatory Phases

Complete each phase before moving to the next. Skipping phases is how "quick fixes" become multi-hour debugging sessions.

### Phase 1: Root Cause Investigation

**Read errors completely.** The full error message, full stack trace, all context. Most bugs tell you exactly what's wrong if you read the whole message instead of scanning for keywords.

**Reproduce.** If you can't reproduce it, you can't fix it. Document exact steps. Note whether it's consistent or intermittent.

**Check recent changes.** `git log --oneline -10` and `git diff HEAD~3` cover most regressions. The bug was probably introduced by the last thing that changed.

**Trace data flow backward.** Start at the failure point and work backward through the call stack. At each layer:
- What data arrived here?
- Is it what was expected?
- Where did it come from?

Continue until you find where correct data becomes incorrect. See `references/root-cause-tracing.md` for stack forensics, test-pollution isolation, and cross-environment diffing techniques.

### Phase 2: Pattern Analysis

**Find a working example.** Somewhere in the codebase, a similar operation works correctly. Find it.

**Compare completely.** Diff the working path against the broken path. Note every difference, not just the obvious ones.

**Identify the actual difference.** The root cause lives in the delta between working and broken. Often it's not what you expect — it's a configuration difference, an import path, an environment variable.

### Phase 3: Hypothesis and Test

**Single hypothesis.** Formulate one specific, falsifiable hypothesis: "The bug occurs because X returns Y when it should return Z."

**Minimal test.** Design the smallest possible test that confirms or refutes the hypothesis. One variable at a time.

**If falsified, return to Phase 1.** Don't chain hypotheses. Go back to investigation with what you learned.

### Phase 4: Implementation

**Failing test first.** Write a test that reproduces the bug. Run it, confirm it fails for the right reason.

**Single fix at root cause.** Fix the actual cause, not a symptom. If the fix is more than ~10 lines, reconsider whether you've found the real root cause.

**Verify.** Run the failing test — it should pass. Run the full test suite — nothing else should break.

### Phase 4.5: Architectural Review

**Trigger:** If 3 or more fix attempts have failed, STOP.

This means the problem is deeper than it appears. Don't keep trying — escalate:
- Explain what you've tried and why each attempt failed
- Present your current understanding of the system
- Ask the human for guidance on architecture or assumptions you might be wrong about

Three failed fixes is not "almost there" — it's evidence of a misunderstanding.

## Multi-Component Diagnostics

When the failure spans multiple components (frontend → API → database → external service):

1. **Add instrumentation at each boundary.** Log inputs and outputs at every layer transition.
2. **Find the guilty boundary.** The bug lives where correct data enters and incorrect data exits.
3. **Narrow scope.** Once you know the guilty component, apply the 4 phases within that component.

Don't debug across all layers simultaneously. Isolate first.

## Red Flags

Stop and reassess if any of these are happening:

| Red Flag | What it means |
|----------|--------------|
| "Quick fix" — changing code without understanding why | Guessing, not debugging |
| Multiple changes at once | Can't isolate which change fixed it (or broke something else) |
| Skipping test creation | Will regress. The bug will come back. |
| "One more attempt" after 2 failures | Escalate to Phase 4.5 |
| Fixing symptoms instead of cause | Applying bandaids — root cause still exists |
| Increasing timeout/retry values | Masking the real problem |
| Adding try/catch to suppress errors | Hiding the real problem |

Increasing a timeout is usually a symptom of a race condition — see `references/condition-based-waiting.md` for replacing arbitrary waits with condition polling. For structural prevention once the fix lands, see `references/defense-in-depth.md` on validating at entry points, business logic, and environment boundaries.

## Worked Example

**Bug report:** "Users intermittently see 'Session expired' right after logging in."

**Phase 1 (Investigation):** Full error and stack trace show the session check failing in `middleware/auth.ts:28`. Reproduces roughly 1 in 5 logins, not consistently. `git log --oneline -10` shows a recent change to session-token issuance. Tracing backward from the failure: the middleware reads `session.token` before the login handler's async token-write has resolved.

**Phase 2 (Pattern Analysis):** The password-reset flow does the same token issuance and never fails this way. Diffing the two paths: password-reset awaits the write before redirecting; login redirects immediately after calling the write, without awaiting it.

**Phase 3 (Hypothesis):** "The bug occurs because the login handler redirects before the session-token write resolves, so the middleware sometimes reads a token that isn't there yet." Minimal test: add a delay before the middleware's read — if the failure disappears, the hypothesis holds.

**Phase 4 (Implementation):** Write a failing test that logs in and immediately checks session validity — it fails intermittently, reproducing the bug. Fix: `await` the token write before redirecting in the login handler (a 1-line change at the actual root cause, not the middleware). Re-run the new test — passes consistently across 50 runs. Full suite still green.

No architectural review needed — fixed on the first attempt with a clear cause-and-effect explanation.

## iter Integration

iter maps `systematic-debugging` to tasks tagged as bugfix, investigation, or debugging during planning.
