---
name: foundation-models-diag
description: Diagnostic — Context exceeded, guardrail violations, tool failures, slow generation, availability issues. Specific error types, Instruments triage, and production crisis defense for Foundation Models.
---

# Foundation Models — Diagnostics

## Overview

Diagnostic workflows for Foundation Models issues. Every entry maps symptoms to specific `GenerationError` cases with concrete resolution steps. Use this when generation fails, output is wrong, performance is poor, or a production crisis hits.

---

## Diagnostic Decision Tree

### Context Exceeded (`GenerationError.exceededContextWindowSize`)

**Symptom:** Generation throws `LanguageModelSession.GenerationError.exceededContextWindowSize`

**Cause:** Input (instructions + prompt + schema + transcript) + output exceeds 4096 tokens. This is the total context window — not just the current prompt.

**Triage with Instruments:**
1. Product → Profile (Cmd+I), add Foundation Models instrument
2. Check **Inference track** → "Max token count" shows how close you are to the limit
3. Identify which component consumes the most tokens: instructions, schema, transcript history, or current prompt

**Resolution strategies:**

1. **Fresh session** (lose history):
```swift
session = LanguageModelSession(instructions: originalInstructions)
let response = try await session.respond(to: prompt)
```

2. **Condensed session** (keep instructions + summary of history):
```swift
// Ask the model to summarize the conversation so far
let summary = try await session.respond(to: "Summarize our conversation in 2 sentences")
session = LanguageModelSession(instructions: originalInstructions)
let response = try await session.respond(to: "Context: \(summary.content)\n\n\(newPrompt)")
```

3. **Chunk large inputs** — split text into segments, process each in a fresh session, aggregate results.

**Prevention:** Monitor transcript length. Warn the user or auto-condense before hitting the limit. Use `session.transcript` to inspect accumulated turns.

---

### Guardrail Violation (`GenerationError.guardrailViolation`)

**Symptom:** Generation throws `LanguageModelSession.GenerationError.guardrailViolation`

**Cause:** Content policy triggered by input prompt or by generated output mid-stream.

**Debug — access error details:**
```swift
do {
    let response = try await session.respond(to: prompt)
} catch let error as LanguageModelSession.GenerationError {
    if case .guardrailViolation = error {
        print(error.debugDescription)        // What happened
        print(error.failureReason ?? "")     // Why it failed
        print(error.recoverySuggestion ?? "") // What to try
    }
}
```

**Resolution:**
- Present a user-friendly message — don't expose raw error details
- Rephrase the prompt to avoid triggering content filters
- If user input caused it, sanitize or pre-filter known problematic patterns
- Don't retry the same prompt — it will fail again

**Prevention:** Pre-filter inputs for known problematic content patterns. Test with adversarial inputs during development.

---

### Tool Not Called

**Symptom:** Model responds with text instead of calling an available tool.

**Checklist:**
1. **Tool name and description clear?** The model relies on `name` and `description` properties to decide when to call a tool. Vague descriptions = tool gets ignored.
2. **Instructions direct the model?** Add explicit guidance: "Always use the getWeather tool when the user asks about weather."
3. **Prompt matches tool purpose?** If the prompt doesn't relate to the tool's described purpose, the model won't invoke it.
4. **Tool registered on session?** Verify the tool was passed to `LanguageModelSession(instructions:tools:)`.

**Debug — inspect transcript:**
```swift
for entry in session.transcript {
    switch entry {
    case .toolCall(let call):
        print("Tool called: \(call)")
    case .response(let text):
        print("Text response: \(text)")
    default:
        break
    }
}
```

If no `.toolCall` entry exists, the model chose not to invoke.

**Fixes:**
- Strengthen instructions with explicit tool-use directives
- Make tool description more specific to the expected query types
- Use `GenerationOptions(sampling: .greedy)` during debugging for deterministic behavior
- Simplify: if you have many tools, the model may get confused — reduce to only relevant tools per session

---

### Slow Generation

**Symptom:** Responses take noticeably long, UI feels sluggish.

