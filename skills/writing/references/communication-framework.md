# Communication Framework

Adaptive structure for team and peer communications grounded in established methodologies: BLUF (military), Minto Pyramid (consulting), Plain Language (federal standard), and SCR (McKinsey). Every message answers three questions: *why am I writing, what do they need to know, and what happens next.*

## Output Format

All composed messages must be plain text. No markdown formatting — no bold (`**`), no bullet syntax (`-`), no headers (`#`), no backticks. Messages are destined for email, Teams, Slack, iMessage, and similar channels where markdown either renders incorrectly or looks like syntax noise. Use natural line breaks for structure and plain language for emphasis.

## Structure: Purpose → Content → Wrapup

Scale the structure to the channel — not every message needs all three sections explicitly.

| Channel | Purpose | Content | Wrapup |
|---------|---------|---------|--------|
| **Email** | Opening line states why you're writing and what's at stake | Grouped supporting points — each answers one question | Clear next step with expected response format |
| **Teams/chat** | First sentence combines purpose + key info | Supporting detail if needed (often omitted for quick messages) | Action or question (can be implicit) |
| **Text** | Compressed — purpose is the message | Only if needed | Often omitted |

### Purpose (BLUF-informed)

The first sentence should be able to stand alone. If the recipient reads nothing else, they got the point. This is the BLUF (Bottom Line Up Front) principle — state the conclusion before the evidence.

A good Purpose does two things:
- States what happened or what you need (the situation)
- Names why it matters now (the tension)

"Hey Sarah, wanted to flag something I found" is a soft opener, not a Purpose. "The staging endpoint is live in the production config — it's causing the timeout errors" is a Purpose. The first delays the point; the second delivers it.

For casual peer messages, the Purpose can still be conversational in tone. It just can't bury the lead.

### Content (Pyramid-informed)

For messages with multiple supporting points, group them so each group answers one question and together they cover everything. Don't list facts in the order you discovered them — organize for the reader.

Apply the "so what?" test: if removing a sentence doesn't change the message, cut it. Active voice by default. Keep sentences around 15-20 words — long sentences obscure hierarchy. One idea per paragraph.

For simple messages, Content may be a single sentence or omitted entirely.

### Wrapup (Clarity-informed)

Specify the action AND the form of the expected response. "Let me know what you think" is underspecified. "Reply here or ping me on Teams if you want to talk through it" sets a clear path.

For messages with a deadline, state it. For messages without an ask, the Wrapup can be implicit or omitted (especially in chat/text).

## Examples

### Email (full structure)
```
Hey Sarah, the staging endpoint is live in the production config and it's
causing the timeout errors we've been seeing.

I found it while reviewing the deployment setup this morning. The default
endpoint in config.prod.yaml was still pointing to staging. I updated it
to point to prod and tested locally — the timeouts cleared up.

Can you take a look at the config change when you get a chance? If it
lines up with what you were seeing, I'll push it to the release branch
before end of day.
```

### Teams/Chat (compressed)
```
Hey, I looked into the deployment issue and it looks like the config was
pointing to staging. should be a quick fix
```

### Text (minimal)
```
found the config issue — staging endpoint in prod config. fixing it now
```

## Context Threading

For ongoing conversations, use timestamps to determine whether a recap is needed.

### Gap-Based Recap

| Gap | Action |
|-----|--------|
| < 1 hour | No recap — conversation is fresh |
| 1 hour to 1 day | Light tie-back ("following up on the config issue...") |
| More than 1 day | Brief context line referencing last decision point or open question |

### When to Always Recap (Regardless of Gap)

- Topic shift — the new message diverges from the previous thread
- New participant — someone was added who needs context to follow

### Recap Format

Conversational, not formal. One line max.

- "picking back up on the staging issue from Tuesday..."
- "following up on what we discussed about the migration..."
- "circling back on the auth question..."

### Conversation State

When composing for an ongoing thread, track state in `.workflow.local/writing/{slug}/conversation.json`:

```json
{
  "messages": [
    {
      "timestamp": "2026-03-25T14:30:00Z",
      "channel": "teams",
      "recipient": "Sarah",
      "summary": "Flagged staging config in prod deployment"
    }
  ],
  "thread_context": "Deployment timeout investigation — config pointing to staging"
}
```

## Tone: Casual-Professional

Default voice for all peer/team communications.

### Capitalization and Punctuation

- Capitalize first word of messages and after names
- Relaxed capitalization mid-sentence
- Periods where needed for clarity and structure, not mandatory on every sentence
- Em dashes used sparingly — prefer commas or breaking into separate sentences
- Contractions encouraged (it's, don't, we'll)

### What to Avoid

- Forced formality ("I hope this message finds you well", "Per my last email")
- Stiff closers ("Please do not hesitate to reach out")
- Over-capitalization or excessive punctuation in casual channels
- Em dash chains — one per message is plenty, zero is better
- Passive voice when action ownership matters ("the config will be updated" vs "I'll update the config")

### Formality Escalation

Switch to standard punctuation, full capitalization, and formal structure when:
- The user explicitly requests formal tone
- Communicating with clients or external departments
- Writing to unfamiliar recipients outside the organization

## Technical Knowledge Framing

### Default: Collaborative Framing

Position yourself as researching and contributing, not lecturing.

- "I was looking into this and..."
- "based on what I found..."
- "from the docs it looks like..."

### Outside Core Expertise: Soft Qualifiers

When the topic is outside your core domain, add qualifiers.

- "to the best of my knowledge..."
- "I believe this is the case, but..."
- "from what I've seen so far..."

### Never

- Present researched information as long-held expertise
- Use jargon to signal authority
- Assume the recipient knows less than you

## Scope: "Team Member"

This framework applies to all organizational peers regardless of hierarchy:
- Direct coworkers
- Managers and leads
- Cross-functional collaborators
- Church/community project members

The casual-professional default holds unless the user explicitly requests formal tone.

## Methodology Sources

This framework synthesizes principles from:
- BLUF (Bottom Line Up Front) — U.S. military communication standard (DA Pamphlet 600-67)
- Minto Pyramid Principle — Barbara Minto, McKinsey (1985)
- Plain Language Guidelines — plainlanguage.gov, Plain Writing Act of 2010
- SCR (Situation/Complication/Resolution) — McKinsey consulting framework
- Anthropic prompt engineering clarity principles — docs.anthropic.com
