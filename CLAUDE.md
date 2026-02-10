# CLAUDE.md

## Overview

Claude Code plugin packaging seven skills and a macOS Shortcuts MCP server. Synced from the workflow-systems monorepo — this repo holds distributable copies, not canonical sources.

## Key Commands

- `./build.sh` — validates plugin structure (skills, MCP artifacts, plugin.json)
- `./sync.sh` — copies skills + rebuilds MCP server (run from monorepo)
- `claude --plugin-dir .` — load plugin locally without installing
- `claude --debug` — debug plugin loading/registration

## Plugin Validation

`claude plugin validate .` validates marketplace JSON. `build.sh` is the structural validation layer — checks for `.claude-plugin/plugin.json`, `.mcp.json`, skill SKILL.md files, and MCP server artifacts.

## Environment

`CLAUDE_PLUGIN_ROOT` is set automatically by Claude Code at install time. During local development it is unset — `/doctor` warnings about missing env vars are expected and not a bug. The variable works in JSON configs (`.mcp.json`, `hooks.json`) but has a known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).

## Known Marketplace Bugs

- Schema URL 404 — `$schema` in marketplace.json doesn't resolve ([#9686](https://github.com/anthropics/claude-code/issues/9686))
- Submodules not cloned during marketplace install ([#17293](https://github.com/anthropics/claude-code/issues/17293)) — not an issue here since plugin ships flat copies
- Reserved names blocked: `claude-code-marketplace`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`

## Structure Notes

- Plugin installation is marketplace-only — no direct `claude plugin add` path exists
- `.claude-plugin/marketplace.json` makes the repo a self-listing marketplace (`source: "./"`)
- Skills live at `skills/<name>/SKILL.md` — must be at plugin root, not inside `.claude-plugin/`
- MCP config is standalone `.mcp.json` using `${CLAUDE_PLUGIN_ROOT}` for paths
- `node_modules/` is committed (production deps only) — required for plugin distribution