**Triage with Instruments:**
1. Product → Profile (Cmd+I), add Foundation Models instrument
2. Check **Asset Loading track** — if model loading is slow, add pre-warming
3. Check **Inference track** — high token count means large input/output
4. Check **Response timeline** — first-token latency vs total generation time

**Fixes:**

**Pre-warm the session** (reduces first-response latency):
```swift
// On view appear, before user interaction
try await session.prewarm()

// With expected prompt prefix for better optimization
try await session.prewarm(promptPrefix: Prompt { "Summarize the following" })
```

**Reduce token consumption:**
- Shorter field names in `@Generable` structs
- Use `GenerationOptions(includeSchemaInPrompt: false)` with a one-shot example instead
- Constrain output length with `@Guide(.count())` or `@Guide(.maximumCount())`

**Stream for perceived performance:**
```swift
let stream = session.streamResponse(to: prompt)
for try await partial in stream {
    self.text = partial.content  // User sees progress immediately
}
```

Streaming doesn't reduce total time, but the user sees tokens appear immediately instead of waiting for the full response.

---

### Wrong Output Format

**Symptom:** `@Generable` type has unexpected values, missing fields, or wrong structure.

**Checklist:**
1. **All nested types marked `@Generable`?** Every struct/enum used inside a `@Generable` type must also be `@Generable`.
2. **Property declaration order matches desired generation order?** The model generates properties in declaration order — put important fields first.
3. **`@Guide` descriptions clear and specific?** Vague descriptions produce vague output.
4. **Enum cases cover all expected values?** The model can only generate cases you define.

**Fixes:**
- Add a one-shot example in the prompt to demonstrate expected quality
- Use `@Guide(description:)` on every property that needs specific behavior
- Constrain with `@Guide(.range())`, `@Guide(.count())`, `@Guide(.anyOf())` where appropriate
- Verify with `GenerationOptions(sampling: .greedy)` to get deterministic output during debugging

---

### Decoding Error (`GenerationError.decodingError`)

**Symptom:** Generation throws `LanguageModelSession.GenerationError.decodingError`

**Cause:** Model generated tokens that don't match the `@Generable` schema. Rare with well-defined types, more common with complex nested structures.

**Resolution:**
- Simplify the `@Generable` type — flatten nested structures
- Add `@Guide(description:)` to all properties
- Ensure all nested types are `@Generable`
- Check that enum cases are exhaustive for the expected domain
- Try `GenerationOptions(sampling: .greedy)` for more predictable output

---

### Unsupported Language (`GenerationError.unsupportedLanguageOrLocale`)

**Symptom:** Generation throws `LanguageModelSession.GenerationError.unsupportedLanguageOrLocale`

**Cause:** Input or requested output language isn't supported by the on-device model. FM is optimized for English. Translation is NOT a supported use case.

**Resolution:**
- Check language support before generation: `session.supportsLanguage(of: inputText)`
- Fall back to server API for unsupported languages
- Display user-facing message: "This feature is currently available in English"

---

### Rate Limited (`GenerationError.rateLimited`)

**Symptom:** Generation throws `LanguageModelSession.GenerationError.rateLimited`

**Cause:** Too many concurrent requests to the on-device model.

**Resolution:**
- Implement backoff — wait and retry
- Queue requests instead of firing concurrently
- Reduce request frequency in batch operations

---

### Availability Issues

**Three states** from `SystemLanguageModel.default.availability`:

| State | Meaning | Permanent? | User Action |
|-------|---------|------------|-------------|
| `.available` | Ready to use | — | None |
| `.unavailable(.deviceNotEligible)` | Hardware can't run FM (iPhone 14 or earlier, non-Apple-Silicon Mac) | Yes | None — device can't support it |
| `.unavailable(.appleIntelligenceNotEnabled)` | User hasn't enabled Apple Intelligence in Settings | No | Enable in Settings > Apple Intelligence & Siri |
| `.unavailable(.modelNotReady)` | Model still downloading | No | Wait — try again later |

**Testing in Xcode:** Edit Scheme → Run → Options → "Simulated Foundation Models Availability" — cycle through all states.

