---
name: writing
description: "Use when composing emails, texts, notes, or professional content. Triggers on \"write\", \"compose\", \"draft\", \"proofread\", \"fix grammar\", \"help me say\", \"save this phrase\", or requests to create professional communication."
---

# Writing

Written communication following quality standards. Three paths based on task complexity.

## Resume Check

Every invocation, check for existing state in `.workflow.local/writing/`.

**If state exists**, read `state.json` and use **AskUserQuestion** to offer resume or start fresh — include the content type and current phase as context so the user knows what they're resuming.

**If no state**, proceed to Discover.

## Discover

Infer path from request language:
- "proofread", "fix grammar", "check this" → **Proofread**
- "email", "text", "note", "message", "reply" → **Compose Message**
- "LinkedIn", "cover letter", "blog", "bio", "article" → **Create Content**

Infer tone from relationship context (professional, colleague, casual). Use **AskUserQuestion** only when path or tone is genuinely ambiguous — for example, "help me write something about my experience" could be a LinkedIn post, cover letter, or blog. Present the likely options with brief descriptions.

## Path: Compose Message

**Single-shot**. See [references/templates.md](references/templates.md) for input structure.

1. Gather: type, relationship, intent, key points
2. Apply writing standards from [references/standards.md](references/standards.md)
3. Use appropriate snippets from [references/snippets.md](references/snippets.md) when applicable
4. Output: Ready-to-send message only

If the user provides partial context (e.g., "write an email to my manager" without specifying intent), infer from context when possible. Use **AskUserQuestion** for missing critical details — intent and key points — that can't be reasonably inferred. Combine into a single question with multiSelect when asking about multiple facets.

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

Write to `.workflow.local/writing/{slug}/draft.md`

### Phase: Refine
Present draft and use **AskUserQuestion** to gather structured feedback:
- Options like "Adjust tone", "Restructure", "Add detail", "Shorten" help focus revision rounds
- Always include a freeform "Other" option for specific feedback

Per feedback round:
1. Apply changes
2. Log in `feedback.md`:
```markdown
## Round {N}
**Feedback:** {what user said}
**Changes:** {what changed}
```
3. Update draft
4. Present updated version — repeat until user signals done

### Phase: Validate

Before manual quality review, execute `scripts/check-standards.sh <draft-path>`. Mechanical checks (prohibited terms, marketing tone) are handled by the script. Focus inference on: voice authenticity, claim backing, and the 2-of-3 criteria assessment (actionable, evidence-based, problem-solving).

Check against standards:
- [ ] No prohibited terms (mechanical — script)
- [ ] No marketing tone phrases (mechanical — script)
- [ ] Authentic voice (not marketing) (judgment)
- [ ] Claims backed by specifics (judgment)
- [ ] Meets 2 of 3: actionable, evidence-based, problem-solving (judgment)

Present final version.

## State Files (Iterative Only)

```
.workflow.local/writing/{slug}/
├── state.json      # Current phase
├── brief.md        # Requirements
├── draft.md        # Current version
├── feedback.md     # Revision history
└── guardrails.md   # Lessons learned
```

## Saving Snippets

When user requests to save copy for reuse ("save this", "remember this phrase", "store for later"):

1. Identify appropriate category in [references/snippets.md](references/snippets.md)
2. If category is unclear, use **AskUserQuestion** to let user pick from existing categories or create a new one
3. Add the snippet under that category
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
