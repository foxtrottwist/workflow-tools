# Foundation Models: SwiftUI Integration

Patterns for building SwiftUI views powered by on-device Foundation Models.

## Observable Session Manager

Wrap session management in an `@Observable` class for SwiftUI integration:

```swift
@Observable
class AIAssistant {
    private(set) var responseText = ""
    private(set) var isResponding = false
    private(set) var error: Error?

    private var session: LanguageModelSession

    init(instructions: String = "You are a helpful assistant") {
        self.session = LanguageModelSession(instructions: instructions)
    }

    func send(_ prompt: String) async {
        isResponding = true
        error = nil
        defer { isResponding = false }

        do {
            let response = try await session.respond(to: prompt)
            responseText = response.content
        } catch {
            self.error = error
        }
    }

    func reset(instructions: String = "You are a helpful assistant") {
        session = LanguageModelSession(instructions: instructions)
        responseText = ""
        error = nil
    }
}
```

Use in views:

```swift
struct ChatView: View {
    @State private var assistant = AIAssistant()
    @State private var input = ""

    var body: some View {
        VStack {
            Text(assistant.responseText)

            TextField("Ask something", text: $input)
                .onSubmit {
                    Task { await assistant.send(input) }
                    input = ""
                }
                .disabled(assistant.isResponding)

            if assistant.isResponding {
                ProgressView()
            }
        }
    }
}
```

## Session as @State

For simpler cases, use `LanguageModelSession` directly as `@State`. SwiftUI observes `isResponding` automatically:

```swift
struct SimpleView: View {
    @State private var session = LanguageModelSession(instructions: "You are a travel advisor")
    @State private var result = ""

    var body: some View {
        VStack {
            Text(result)

            Button("Generate") {
                Task {
                    result = try await session.respond(to: "Suggest a weekend trip").content
                }
            }
            .disabled(session.isResponding)
        }
    }
}
```

**Important**: `session.isResponding` works with SwiftUI's observation system when the session is a `@State` property.

## Availability-Gated Views

Always check availability before showing AI features:

```swift
struct AIFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var availability: SystemLanguageModel.Availability?

    var body: some View {
        Group {
            switch availability {
            case .available:
                GenerativeContentView()
            case .unavailable(let reason):
                AIUnavailableView(reason: reason)
            case nil:
                ProgressView("Checking availability...")
            }
        }
        .task { checkAvailability() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active { checkAvailability() }
        }
    }

    private func checkAvailability() {
        availability = SystemLanguageModel.default.availability
    }
}
```

### ContentUnavailableView for AI

```swift
struct AIUnavailableView: View {
    let reason: SystemLanguageModel.UnavailabilityReason

    var body: some View {
        ContentUnavailableView {
            Label("AI Unavailable", systemImage: "apple.intelligence")
        } description: {
            Text(message)
        } actions: {
            if case .modelNotReady = reason {
                Button("Try Again") {
                    // Re-check availability
                }
            }
        }
    }

    private var message: String {
        switch reason {
        case .deviceNotEligible:
            "This device doesn't support Apple Intelligence"
        case .appleIntelligenceNotEnabled:
            "Enable Apple Intelligence in Settings to use this feature"
        case .modelNotReady:
            "The AI model is still downloading. Please try again shortly."
        @unknown default:
            "AI features are currently unavailable"
        }
    }
}
```

Note: Only `.modelNotReady` is a temporary state worth showing a retry button for. Device eligibility and intelligence enablement require user action outside the app.

## Streaming to Views

### Plain Text Streaming

```swift
@State private var responseText = ""

let stream = session.streamResponse(to: prompt)
for try await partial in stream {
    withAnimation {
        responseText = partial.content
    }
}
```

### Structured Streaming with PartiallyGenerated

`@Generable` types automatically get a `PartiallyGenerated` nested type where all properties are optional:

```swift
@Generable
struct Itinerary {
    var name: String
    var days: [DayPlan]
    var summary: String
}

// Itinerary.PartiallyGenerated has:
// var name: String?
// var days: [DayPlan]?
// var summary: String?
```

Stream structured content with safe unwrapping:

```swift
@State private var partial: Itinerary.PartiallyGenerated?

func generate() async throws {
    let stream = session.streamResponse(
        to: "Plan a 3-day trip to Tokyo",
        generating: Itinerary.self
    )
    for try await snapshot in stream {
        withAnimation {
            partial = snapshot
        }
    }
}

// In view body:
VStack {
    if let name = partial?.name {
        Text(name).font(.title)
    }

    if let days = partial?.days {
        ForEach(days, id: \.self) { day in
            DayView(day: day)
        }
    }

    if let summary = partial?.summary {
        Text(summary)
            .foregroundStyle(.secondary)
    }
}
```

Properties appear in declaration order. Put the most important field first for the best streaming UX — users see content immediately instead of waiting for the full response.

## Markdown Response Rendering

Render model responses as rich text:

```swift
@State private var responseText = ""

var body: some View {
    ScrollView {
        Text(LocalizedStringKey(responseText))
            .textSelection(.enabled)
    }
}
```

For attributed string rendering when you need more control:

```swift
if let attributed = try? AttributedString(markdown: responseText) {
    Text(attributed)
        .textSelection(.enabled)
}
```

## Chat UI from Transcript

Build a conversation interface using the session transcript:

