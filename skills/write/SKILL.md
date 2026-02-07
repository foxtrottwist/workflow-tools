---
name: write
description: Written communication with quality standards. Handles message composition (emails, texts, notes), proofreading, and professional content creation. Supports saving reusable snippets for future use. Triggers on "write", "compose", "draft", "proofread", "fix grammar", "help me say", "save this phrase", or requests to create professional content.
---

# Write

Written communication following quality standards. Three paths based on task complexity.

## Resume Check

Every invocation, check for existing state in `.writing.local/`.

**If state exists**, read `state.json` and offer to resume or start fresh.

**If no state**, proceed to Discover.

## Discover

Infer path from request language:
- "proofread", "fix grammar", "check this" → **Proofread**
- "email", "text", "note", "message", "reply" → **Compose Message**
- "LinkedIn", "cover letter", "blog", "bio", "article" → **Create Content**

Infer tone from relationship context (professional, colleague, casual). Use **AskUserQuestion** only when path or tone is genuinely ambiguous.

## Path: Compose Message

**Single-shot**. See [references/templates.md](references/templates.md) for input structure.

1. Gather: type, relationship, intent, key points
2. Apply writing standards from [references/standards.md](references/standards.md)
3. Use appropriate snippets from [references/snippets.md](references/snippets.md) when applicable
4. Output: Ready-to-send message only

**No commentary, no alternatives.** Just the message.

## Path: Proofread

**Single-shot**. Minimal intervention.

1. Identify errors (spelling, grammar, punctuation)
2. Preserve original voice and formatting
3. Never alter quoted material
4. Output: Corrected text only

**Success**: All errors fixed, voice preserved, ready for use.

## Path: Create Content (Iterative)

For longer professional content, use iterative refinement.

### Workflow
```
DISCOVER → DRAFT → REFINE → VALIDATE
```

### Phase: Draft
Create initial version applying:
- Writing standards (prohibited terms, voice requirements)
- Context-specific tone (professional, technical, educational)
- Structure appropriate to content type

Write to `.writing.local/{slug}/draft.md`

### Phase: Refine
Present draft for user feedback. Per feedback round:
1. User provides feedback
2. Apply changes
3. Log in `feedback.md`:
```markdown
## Round {N}
**Feedback:** {what user said}
**Changes:** {what changed}
```
4. Update draft

### Phase: Validate
Check against standards:
- [ ] No prohibited terms
- [ ] Authentic voice (not marketing)
- [ ] Claims backed by specifics
- [ ] Meets 2 of 3: actionable, evidence-based, problem-solving

Present final version.

## State Files (Iterative Only)

```
.writing.local/{slug}/
├── state.json      # Current phase
├── brief.md        # Requirements
├── draft.md        # Current version
├── feedback.md     # Revision history
└── guardrails.md   # Lessons learned
```

## Saving Snippets

When user requests to save copy for reuse ("save this", "remember this phrase", "store for later"):

1. Identify appropriate category in [references/snippets.md](references/snippets.md)
2. Add the snippet under that category
3. Create new category if none fits
4. Confirm what was saved and where

**Trigger phrases:**
- "Save this for later"
- "Remember this response"
- "Add to my snippets"
- "Store this phrase"

## Guardrails

Append discoveries to `guardrails.md`:

```markdown
## {Pattern}
- **Context:** {when this applies}
- **Problem:** {what went wrong}
- **Fix:** {how to avoid}
```

## References

- **Writing standards**: [references/standards.md](references/standards.md) — Voice requirements, prohibited terms, success criteria
- **Templates**: [references/templates.md](references/templates.md) — Input/output patterns for each task type
- **Snippets**: [references/snippets.md](references/snippets.md) — Reusable boilerplate, openers, closers, common phrases

## Quick Reference

| Task | Path | Output |
|------|------|--------|
| Email, text, note | Compose (single-shot) | Ready-to-send message |
| Fix errors | Proofread (single-shot) | Corrected text only |
| LinkedIn, cover letter | Create (iterative) | Polished content |
