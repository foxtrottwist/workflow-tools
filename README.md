# workflow-tools

A Claude Code plugin bundling twenty skills and a macOS Shortcuts MCP server for productivity and Swift/iOS development workflows.

## What's included

### Productivity Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| **iter** | `/iter`, "help me build", "implement", "research" | Task orchestration with verification gates. Auto-detects development or knowledge work mode. |
| **writing** | `/write`, "compose", "draft", "proofread" | Written communication with quality standards. Compose, proofread, or create professional content. |
| **prompt-dev** | `/prompt-dev`, "create a prompt", "build a template" | Prompt template development following Claude 4 conventions. |
| **sharpen** | "sharpen", "refine my thinking", "focus this idea" | Refine raw thoughts into focused statements of intent through guided questioning. |
| **chat-migration** | `/chat-migration`, "save context", "hitting context limit" | Capture conversation context into structured handoff documents for new chats. |
| **code-audit** | `/code-audit`, "verify documentation", "check docs match code" | Documentation-code alignment verification using parallel subagents. |
| **azure-devops** | "review PR", "PR comments", "az repos", "az devops" | Azure DevOps CLI recipes for PR operations via `az repos` and `az devops invoke`. |

### Development Discipline Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| **tdd** | Starting feature work, bug fixes, refactoring | Enforce RED-GREEN-REFACTOR discipline. No production code without a failing test. |
| **systematic-debugging** | Bugs, test failures, unexpected behavior | Find root cause before proposing fixes. Investigation-first approach. |
| **worktree** | Starting new branches, parallel sessions | Create isolated git worktrees for concurrent Claude Code sessions. |

### Swift/iOS Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| **swift-dev** | Swift, SwiftUI, iOS development | Hub skill — routes to specialist skills for deep guidance. |
| **swift-concurrency** | async/await, actors, Sendable, Swift 6 migration | Expert guidance on Swift Concurrency patterns and safety. |
| **swiftui-expert-skill** | Building or reviewing SwiftUI views | State management, view composition, performance, Liquid Glass adoption. |
| **swift-conventions** | Generating or reviewing Swift code | Quick-reference coding standards for Swift 6.2, SwiftUI, SwiftData, Foundation Models. |
| **axiom-accessibility-diag** | VoiceOver issues, Dynamic Type, color contrast | Accessibility diagnostics with WCAG compliance for iOS/macOS. |
| **axiom-foundation-models-ref** | On-device AI, @Generable, LanguageModelSession | Complete Foundation Models framework reference (iOS 26+). |
| **axiom-swift-testing** | Writing unit tests, Swift Testing framework | @Test/@Suite macros, #expect/#require, parameterized tests, fast test setup. |
| **axiom-swiftdata** | @Model, @Query, ModelContext, CloudKit | SwiftData persistence patterns and iOS 26+ features. |
| **axiom-swiftui-26-ref** | iOS 26 SwiftUI features | Liquid Glass, @Animatable, WebView, rich text editing, 3D spatial layout. |
| **axiom-swiftui-debugging** | View not updating, preview crashes, layout issues | Diagnostic decision trees for SwiftUI debugging. |

### MCP Server

[**shortcuts-mcp**](https://github.com/foxtrottwist/shortcuts-mcp) — Run, view, and manage macOS Shortcuts from Claude Code. Provides tools for executing shortcuts, browsing your library, and tracking usage patterns.

## Install

Add the marketplace and install the plugin:

```
/plugin marketplace add Foxtrottwist/workflow-tools
/plugin install workflow-tools@workflow-tools
```

Or from the CLI:

```bash
claude plugin marketplace add Foxtrottwist/workflow-tools
claude plugin install workflow-tools@workflow-tools
```

## Development

Skills are edited directly in this repo — it is the canonical source. The MCP server source lives in `mcp-servers/shortcuts-mcp` in the [workflow-systems](https://github.com/Foxtrottwist/workflow-systems) monorepo and is built into this repo via `sync.sh`.

### Updating MCP artifacts

From the workflow-systems monorepo:

```bash
cd plugins/workflow-tools
./sync.sh    # rebuilds MCP server artifacts
./build.sh   # validates plugin structure
```

### Local testing

```bash
claude --plugin-dir .
```

Running `/doctor` during local development will show a warning about `CLAUDE_PLUGIN_ROOT` being missing. This is expected — Claude Code sets that variable automatically at install time. The warning does not appear for end users after installation via the marketplace.

### Structure

```
workflow-tools/
├── .claude-plugin/
│   ├── marketplace.json     # Marketplace catalog
│   └── plugin.json          # Plugin metadata
├── .mcp.json                # MCP server configuration
├── skills/
│   ├── iter/
│   ├── writing/
│   ├── prompt-dev/
│   ├── sharpen/
│   ├── chat-migration/
│   ├── code-audit/
│   ├── azure-devops/
│   ├── tdd/
│   ├── systematic-debugging/
│   ├── worktree/
│   ├── swift-dev/
│   ├── swift-concurrency/
│   ├── swiftui-expert-skill/
│   ├── swift-conventions/
│   ├── axiom-accessibility-diag/
│   ├── axiom-foundation-models-ref/
│   ├── axiom-swift-testing/
│   ├── axiom-swiftdata/
│   ├── axiom-swiftui-26-ref/
│   └── axiom-swiftui-debugging/
├── mcp-servers/
│   └── shortcuts-mcp/
│       ├── dist/            # Compiled server
│       ├── node_modules/    # Production deps
│       └── package.json
├── sync.sh                  # Build MCP artifacts
├── build.sh                 # Validate structure
└── LICENSE
```

## License

MIT
