# CLAUDE.md

## Build / Test

- `bash build.sh` — validates plugin structure (skills, agents, hooks, MCP)
- `claude --plugin-dir .` — load plugin locally without installing

## Constraints

- `node_modules/` is committed (production deps only) — required for plugin distribution

## Corrections

_(None yet — add when an observed failure warrants it.)_

## Gotchas

- `CLAUDE_PLUGIN_ROOT` is unset during local dev — `/doctor` warnings are expected. Known bug in command markdown files ([#9354](https://github.com/anthropics/claude-code/issues/9354)).

## Path-Scoped Rules

- `.claude/rules/plugin-packaging.md` — versioning, `build.sh` SKILLS array, marketplace.json quirks. Loads when editing `.claude-plugin/*.json` or `build.sh`.
- `.claude/rules/hooks.md` — hook script conventions. Loads when editing `hooks/**`.
