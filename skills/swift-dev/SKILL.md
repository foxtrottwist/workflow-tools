---
name: swift-dev
description: 'Swift and iOS development hub. Activates for Swift, SwiftUI, iOS, iPadOS, visionOS, SwiftData, Swift concurrency, Foundation Models, and Apple platform development. Routes to specialist skills for deep guidance on specific topics.'
---
# Swift Development

Hub skill for Swift/iOS development. Provides quick-reference rules and routes to specialist skills for deep dives.

## Skills Routing

Consult specialist skills for detailed guidance. Read the SKILL.md (and any `references/` files) before writing code in that area.

| Skill | When to consult |
|-------|----------------|
| `swiftui-expert-skill` | Building or reviewing SwiftUI views — state, animations, performance, Liquid Glass |
| `swift-concurrency` | Async/await, actors, sendable, tasks, Swift 6 migration |
| `axiom-swiftui-debugging` | View not updating, preview crashes, layout issues — use the decision trees |
| `axiom-swiftui-26-ref` | iOS 26 new features — Liquid Glass toolbars, WebView, rich text, @Animatable, sliders |
| `axiom-swift-testing` | Writing unit tests — @Test/@Suite, #expect/#require, parameterized tests, fast test setup |
| `axiom-accessibility-diag` | VoiceOver issues, Dynamic Type, contrast, touch targets, App Store review prep |
| `foundation-models-ref` | Foundation Models — LanguageModelSession, @Generable, @Guide, Tool protocol, streaming |
| `foundation-models` | Foundation Models discipline — anti-patterns, decision trees, pressure scenarios |
| `foundation-models-diag` | Foundation Models diagnostics — error triage, Instruments profiling, production crisis |
| `axiom-swiftdata` | SwiftData — @Model, @Query, @Relationship, CloudKit, migration, performance |

### Foundation Models References

When writing or reviewing Foundation Models code, read the applicable references first:

| Task | Read |
|------|------|
| Any FM work | [references/foundation-models.md](references/foundation-models.md) |
| Structured output (`@Generable`) | [references/foundation-models-generable.md](references/foundation-models-generable.md) |
| Tool definitions | [references/foundation-models-tools.md](references/foundation-models-tools.md) |
| Performance issues or optimization | [references/foundation-models-performance.md](references/foundation-models-performance.md) |
| SwiftUI integration patterns | [references/foundation-models-swiftui.md](references/foundation-models-swiftui.md) |

Read multiple references when tasks overlap (e.g., a tool returning `@Generable` types).

## Swift Rules

- Target iOS 26+ and Swift 6.2+ exclusively
- Use modern Swift concurrency (`async`/`await`, actors, structured concurrency) — no GCD
- No third-party dependencies without explicit approval
- Avoid UIKit unless SwiftUI has no equivalent
- Use `@Observable` macro with `@MainActor` isolation for view models
- Enable strict concurrency checking — resolve all warnings
- Use `localizedStandardContains()` for user-facing string searches
- Minimize force unwraps (`!`) and force tries (`try!`) — use `guard`, `if let`, or `try?`
- Use typed throws (`async throws(MyError)`) for predictable failure modes — avoid `Result` with async/await
- Use modern Foundation APIs: `AttributedString`, `FormatStyle`, `Duration`, `Regex`
- Prefer `String(localized:)` over `NSLocalizedString`
- Use `sending` parameter annotation where appropriate for concurrency safety
- Mark types as `Sendable` when they cross isolation boundaries
- Prefer Swift-native string methods: `replacing(_:with:)` over `replacingOccurrences(of:with:)`
- Prefer modern Foundation: `URL.documentsDirectory`, `appending(path:)`
- Prefer static member lookup: `.circle` over `Circle()`, `.borderedProminent` over `BorderedProminentButtonStyle()`

## SwiftUI Rules

