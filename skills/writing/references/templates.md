# Writing Templates

## Message Composition

### Input Structure
```xml
<message_request>
type: [email|text|chat|note]
context: [response|initiate]
relationship: [professional|colleague|acquaintance|friend|formal]
intent: [specific purpose/goal]
content: [partial message or key points] OR "none"
</message_request>
```

### Constraints
- Match tone to relationship level
- Include proper structure for message type
- Preserve user's voice when content provided
- No commentary or alternatives

### Output
Message text only, ready to send.

---

## Proofreading

### Input Structure
```xml
<content>
type: [email|document|message|code-comment|note]
preserve: [tone|format|style] OR "all"

[TEXT_TO_PROOFREAD]
</content>
```

### Constraints
- Fix spelling, grammar, and punctuation errors
- Preserve original tone and formatting
- Maintain technical accuracy
- Never alter quoted material
- Keep corrections minimal for casual content

### Success Criteria
- All errors corrected
- Original voice preserved
- Formatting maintained
- Ready for immediate use

### Output
Corrected text only, preserving original voice and formatting.

---

## Professional Content

### Input Structure
```xml
<content_request>
type: [linkedin-post|cover-letter|blog-post|article|bio]
purpose: [specific goal]
audience: [target readers]
key_points: [main ideas to include]
tone: [from standards] OR "match voice samples"
</content_request>
```

### Constraints
- Apply writing standards (see standards.md)
- Match specified tone to context
- Include evidence/examples for claims
- No prohibited terms

### Success Criteria
- Sounds authentic, not marketing
- Claims backed by specifics
- Meets 2 of 3: actionable, evidence-based, problem-solving

---

## Team Communication

Templates for peer/team messages. Scale structure to the channel. See [communication-framework.md](communication-framework.md) for full framework.

### Input Structure
```xml
<team_message>
channel: [email|teams|text]
recipient: [name or role]
relationship: [colleague|manager|cross-functional|community]
intent: [specific purpose/goal]
content: [key points or partial draft] OR "none"
conversation_context: [prior messages or "new thread"]
</team_message>
```

### Email Template (Full Structure)
```
Purpose: Opening line — why you're writing
Content: Context, details, supporting information
Wrapup: Clear next step or ask
```

### Teams/Chat Template (Compressed)
```
Purpose + key info in first sentence
Supporting detail if needed (often omitted)
Action or question (can be implicit)
```

### Text Template (Minimal)
```
Purpose is the message — one or two sentences max
```

### Constraints
- Apply casual-professional tone (see standards.md Peer/Team voice)
- Use gap-based context threading for ongoing conversations
- Collaborative framing for technical content
- No forced formality unless explicitly requested
- Preserve user's voice when partial draft provided
- Plain text only — no markdown formatting (no bold, bullets, headers, backticks)
- Purpose should stand alone (BLUF) — if the reader stops at the first sentence, they got the point
- Active voice when action ownership matters

### Output
Plain text message only, ready to copy-paste into any channel.

---

## Pattern Summary

| Task | Input Needed | Output |
|------|--------------|--------|
| Compose message | type, relationship, intent | Ready-to-send text |
| Team communication | channel, recipient, intent, context | Ready-to-send message |
| Proofread | text, preserve settings | Corrected text only |
| Professional content | type, purpose, key points | Polished content |
