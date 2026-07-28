---
name: chat-migration
description: "Use when approaching context limits or switching chats. Triggers on \"save context\", \"migrate chat\", \"export conversation\", \"hitting context limit\", \"save this session\", or requests to preserve work before starting fresh."
---

# Chat Migration

Generate context transfer documents for conversation continuation.

## When Invoked

Analyze the current conversation and produce a handoff document. No user questions needed—scan the full context and extract what matters.

## Required Sections

Generate a markdown artifact titled after the conversation's subject, with these sections in order. Each needs real extracted content — cut a section only if it's genuinely empty (e.g., no open questions), never leave filler.

- **Summary** — 2-3 sentences on what this conversation accomplished.
- **Key Decisions** — each choice made, paired with its rationale, not just the choice.
- **Technical Context** — code snippets, configs, or technical choices that must carry forward verbatim.
- **Current State** — split into Completed, In Progress, Blocked/Pending.
- **Open Questions** — unresolved items the next session needs to address.
- **Files Modified** — every file touched, with a one-line note on what changed.
- **Continuation Instructions** — specific enough that the next session doesn't have to re-derive what to do first or what to avoid.

## Worked Example

**Conversation:** Debugged a flaky integration test, traced it to a race condition in `src/auth/session.ts`, fixed it with a condition-based wait, started but didn't finish a regression test.

**Generated artifact:**

```markdown
# Context Migration: Auth Session Race Condition Fix

## Summary
Fixed a flaky integration test caused by a race condition in session token
refresh. Root cause confirmed; regression test still in progress.

## Key Decisions
- Used condition polling (`waitFor`) instead of `sleep()` — the timing
  wasn't fixed, it depended on token refresh completing.
- Left retry logic in `session.ts` unchanged — the race was in when the
  check ran, not the retry mechanism.

## Technical Context
`src/auth/session.ts:42`:
\`\`\`ts
await waitFor(() => session.isRefreshed, { timeout: 5000 })
\`\`\`

## Current State
- **Completed:** Root cause identified, fix applied and passing locally.
- **In Progress:** Regression test in `tests/auth.test.ts` — skeleton
  written, assertions not yet added.
- **Blocked/Pending:** None.

## Open Questions
- Does the same race exist in the mobile client's session refresh path?

## Files Modified
- `src/auth/session.ts` — added condition-based wait before token read.
- `tests/auth.test.ts` — regression test skeleton, incomplete.

## Continuation Instructions
Finish the regression test first — confirm it reproduces the old race
against the pre-fix code before considering this closed. Don't start the
mobile-client check until the regression test lands.
```

## Constraints

- Extract only information relevant to continuation
- Preserve exact code snippets when critical
- Include file paths for all referenced files
- Omit pleasantries and meta-discussion
- Keep decisions with their rationale (not just the choice)

## Success Criteria

- New session can resume immediately without re-explaining context
- All technical choices documented with reasoning
- No critical information lost
- Document is self-contained (no external references needed)