- Use `foregroundStyle()` over `foregroundColor()`
- Use `clipShape(.rect(cornerRadius:))` over `cornerRadius()` modifier
- Use the Tab API (`Tab("Title", systemImage:) { }`) for tab bars
- Do NOT use `ObservableObject`/`@Published` — use `@Observable` macro instead
- Use `NavigationStack` with `navigationDestination(for:)` — not `NavigationView` or `NavigationLink(destination:)`
- Extract subviews as separate structs with descriptive names — not computed properties
- Support Dynamic Type — never hardcode font sizes, use relative sizing
- Prefer `containerRelativeFrame()` and `visualEffect()` over `GeometryReader` when possible
- Use `bold()` over `fontWeight(.bold)`
- Use `scrollIndicators(.hidden)` to hide scroll indicators
- Use `ForEach(items.enumerated(), id: \.element.id)` when index is needed — do not wrap in `Array()`
- Use `scrollTargetBehavior(.viewAligned)` and `scrollTargetLayout()` for snap scrolling
- `Section("Title") { } footer: { }` doesn't compile — use `Section { } header: { Text("Title") } footer: { }` when both header and footer are needed
- `onChange` with two parameters or zero — never one-parameter variant
- `Button` for taps — `onTapGesture()` only when tap location/count needed
- `Task.sleep(for:)` not `Task.sleep(nanoseconds:)`
- Never use `UIScreen.main.bounds` for available space
- Button images need text: `Button("Action", systemImage: "plus", action: handler)`
- `ImageRenderer` over `UIGraphicsImageRenderer`
- Number formatting: `Text(value, format: .number.precision(.fractionLength(2)))` — never `String(format:)`
- Avoid `AnyView` unless required
- Avoid hardcoded padding/spacing values

## State Management

- Prefer `@Environment` values over singletons for dependency injection
- Use `@State` for view-local state owned by a single view
- Use `@Binding` to pass write access to a parent's `@State` down to a child
- Use `@Bindable` to create bindings from an `@Observable` object's properties
- Use `@Environment` to inject shared dependencies (model contexts, services, settings)
- When a decision has 3+ branches, centralize the logic in a private `enum`

## Logging

Use `os.Logger` exclusively — no `print()` or `NSLog()`. Centralize categories in a `Logger` extension file with `static nonisolated let` properties.

- **Setup:** Each file declares `private nonisolated let log = Logger.<category>` at file scope
- **Categories:** One per service/feature area

**Log levels:** `debug` (verbose), `info` (milestones), `warning` (recoverable), `error` (failures), `fault` (system corruption only)

**Gotchas:**
- `os.Logger` interpolation evaluates in a closure context — `@Observable` properties need explicit `self.`
- File-scope `private let log = Logger(...)` inherits MainActor isolation when `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — use `private nonisolated let`

## SwiftData Rules

- When using CloudKit sync, do NOT use `@Attribute(.unique)` — CloudKit does not support unique constraints
- All model properties must have default values or be optional for CloudKit compatibility
- Use optional relationships — CloudKit requires them
- Use `@Model` macro and define schema with `@Attribute`, `@Relationship`
- Prefer `#Predicate` macro over raw `NSPredicate`
- Use `modelContext.save()` explicitly at logical save points

## Accessibility

- Provide VoiceOver labels for all interactive elements and meaningful images
- Support Dynamic Type — test with largest accessibility sizes
- Maintain sufficient color contrast (WCAG 2.1 AA: 4.5:1 text, 3:1 large text/UI)
- Support full keyboard and Switch Control navigation
- Use SF Symbols with text labels — do not rely on icons alone
- Do NOT use "sparkles" SF Symbol or any sparkle-style icon
- Use `.accessibilityLabel()`, `.accessibilityHint()`, `.accessibilityValue()` appropriately
- Group related elements with `.accessibilityElement(children: .combine)`

## Pattern Lint

Run the shared lint script to scan for known anti-patterns:
```
../../scripts/swift-pattern-lint.sh <project-dir> <skill>/references/lint-patterns.json
```
Skills with lint patterns: `swift-concurrency`, `swiftui-expert-skill`, `axiom-accessibility-diag`.
