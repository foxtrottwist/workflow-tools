---
name: dispatch
description: "Bridge a sharpened spec into an active code session. Use when ready to
  start implementing a spec, kick off work on a sharpened idea, transition from planning
  to code, or pick up where a sharpen session left off. Triggers on: 'dispatch',
  '/dispatch', 'start the spec', 'kick off', 'implement the spec', 'run the spec',
  'let's build it', 'start coding'. Pairs with the sharpen skill — dispatch is the
  implementation step that follows a sharpen session."
---

# Dispatch

Bridge the sharpen → code gap: find the most recent spec, confirm the workspace, invoke iter.

## Procedure

1. **Find the spec** — Glob `.workflow.local/sharpen/*.md` in the project root. Sort by
   modification time. Read the most recent file.

2. **Confirm workspace** — Surface the spec title and one-line intent as a natural
   acknowledgement: "Found: *{title}* — starting in {workspace}." Escalate to
   AskUserQuestion only when the target workspace is genuinely ambiguous (e.g., spec
   references a different repo, multiple active projects with no clear match).

3. **Invoke iter** — Call the `workflow-tools:iter` skill. Pass the spec file path and
   key context (spec title, intent, success criteria) as the task description.

## Worked Example

**Scenario:** User finishes a sharpen session. File `.workflow.local/sharpen/dispatch-skill-spec.md`
exists in `workflow-tools/`.

**User:** `/dispatch`

**Step 1 — Find spec:**
```
Glob: .workflow.local/sharpen/*.md
→ dispatch-skill-spec.md (modified 2026-03-21)
```

**Step 2 — Read and confirm:**
Read `dispatch-skill-spec.md`. Title: "dispatch — Statement of Intent". Intent: "Build a
compact `/dispatch` skill that closes the sharpen → code loop."
Output: "Found: *dispatch — Statement of Intent* in `workflow-tools/`. Kicking off iter."

**Step 3 — Invoke iter:**
```
/iter implement the following spec.
Spec file: .workflow.local/sharpen/dispatch-skill-spec.md
Read the spec in full before starting.
```
Iter enters plan mode, runs discovery, decomposes into tasks.

## Constraints

- Never hard-code spec paths — always resolve relative to the active project root.
- Never start the code session without confirming the workspace.
- Always read the full spec before dispatching — never pass a summary.
