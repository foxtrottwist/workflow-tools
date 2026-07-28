---
name: writing
description: "Use when composing emails, texts, notes, or professional content. Triggers on \"write\", \"compose\", \"draft\", \"proofread\", \"fix grammar\", \"help me say\", \"save this phrase\", \"reply to\", \"respond to\", \"Teams message\", \"Slack message\", \"send a message\", or requests to create professional communication. Also use when the user wants to write a message to a coworker, manager, or team member."
---

# Writing

Written communication following quality standards. Three paths based on task complexity. Defaults to proofreading the user's own words rather than originating a message from scratch — see the Compose Gate for when full drafting is appropriate.

## Resume Check

Every invocation, check for existing state in `.workflow.local/writing/`.

**If state exists**, read `state.json` and use **AskUserQuestion** to offer resume or start fresh — include the content type and current phase as context. **If no state**, proceed to Discover.

## Discover

Infer path from request language:
- "proofread", "fix grammar", "check this" → **Proofread**
- "email", "text", "note", "message", "reply" → **Compose Message**
- "LinkedIn", "cover letter", "blog", "bio", "article" → **Create Content**

Infer tone from relationship context (professional, colleague, casual). Use **AskUserQuestion** only when path or tone is genuinely ambiguous — for example, "help me write something about my experience" could be a LinkedIn post, cover letter, or blog. Present the likely options with brief descriptions.

## Path: Compose Message

See [references/templates.md](references/templates.md) for input structure.

### Compose Gate

Default to proofreading, not ghostwriting. Compose a message from scratch only when at least one holds:

- **Explicit request for full drafting** — the request itself contains what to say ("tell him the meeting moved to 3pm and ask if that still works"), or the user directly asks to be handed the words despite the topic's weight ("just write it, I trust you"). Naming a topic ("write an email about the delay") is not the same as supplying the content.
- **Low stakes** — routine, low-consequence message where an imperfect first pass costs nothing.
- **Mechanical / informational** — a factual or logistical reply: confirming receipt, answering a routine question, relaying a status, sharing a link.
- **Functional etiquette** — brief social-function messages: thanks, acknowledgment, congratulations, RSVP, "got it."
- **Shape already provided** — the user supplied bullet points, a rough draft, or dictated content to structure and polish.

**If none apply:** the message is substantive — a disagreement, a negotiation, feedback, an apology, a case being made — and the user hasn't supplied the actual content, only the topic. Don't invent it. Ask for their rough points or a first attempt, then apply the framework and tone rules below to what they give you. The substance stays theirs; composing from nothing is not proofreading.

### Channel Detection

Infer channel from request language:
- "email", "send an email" → **email** (full Purpose/Content/Wrapup)
- "Teams", "message", "chat", "ping" → **teams** (compressed)
- "text", "iMessage" → **text** (minimal)

If channel is ambiguous, infer from relationship and length — short messages to colleagues default to teams, longer or more formal messages default to email.

### Team/Peer Messages

For messages to team members (colleagues, managers, cross-functional, community), apply the communication framework:

1. Detect channel and scale structure accordingly
2. Apply [references/communication-framework.md](references/communication-framework.md) — Purpose/Content/Wrapup adaptive to channel
3. Apply Peer/Team voice from [references/standards.md](references/standards.md)
4. Use appropriate snippets from [references/snippets.md](references/snippets.md) when applicable
5. Output: Ready-to-send message only

### Context Threading

For ongoing conversations, check for existing state in `.workflow.local/writing/{slug}/conversation.json`:
- **If state exists**: Calculate gap since last message and apply recap rules from the framework
- **If new thread**: Create conversation state after composing

Log each composed message with timestamp, channel, recipient, and one-line summary.

### General Messages

For non-team messages (client, department, formal), use standard composition:

1. Gather: type, relationship, intent, key points
2. Apply writing standards from [references/standards.md](references/standards.md)
3. Use appropriate snippets from [references/snippets.md](references/snippets.md) when applicable
4. Output: Ready-to-send message only

### Shared Rules

If the user provides partial context (e.g., "write an email to my manager" without specifying intent), infer from context when possible. Use **AskUserQuestion** for missing critical details — intent and key points — that can't be reasonably inferred. Combine into a single question with multiSelect when asking about multiple facets.

**No commentary, no alternatives.** Just the message. All composed messages must be plain text — no markdown formatting (no bold, bullets, headers, or backticks). Messages should copy-paste cleanly into any channel.

**No em dashes, ever, in any composed message.** Use a comma, period, semicolon, or parentheses instead. Hard ban, not a "use sparingly" judgment call.

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
- [ ] Em dashes used only where a comma or period genuinely wouldn't do (judgment)
- [ ] Meets 2 of 3: actionable, evidence-based, problem-solving (judgment)

Present final version.

## State Files (Iterative Only)

```
.workflow.local/writing/{slug}/
├── state.json      # Current phase
├── brief.md        # Requirements
├── draft.md        # Current version
└── feedback.md     # Revision history
```

## Saving Snippets

When user requests to save copy for reuse ("save this", "remember this phrase", "store for later"):

1. Identify appropriate category in [references/snippets.md](references/snippets.md)
2. If category is unclear, use **AskUserQuestion** to let user pick from existing categories or create a new one
3. Add the snippet under that category
4. Confirm what was saved and where

**Trigger phrases:** "Save this for later", "Remember this response", "Add to my snippets", "Store this phrase".

## Worked Example

**Request:** "Write a Teams message to my manager letting her know the API migration is done, but flag that we're now dependent on the new rate limits."

**Discover:** Path = Compose Message (message request). Channel = Teams ("Teams message" stated explicitly) → compressed structure. Tone = professional/colleague, inferred from "manager."

**Compose Gate check:** Mechanical/informational — a status update relaying a completed fact and a follow-on risk, not a negotiation or disagreement. Gate passes; compose freely.

**Team/Peer path:** Apply Purpose/Content/Wrapup from communication-framework.md, compressed for Teams length. Purpose: status update. Content: migration complete, new dependency on rate limits. Wrapup: offer to discuss if needed.

**Output (ready-to-send only, no commentary):**
```
API migration to v2 is complete and deployed. One thing to flag: we're now
subject to the new provider's rate limits (1000 req/min vs. unlimited
before), so if traffic spikes we could see throttling. Want to sync on
whether we need a caching layer, or wait and see?
```

Plain text, no markdown, no bullets — copy-pastes cleanly into Teams. No conversation state was created since this is a one-off status update, not an ongoing thread.

### When the Gate Fails

**Request:** "Write an email to my manager explaining why I think we should push back the launch date — QA flagged blocking issues but leadership wants to ship on schedule."

**Compose Gate check:** Substantive — a disagreement with leadership carrying real stakes. The user named the topic and their general position, not their actual argument: which issues, how severe, what they want to happen if leadership says no anyway. No shape provided, not mechanical, not etiquette, no explicit instruction to fully originate it. Gate fails.

**Response:** Don't build the argument. Ask: "What's your case — which specific blocking issues, and how bad is the risk if you ship anyway? Give me your rough points or a first pass and I'll help you sharpen it." Once the user supplies their reasoning, apply the communication framework and tone rules to structure and tighten it — the substance stays theirs.

## Quick Reference

| Task | Path | Output |
|------|------|--------|
| Email, text, note — gate passes | Compose (single-shot) | Ready-to-send message |
| Email, text, note — gate fails | Ask for the user's points, then Compose from those | Ready-to-send message |
| Fix errors | Proofread (single-shot) | Corrected text only |
| LinkedIn, cover letter | Create (iterative) | Polished content |
