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

## Pattern Summary

| Task | Input Needed | Output |
|------|--------------|--------|
| Compose message | type, relationship, intent | Ready-to-send text |
| Proofread | text, preserve settings | Corrected text only |
| Professional content | type, purpose, key points | Polished content |