```swift
struct ConversationView: View {
    @State private var session = LanguageModelSession(instructions: "You are a travel agent")
    @State private var input = ""

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(session.transcript) { entry in
                    switch entry {
                    case .prompt(let prompt):
                        ChatBubble(
                            text: prompt.segments.first?.description ?? "",
                            isUser: true
                        )
                    case .response(let response):
                        ChatBubble(
                            text: response.segments.first?.description ?? "",
                            isUser: false
                        )
                    default:
                        EmptyView()
                    }
                }
            }
        }

        HStack {
            TextField("Message", text: $input)
            Button("Send") {
                let message = input
                input = ""
                Task {
                    try await session.respond(to: message)
                }
            }
            .disabled(input.isEmpty || session.isResponding)
        }
    }
}

struct ChatBubble: View {
    let text: String
    let isUser: Bool

    var body: some View {
        Text(text)
            .padding(12)
            .background(isUser ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isUser ? .white : .primary)
            .clipShape(.rect(cornerRadius: 16))
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }
}
```

The transcript updates automatically after each `respond(to:)` call. SwiftUI observes the session and re-renders the conversation.

## Multi-Turn Conversation Pattern

For a guided conversation (like a travel agent):

```swift
@Observable
class TravelAgent {
    private(set) var isResponding = false
    private var session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: InstructionsBuilder {
            "You are a friendly travel agent"
            "Help plan trips step by step"
            "Ask clarifying questions about preferences"
            "Keep responses concise"
        })
    }

    var transcript: Transcript {
        session.transcript
    }

    func send(_ message: String) async throws {
        isResponding = true
        defer { isResponding = false }
        try await session.respond(to: message)
    }

    func newConversation() {
        session = LanguageModelSession(instructions: InstructionsBuilder {
            "You are a friendly travel agent"
            "Help plan trips step by step"
            "Ask clarifying questions about preferences"
            "Keep responses concise"
        })
    }
}
```

The session automatically maintains conversation context — each `respond(to:)` call adds to the transcript and the model sees the full history.

## Error Presentation

Present Foundation Models errors with appropriate user-facing messages:

```swift
@State private var errorMessage: String?
@State private var showError = false

func generate() async {
    do {
        let response = try await session.respond(to: prompt)
        // handle response
    } catch let error as LanguageModelSession.GenerationError {
        switch error {
        case .guardrailViolation:
            errorMessage = "Unable to generate a response for this request."
            if let suggestion = error.recoverySuggestion {
                errorMessage! += " \(suggestion)"
            }
        case .exceededContextWindowSize:
            errorMessage = "Conversation is too long. Starting fresh."
            session = LanguageModelSession(instructions: originalInstructions)
        case .rateLimited:
            errorMessage = "Please wait a moment before trying again."
        case .unsupportedLanguageOrLocale:
            errorMessage = "This language isn't supported yet."
        case .decodingError:
            errorMessage = "Something went wrong. Please try again."
        @unknown default:
            errorMessage = "An unexpected error occurred."
        }
        showError = true
    } catch {
        errorMessage = error.localizedDescription
        showError = true
    }
}

// In view body
.alert("Error", isPresented: $showError) {
    Button("OK") { }
} message: {
    if let errorMessage {
        Text(errorMessage)
    }
}
```

**Key details for guardrail errors:**
- `error.debugDescription` — technical details (for logging)
- `error.failureReason` — why the error occurred
- `error.recoverySuggestion` — what the user can try

Never expose raw error descriptions to users — they contain technical details.

## Progress Indicators

Show generation state with standard SwiftUI patterns:

```swift
struct GenerateButton: View {
    let session: LanguageModelSession
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            if session.isResponding {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("Generate")
            }
        }
        .disabled(session.isResponding)
    }
}
```

For inline progress during streaming:

```swift
VStack {
    if let partial = partialResult {
        PartialResultView(partial: partial)
    } else if session.isResponding {
        ProgressView("Generating...")
    }
}
```

## Environment-Injectable Service

For apps that need Foundation Models access across multiple views:

```swift
@Observable
class FoundationModelService {
    private(set) var isAvailable = false
    private(set) var unavailableReason: String?

    init() {
        checkAvailability()
    }

    func checkAvailability() {
        switch SystemLanguageModel.default.availability {
        case .available:
            isAvailable = true
            unavailableReason = nil
        case .unavailable(let reason):
            isAvailable = false
            switch reason {
            case .deviceNotEligible:
                unavailableReason = "Device not supported"
            case .appleIntelligenceNotEnabled:
                unavailableReason = "Enable Apple Intelligence in Settings"
            case .modelNotReady:
                unavailableReason = "Model downloading..."
            @unknown default:
                unavailableReason = "Unavailable"
            }
        }
    }

    func createSession(instructions: String) -> LanguageModelSession? {
        guard isAvailable else { return nil }
        return LanguageModelSession(instructions: instructions)
    }
}

// In App
@main
struct MyApp: App {
    @State private var modelService = FoundationModelService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(modelService)
        }
    }
}

// In any view
struct FeatureView: View {
    @Environment(FoundationModelService.self) private var modelService

    var body: some View {
        if modelService.isAvailable {
            // AI feature
        } else {
            ContentUnavailableView("AI Unavailable", systemImage: "apple.intelligence")
        }
    }
}
```

## Pre-warming on Navigation

Start loading the model before the user needs it:

```swift
struct RecipeListView: View {
    @State private var session: LanguageModelSession?

    var body: some View {
        List(recipes) { recipe in
            NavigationLink(value: recipe) {
                RecipeRow(recipe: recipe)
            }
        }
        .navigationDestination(for: Recipe.self) { recipe in
            RecipeDetailView(session: session, recipe: recipe)
        }
        .task {
            let s = LanguageModelSession(instructions: "You suggest recipe variations")
            try? await s.prewarm()
            session = s
        }
    }
}
```

Pre-warming on the list view means the model is ready when the user navigates to a detail view — no cold-start delay.
