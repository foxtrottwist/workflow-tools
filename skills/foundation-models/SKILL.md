---
name: foundation-models
description: Discipline — Anti-patterns, decision trees, and pressure scenarios for Foundation Models development. When to use FM vs server APIs, @Generable vs plain text, tools vs prompt context.
---

# Foundation Models — Discipline

## Overview

Discipline skill enforcing correct Foundation Models usage. Covers the most common mistakes, decision frameworks for architecture choices, and responses to stakeholder pressure. Complements `foundation-models-ref` (API reference) and `foundation-models-diag` (troubleshooting).

---

## Anti-Patterns with Corrected Code

### Anti-Pattern 1: Manual JSON Parsing

The model uses constrained decoding with `@Generable` — it generates valid structured output directly. No JSON parsing needed.

```swift
// ❌ WRONG: Manual JSON parsing
let response = try await session.respond(to: "Return a JSON object with name and age")
let data = response.content.data(using: .utf8)!
let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

// ✅ RIGHT: @Generable with constrained decoding
@Generable
struct Person {
    var name: String
    var age: Int
}
let person = try await session.respond(to: "Generate a person", generating: Person.self).content
```

**Why it matters:** Manual parsing is fragile — the model might produce malformed JSON, wrong keys, or unexpected types. `@Generable` guarantees type-safe output through constrained decoding at the token level. The model literally cannot produce invalid structure.

---

### Anti-Pattern 2: Blocking UI with Synchronous Generation

```swift
// ❌ WRONG: User waits for entire response
let response = try await session.respond(to: prompt)
self.text = response.content

// ✅ RIGHT: Streaming for progressive display
let stream = session.streamResponse(to: prompt)
for try await partial in stream {
    withAnimation {
        self.text = partial.content
    }
}
```

**Why it matters:** Even on-device generation takes time. Users see a frozen screen with no feedback. Streaming shows tokens as they generate — perceived latency drops dramatically even though total time is the same.

---

### Anti-Pattern 3: Context Overflow from Unbounded Conversations

```swift
// ❌ WRONG: Endless multi-turn without context management
// Session transcript grows until it hits 4096 token limit, then crashes

// ✅ RIGHT: Catch and recover
do {
    let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.exceededContextWindowSize {
    // Strategy: keep instructions + last exchange
    session = LanguageModelSession(instructions: originalInstructions)
    let response = try await session.respond(to: prompt)
}
```

**Why it matters:** The 4096 token context window is TOTAL — instructions + schema + transcript + new prompt + output. Long conversations fill it silently. Without handling `exceededContextWindowSize`, the app throws an unhandled error.

---

### Anti-Pattern 4: User Input in Instructions (Prompt Injection)

```swift
// ❌ WRONG: User input in instructions — prompt injection risk
let session = LanguageModelSession(instructions: "Summarize: \(userInput)")

// ✅ RIGHT: User input in prompt, instructions are developer-controlled
let session = LanguageModelSession(instructions: "You summarize text concisely")
let response = try await session.respond(to: userInput)
```

**Why it matters:** Instructions set the model's behavior and are developer-controlled. Interpolating user text into instructions lets users override your behavioral constraints. Keep instructions static; pass user content through `respond(to:)`.

---

### Anti-Pattern 5: Struct for Stateful Tools

```swift
// ❌ WRONG: Struct copies lose state
struct ContactTool: Tool {
    var pickedContacts = Set<String>()  // Lost between calls

    let name = "pickContact"
    let description = "Pick a contact"

    func call(arguments: Arguments) async throws -> ToolOutput {
        // pickedContacts mutations don't persist — struct is copied
        pickedContacts.insert(arguments.name)
        return ToolOutput("\(arguments.name) selected")
    }
}

// ✅ RIGHT: Class persists state across calls
class ContactTool: Tool {
    var pickedContacts = Set<String>()  // Survives across calls

    let name = "pickContact"
    let description = "Pick a contact"

    func call(arguments: Arguments) async throws -> ToolOutput {
        pickedContacts.insert(arguments.name)
        return ToolOutput("\(arguments.name) selected")
    }
}
```

**Why it matters:** The `Tool` protocol doesn't require reference semantics, but tools are called by the session — if the tool is a struct, mutations happen on a copy and the original instance never changes. Use `class` when tools accumulate state across calls.

---

### Anti-Pattern 6: Over-Complex Instructions Duplicating @Generable Structure

```swift
// ❌ WRONG: Instructions describe what @Generable already encodes
let session = LanguageModelSession(instructions: """
    You must return a response with exactly these fields:
    - title: a string, the title of the recipe
    - ingredients: an array of strings, each ingredient needed
    - steps: an array of strings, each step in order
    - prepTimeMinutes: an integer between 5 and 120
    - difficulty: one of "easy", "medium", or "hard"
    """)

// ✅ RIGHT: Instructions for behavior, @Generable for structure
@Generable
struct Recipe {
    @Guide(description: "Recipe title")
    var title: String

    @Guide(.count(1...20), description: "Ingredients needed")
    var ingredients: [String]

    @Guide(.count(1...30), description: "Steps in preparation order")
    var steps: [String]

    @Guide(.range(5...120), description: "Preparation time")
    var prepTimeMinutes: Int

    var difficulty: Difficulty

    @Generable
    enum Difficulty {
        case easy, medium, hard
    }
}

let session = LanguageModelSession(instructions: "Generate practical home cooking recipes")
let recipe = try await session.respond(to: "A quick weeknight pasta", generating: Recipe.self).content
```

