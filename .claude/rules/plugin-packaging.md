---
paths:
  - ".claude-plugin/*.json"
  - "build.sh"
---

# Plugin Packaging

- Bump version in **both** `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`. `claude plugin update` silently no-ops if versions match.
- Skills array in `build.sh` is hardcoded — add new skills there, not auto-discovered.
- Schema URL in `marketplace.json` 404s ([#9686](https://github.com/anthropics/claude-code/issues/9686)) — expected, not a bug to chase.
- Reserved plugin names, do not use: `claude-code-marketplace`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`.