**Check on scene activation** to catch state changes (user enables AI, model finishes downloading):
```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            showAIFeatures = true
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:
                showDeviceIneligibleMessage()
            case .appleIntelligenceNotEnabled:
                showEnableAIMessage()
            case .modelNotReady:
                showModelDownloadingMessage()
            @unknown default:
                showGenericUnavailableMessage()
            }
        }
    }
}
```

---

## Production Crisis Scenario

**Scenario: AI feature launches, significant error rate in telemetry.**

### Immediate Triage (first 15 minutes)

1. **Identify error type distribution** — which `GenerationError` cases dominate the logs?
   - Mostly `.exceededContextWindowSize` → context management missing or insufficient
   - Mostly `.guardrailViolation` → specific content patterns triggering filters
   - Mostly `.deviceNotEligible` → availability check missing entirely
   - Mostly `.decodingError` → `@Generable` schema issue
   - Mixed → multiple issues, prioritize by volume

2. **Correlate with device class** — are errors concentrated on specific hardware?
   - iPhone 15 and earlier showing errors → availability check not implemented
   - All devices → logic bug, not hardware issue

3. **Check input patterns** — is specific content triggering failures?
   - Long inputs → context window issue
   - Specific topics → guardrail violations
   - Non-English text → unsupported language

4. **Check session lifetime** — are sessions living too long?
   - `exceededContextWindowSize` increasing over time → multi-turn without context management

### Instruments-Based Triage

1. Reproduce on affected device class
2. Profile with Foundation Models template (Product → Profile → Foundation Models)
3. Check **Asset Loading** — is the model loading fresh each time instead of staying warm? Add `prewarm()`.
4. Check **Inference track** token counts — are prompts larger than expected? Instructions bloated?
5. Check for concurrent session issues — multiple sessions competing for model resources

### Quick Mitigations

```swift
// 1. Add ContentUnavailableView fallback for all unavailable states
if !isModelAvailable {
    ContentUnavailableView("AI Features Unavailable",
        systemImage: "brain",
        description: Text(unavailabilityMessage))
}

// 2. Wrap every generation call with comprehensive error handling
do {
    let response = try await session.respond(to: prompt)
    handleSuccess(response)
} catch LanguageModelSession.GenerationError.exceededContextWindowSize {
    resetSessionAndRetry()
} catch LanguageModelSession.GenerationError.guardrailViolation {
    showContentFilterMessage()
} catch LanguageModelSession.GenerationError.unsupportedLanguageOrLocale {
    showLanguageUnsupportedMessage()
} catch LanguageModelSession.GenerationError.decodingError {
    showGenerationFailedMessage()
} catch LanguageModelSession.GenerationError.rateLimited {
    retryWithBackoff()
} catch {
    showGenericErrorMessage(error)
}

// 3. Add input length validation before sending to model
guard prompt.count < 3000 else {  // Conservative limit
    showInputTooLongMessage()
    return
}
```

- Consider feature flag to disable AI features for specific device classes if needed
- Add telemetry for each error type to track fix effectiveness

---

## Quick Reference: Symptom to Error Mapping

| Symptom | Error | Key Fix |
|---------|-------|---------|
| "Context too long" | `.exceededContextWindowSize` | Fresh/condensed session |
| Content policy error | `.guardrailViolation` | Rephrase prompt, filter input |
| Unexpected language error | `.unsupportedLanguageOrLocale` | Check `supportsLanguage(of:)`, fall back to server |
| Structured output fails | `.decodingError` | Verify nested `@Generable`, add `@Guide` descriptions |
| Too many requests | `.rateLimited` | Backoff, reduce request frequency |
| Model unavailable | Check `.availability` | Three states, different user messaging per state |
| Tool not called | Inspect `session.transcript` | Strengthen instructions and tool description |
| Slow response | Profile with Instruments | Pre-warm, reduce tokens, stream |
| Wrong output values | Check `@Guide` constraints | Add descriptions, constrain with range/count/anyOf |
| First response slow | Check Asset Loading track | Add `session.prewarm()` on view appear |

---

## Related Skills

- `foundation-models-ref` — Complete API reference
- `foundation-models` — Discipline patterns and anti-patterns