**Why it matters:** `@Generable` and `@Guide` already encode the output structure at the decoding level. Repeating the schema in instructions wastes tokens (critical with 4096 limit) and can conflict with the actual schema constraints.

---

## Decision Trees

### Foundation Models vs Server API

| Question | Answer → Choice |
|----------|-----------------|
| Privacy required (data can't leave device)? | Yes → FM |
| Offline support needed? | Yes → FM |
| Avoid per-request API cost? | Yes → FM |
| Task is summarization, extraction, or classification? | Yes → FM |
| Need world knowledge (facts, dates, people)? | Yes → Server API |
| Need complex reasoning or math? | Yes → Server API |
| Need >4096 token context? | Yes → Server API |
| Need translation? | Yes → Server API |

FM and server APIs can coexist in the same app. Use FM for privacy-sensitive on-device features, server APIs for capabilities FM can't handle.

### @Generable vs Plain Text

| Question | Answer → Choice |
|----------|-----------------|
| Need structured data in code? | Yes → @Generable |
| Need type safety? | Yes → @Generable |
| Need streaming with progressive UI? | Yes → @Generable (PartiallyGenerated) |
| Just displaying text to user? | Yes → Plain text |
| Dynamic or unknown structure? | Yes → DynamicGenerationSchema or plain text |

### Tools vs Prompt Context

| Question | Answer → Choice |
|----------|-----------------|
| Data is dynamic or real-time? | Yes → Tool |
| Data comes from user's device (contacts, calendar)? | Yes → Tool |
| Data is static and short? | Yes → Include in prompt |
| Need external API call? | Yes → Tool |
| Model needs to decide whether to fetch? | Yes → Tool |

### New Session vs Reuse

| Question | Answer → Choice |
|----------|-----------------|
| Same topic/conversation? | Yes → Reuse |
| Context window filling up? | Yes → New session with condensed history |
| Completely new topic? | Yes → New session |
| Need different instructions? | Yes → New session |
| Need different tools? | Yes → New session |

---

## Pressure Scenarios

### "Use ChatGPT API Instead"

Tradeoffs to present:

**Foundation Models strengths:**
- On-device: private, offline, no network latency
- No per-request cost — scales to millions of users at zero marginal cost
- No API key management, no backend infrastructure
- 3B model optimized for summarization, extraction, classification

**Server API strengths:**
- World knowledge, complex reasoning, larger context windows
- Translation, code generation, math
- Larger model capacity for nuanced tasks

**FM limitations to acknowledge:**
- 3B parameters — smaller than server models
- 4096 token context (input + output combined)
- No world knowledge — can't answer factual questions
- Best at: summarize, extract, classify, generate from structured data

**Decision:** Use FM for on-device privacy-sensitive features. Use server APIs for capabilities FM can't handle. Both can coexist — this is not an either/or choice.

### "One Big Prompt for Everything"

- 4096 token limit is TOTAL: instructions + schema + transcript + new prompt + generated output
- Long instructions + `@Generable` schema + multi-turn transcript can exhaust context before generation starts
- Strategies:
  - Keep instructions concise — use `@Generable` instead of describing format in instructions
  - Chunk large inputs — process in segments, aggregate results
  - Monitor token usage with Instruments (Foundation Models template → inference track → "Max token count")
  - For multi-turn: catch `exceededContextWindowSize`, start fresh session with condensed history

### "Skip Availability Checks"

Three unavailable states from `SystemLanguageModel.default.availability`:

| State | Meaning | User Message |
|-------|---------|--------------|
| `.unavailable(.deviceNotEligible)` | Hardware can't run FM (iPhone 14 or earlier, non-Apple-Silicon Mac) | "This feature requires [device]. Not available on this device." |
| `.unavailable(.appleIntelligenceNotEnabled)` | User hasn't enabled Apple Intelligence in Settings | "Enable Apple Intelligence in Settings > Apple Intelligence & Siri" |
| `.unavailable(.modelNotReady)` | Model still downloading — temporary | "AI features are preparing. Try again in a few minutes." |

- Not checking = crashes or confusing errors on unsupported devices
- `.modelNotReady` is temporary — check again on `scenePhase` changes
- Check on `scenePhase` activation to catch state changes:

```swift
.onChange(of: scenePhase) { _, newPhase in
    if newPhase == .active {
        checkAvailability()
    }
}
```

---

## Related Skills

- `foundation-models-ref` — Complete API reference
- `foundation-models-diag` — Diagnostic troubleshooting
