# CLAUDE.md

## Overview

Claude Code plugin packaging twenty-one skills, four specialized agents, and a macOS Shortcuts MCP server. This repo is the **canonical source** for all bundled skills and agents — edit them directly here.

**Productivity skills:** iter, writing, instruct-dev, sharpen, chat-migration, code-audit, azure-devops.

**Development discipline skills:** tdd, systematic-debugging, worktree.

**Swift/iOS skills:** swift-dev (hub with Foundation Models references), swift-concurrency, swiftui-expert-skill, axiom-accessibility-diag, foundation-models-ref, foundation-models, foundation-models-diag, axiom-swift-testing, axiom-swiftdata, axiom-swiftui-26-ref, axiom-swiftui-debugging. The swift-dev hub skill routes to specialist skills and includes shared lint tooling at `scripts/swift-pattern-lint.sh`.

## Key Commands

- `./build.sh` — validates plugin structure (skills, agents, MCP artifacts, plugin.json)
- `./sync.sh` — rebuilds MCP server artifacts from monorepo source (skills are edited directly here)
- `claude --plugin-dir .` — load plugin locally without installing
- `claude --debug` — debug plugin loading/registration

## Versioning

Bump the version in **both** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` whenever making changes. `claude plugin update` compares the installed version against the marketplace version — if they match, it silently no-ops. Without a bump, users must uninstall and reinstall to pick up changes.

Use semver: patch for bug fixes, minor for new/updated skills, major for breaking changes.

## Plugin Validation

`claude plugin validate .` validates marketplace JSON. `build.sh` is the structural validation layer — checks for `.claude-plugin/plugin.json`, `.mcp.json`, skill SKILL.md files, agent .md files, and MCP server artifacts.

## Environment

`CLAUDE_PLUGIN_ROOT` is set automatically by Claude Code at install time. During local development it is unset — `/doctor` warnings about missing env vars are expected and not a bug. The variable works in JSON configs (`.mcp.json`, `hooks.json`) but has a known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).

## Known Marketplace Bugs

- Schema URL 404 — `$schema` in marketplace.json doesn't resolve ([#9686](https://github.com/anthropics/claude-code/issues/9686))
- Submodules not cloned during marketplace install ([#17293](https://github.com/anthropics/claude-code/issues/17293)) — not an issue here since plugin ships flat copies
- Reserved names blocked: `claude-code-marketplace`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`

## Agents

Four specialized agents with restricted tool access and focused mandates. Agents provide behavioral constraints (how to operate) while skills provide domain knowledge (what to do).

| Agent | Role | Model | Pairs With |
|-------|------|-------|------------|
| researcher | Information gathering and synthesis | sonnet | iter (knowledge mode), general exploration |
| verifier | Adversarial review against acceptance criteria | sonnet | iter (verification gates) |
| orchestrator | Task decomposition and planning | opus | iter (development and knowledge modes) |
| editor | Editorial review against writing standards | sonnet | writing skill |

Agents live at `agents/<name>.md` at plugin root. They use YAML frontmatter for configuration (name, description, tools, model, skills) and markdown body for system prompt.

## Adding a New Agent

1. Create agent file at `agents/<name>.md` with frontmatter (name, description, tools, model) and system prompt
2. Add agent name to the `AGENTS` array in `build.sh`
3. Bump version in both `plugin.json` and `marketplace.json`
4. Run `bash build.sh` to validate

## Adding a New Skill

1. Create skill directory at `skills/<name>/` with `SKILL.md` (and optional `references/`, `scripts/`, `assets/`)
2. Add skill name to the `SKILLS` array in `build.sh` (hardcoded, not auto-discovered)
3. Bump version in both `plugin.json` and `marketplace.json`
4. Update skill count and description in `marketplace.json`
5. Run `bash build.sh` to validate

## Hooks

Plugin ships `hooks/hooks.json` with hooks that pair with bundled skills:

| Hook | Event | Pairs With |
|------|-------|------------|
| `hooks/swift-patterns.sh` | PreToolUse (Edit\|Write) | swift-dev ecosystem — blocks deprecated Swift patterns |
| `hooks/swift-skill-nudge.sh` | UserPromptSubmit | swift-dev routing — nudges skill usage for Swift prompts |
| `hooks/verification-nudge.sh` | Stop | TDD, iter — prompts build/test verification before stopping |
| `hooks/claude-md-bloat-guard.sh` | PreToolUse (Edit\|Write) | Optimization principles — warns on CLAUDE.md bloat |

All plugin hooks skip subagents via `agent_id` guard and use fail-open design (`|| exit 0` on stdin/jq).

## Structure Notes

- Plugin installation is marketplace-only — no direct `claude plugin add` path exists
- `.claude-plugin/marketplace.json` makes the repo a self-listing marketplace (`source: "./"`)
- Skills live at `skills/<name>/SKILL.md` — must be at plugin root, not inside `.claude-plugin/`
- MCP config is standalone `.mcp.json` using `${CLAUDE_PLUGIN_ROOT}` for paths
- `node_modules/` is committed (production deps only) — required for plugin distribution
