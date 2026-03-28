# CLAUDE.md

## Build / Test

- `bash build.sh` — validates plugin structure (skills, agents, hooks, MCP)
- `claude --plugin-dir .` — load plugin locally without installing

## Versioning

Bump version in **both** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. `claude plugin update` silently no-ops if versions match.

## Constraints

- Skills array in `build.sh` is hardcoded — add new skills there, not auto-discovered
- `node_modules/` is committed (production deps only) — required for plugin distribution
- All hooks skip subagents via `agent_id` guard and use fail-open design (`|| exit 0`)

## Corrections

_(None yet — add when an observed failure warrants it.)_

## Gotchas

- `CLAUDE_PLUGIN_ROOT` is unset during local dev — `/doctor` warnings are expected. Known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).
- Schema URL in marketplace.json 404s ([#9686](https://github.com/anthropics/claude-code/issues/9686))
- Reserved plugin names: `claude-code-marketplace`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`
