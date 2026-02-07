# CLAUDE.md

## Overview

Claude Code plugin packaging five skills and a macOS Shortcuts MCP server. Synced from the workflow-systems monorepo — this repo holds distributable copies, not canonical sources.

## Key Commands

- `./build.sh` — validates plugin structure (skills, MCP artifacts, plugin.json)
- `./sync.sh` — copies skills + rebuilds MCP server (run from monorepo)
- `claude --plugin-dir .` — load plugin locally without installing
- `claude --debug` — debug plugin loading/registration

## Plugin Validation

No official `claude plugin validate` command exists. `build.sh` is the validation layer. It checks for `.claude-plugin/plugin.json`, `.mcp.json`, skill SKILL.md files, and MCP server artifacts.

## Environment

`CLAUDE_PLUGIN_ROOT` is set automatically by Claude Code at install time. During local development it is unset — `/doctor` warnings about missing env vars are expected and not a bug. The variable works in JSON configs (`.mcp.json`, `hooks.json`) but has a known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).

## Structure Notes

- Skills live at `skills/<name>/SKILL.md` — must be at plugin root, not inside `.claude-plugin/`
- MCP config is standalone `.mcp.json` using `${CLAUDE_PLUGIN_ROOT}` for paths
- `node_modules/` is committed (production deps only) — required for plugin distribution
