---
name: speak
description: "Speak text aloud or check TTS status via SpokenBite's local REST API. Use when the user asks to read something aloud, say something, speak text, announce results, give a verbal status update, check if SpokenBite is running, or check TTS readiness. Triggers on: 'read this aloud', 'say this', 'speak', 'tell me', 'announce', 'voice status', 'is SpokenBite running'. Also use proactively to speak summaries, confirmations, or status updates when voice feedback would be useful."
---

# Speak

Speak text aloud through SpokenBite's local TTS engine. SpokenBite runs a REST API on localhost that accepts text and plays it through the system's audio output using PocketTTS.

## Before Speaking

Check that SpokenBite is running and TTS is ready:

```bash
curl -s http://localhost:7849/v1/status
```

Response includes `tts.status` — one of `"ready"`, `"loading"`, `"not_loaded"`, or `"error"`. Only send speech requests when status is `"ready"`. If the server is unreachable or TTS isn't ready, tell the user — don't silently fail.

## Speak Text

```bash
curl -s -X POST http://localhost:7849/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "Your text here"}'
```

**Parameters:**

| Field | Required | Default | Notes |
|-------|----------|---------|-------|
| `input` | yes | — | Text to speak. Keep under ~500 words for best results. |
| `voice` | no | user setting | Override TTS voice. Omit to use user's configured preference. |
| `speed` | no | user setting | Playback rate, 0.5 to 2.0. |

Returns `{"status": "ok"}` on success. The audio plays locally on the user's machine — there's no audio data in the response.

## When to Speak

**Good uses:**
- User explicitly asks: "read this aloud", "say this", "tell me the summary"
- Task completion: "Done — 3 tests passed, build succeeded"
- Long-running task updates: "Starting deployment" ... "Deployment complete"
- Reading back text the user dictated for confirmation

**Don't speak:**
- Error messages or stack traces — visual is better
- Anything longer than a few sentences unless asked
- Repeatedly during tight loops

## Worked Example

User: "Summarize the PR and read it to me"

```bash
# 1. Check status
curl -s http://localhost:7849/v1/status
# → {"status":"ok","version":"1.0","tts":{"status":"ready"},"mcp":{"sessions":0}}

# 2. Speak the summary
curl -s -X POST http://localhost:7849/v1/audio/speech \
  -H "Content-Type: application/json" \
  -d '{"input": "The PR adds pagination to the user list endpoint. It introduces a cursor-based approach with a default page size of 25. Two new query parameters: cursor and limit."}'
# → {"status": "ok"}
```

## Port Configuration

Default port is `7849`. The user can change this in SpokenBite Settings > Integrations. If the default port doesn't respond, ask the user what port SpokenBite is configured on.

## Constraints

- Always check `/v1/status` before the first speech request in a session. Cache the result — don't re-check before every utterance.
- Never override `voice` unless the user explicitly asks for a specific voice.
- If SpokenBite isn't running, say so plainly and move on. Don't retry or troubleshoot — the user knows how to launch their app.
