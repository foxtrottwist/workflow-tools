# CLAUDE.md

## Overview

Claude Code plugin packaging eighteen skills and a macOS Shortcuts MCP server. This repo is the **canonical source** for all bundled skills — edit skills directly here.

**Productivity skills:** iter, writing, prompt-dev, sharpen, chat-migration, code-audit, azure-devops, skill-creator.

**Swift/iOS skills:** swift-dev (hub), swift-concurrency, swiftui-expert-skill, swift-conventions, axiom-accessibility-diag, axiom-foundation-models-ref, axiom-swift-testing, axiom-swiftdata, axiom-swiftui-26-ref, axiom-swiftui-debugging. The swift-dev hub skill routes to specialist skills and includes shared lint tooling at `scripts/swift-pattern-lint.sh`. Hookify rules for Swift patterns live in `hookify-rules/`.

## Key Commands

- `./build.sh` — validates plugin structure (skills, MCP artifacts, plugin.json)
- `claude --plugin-dir .` — load plugin locally without installing
- `claude --debug` — debug plugin loading/registration

## Versioning

Bump the version in **both** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` whenever making changes. `claude plugin update` compares the installed version against the marketplace version — if they match, it silently no-ops. Without a bump, users must uninstall and reinstall to pick up changes.

Use semver: patch for bug fixes, minor for new/updated skills, major for breaking changes.

## Plugin Validation

`claude plugin validate .` validates marketplace JSON. `build.sh` is the structural validation layer — checks for `.claude-plugin/plugin.json`, `.mcp.json`, skill SKILL.md files, and MCP server artifacts.

## Environment

`CLAUDE_PLUGIN_ROOT` is set automatically by Claude Code at install time. During local development it is unset — `/doctor` warnings about missing env vars are expected and not a bug. The variable works in JSON configs (`.mcp.json`, `hooks.json`) but has a known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).

## Known Marketplace Bugs

- Schema URL 404 — `$schema` in marketplace.json doesn't resolve ([#9686](https://github.com/anthropics/claude-code/issues/9686))
- Submodules not cloned during marketplace install ([#17293](https://github.com/anthropics/claude-code/issues/17293)) — not an issue here since plugin ships flat copies
- Reserved names blocked: `claude-code-marketplace`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`

## Adding a New Skill

1. Create skill directory at `skills/<name>/` with `SKILL.md` (and optional `references/`, `scripts/`, `assets/`)
2. Add skill name to the `SKILLS` array in `build.sh` (hardcoded, not auto-discovered)
3. Bump version in both `plugin.json` and `marketplace.json`
4. Update skill count and description in `marketplace.json`
5. Run `bash build.sh` to validate

## Structure Notes

- Plugin installation is marketplace-only — no direct `claude plugin add` path exists
- `.claude-plugin/marketplace.json` makes the repo a self-listing marketplace (`source: "./"`)
- Skills live at `skills/<name>/SKILL.md` — must be at plugin root, not inside `.claude-plugin/`
- MCP config is standalone `.mcp.json` using `${CLAUDE_PLUGIN_ROOT}` for paths
- `node_modules/` is committed (production deps only) — required for plugin distribution
