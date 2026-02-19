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
| `swift-conventions` | Any Swift/SwiftUI code — quick-reference standards and Foundation Models API |
| `swiftui-expert-skill` | Building or reviewing SwiftUI views — state, animations, performance, Liquid Glass |
| `swift-concurrency` | Async/await, actors, sendable, tasks, Swift 6 migration |
| `axiom-swiftui-debugging` | View not updating, preview crashes, layout issues — use the decision trees |
| `axiom-swiftui-26-ref` | iOS 26 new features — Liquid Glass toolbars, WebView, rich text, @Animatable, sliders |
| `axiom-swift-testing` | Writing unit tests — @Test/@Suite, #expect/#require, parameterized tests, fast test setup |
| `axiom-accessibility-diag` | VoiceOver issues, Dynamic Type, contrast, touch targets, App Store review prep |
| `axiom-foundation-models-ref` | Foundation Models — LanguageModelSession, @Generable, @Guide, Tool protocol, streaming |
| `axiom-swiftdata` | SwiftData — @Model, @Query, @Relationship, CloudKit, migration, performance |

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
