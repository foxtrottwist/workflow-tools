# workflow-tools

A Claude Code plugin bundling five skills and a macOS Shortcuts MCP server for productivity workflows.

## What's included

### Skills

| Skill | Trigger | What it does |
|-------|---------|--------------|
| [**iter**](https://github.com/foxtrottwist/iterative) | `/iter`, "help me build", "implement", "research" | Task orchestration with verification gates. Auto-detects development or knowledge work mode, decomposes into atomic tasks, runs each through fresh-context iterations. |
| [**write**](https://github.com/foxtrottwist/write) | `/write`, "compose", "draft", "proofread" | Written communication with quality standards. Compose messages, proofread text, or create professional content with iterative refinement. |
| [**prompt-dev**](https://github.com/foxtrottwist/prompt-dev) | `/prompt-dev`, "create a prompt", "build a template" | Prompt template development following Claude 4 conventions. Iterative DISCOVER → DRAFT → TEST → REFINE → VALIDATE workflow. |
| [**chat-migration**](https://github.com/foxtrottwist/chat-migration) | `/chat-migration`, "save context", "hitting context limit" | Captures conversation context into structured handoff documents for seamless continuation in a new chat. |
| [**code-audit**](https://github.com/foxtrottwist/code-audit) | `/code-audit`, "verify documentation", "check docs match code" | Documentation-code alignment verification using parallel subagents. Finds stale docs, drift, and inaccuracies. |

### MCP Server

[**shortcuts-mcp**](https://github.com/foxtrottwist/shortcuts-mcp) — Run, view, and manage macOS Shortcuts from Claude Code. Provides tools for executing shortcuts, browsing your library, and tracking usage patterns.

## Install

```bash
claude plugin add Foxtrottwist/workflow-tools
```

## Development

This plugin is synced from the [workflow-systems](https://github.com/Foxtrottwist/workflow-systems) monorepo. Skills and the MCP server live in their canonical locations there — this repo holds the distributable copies.

### Updating

From the workflow-systems monorepo:

```bash
cd plugins/workflow-tools
./sync.sh    # copies skills + rebuilds MCP server
./build.sh   # validates plugin structure
```

`sync.sh` handles:
- Copying skill files from canonical sources (excluding dev artifacts)
- Building shortcuts-mcp with pnpm
- Installing production-only dependencies
- Cleaning test files and lockfiles from the dist

### Structure

```
workflow-tools/
├── .claude-plugin/
│   └── plugin.json          # Plugin metadata
├── .mcp.json                # MCP server configuration
├── skills/
│   ├── iter/
│   ├── write/
│   ├── prompt-dev/
│   ├── chat-migration/
│   └── code-audit/
├── mcp-servers/
│   └── shortcuts-mcp/
│       ├── dist/            # Compiled server
│       ├── node_modules/    # Production deps
│       └── package.json
├── sync.sh                  # Sync from monorepo
├── build.sh                 # Validate structure
└── LICENSE
```

## License

MIT
