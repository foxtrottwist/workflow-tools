#!/usr/bin/env bash
# Validates plugin structure. All artifacts are pre-built by sync.sh.
# Runs locally or in CI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(iter write prompt-dev chat-migration code-audit azure-devops skill-creator)
MCP_DIR="$SCRIPT_DIR/mcp-servers/shortcuts-mcp"

echo "==> Validating workflow-tools plugin"

errors=0

# plugin.json
if [ ! -f "$SCRIPT_DIR/.claude-plugin/plugin.json" ]; then
  echo "  FAIL: .claude-plugin/plugin.json missing"
  errors=$((errors + 1))
else
  echo "  OK: .claude-plugin/plugin.json"
fi

# .mcp.json
if [ ! -f "$SCRIPT_DIR/.mcp.json" ]; then
  echo "  FAIL: .mcp.json missing"
  errors=$((errors + 1))
else
  echo "  OK: .mcp.json"
fi

# Skills
for skill in "${SKILLS[@]}"; do
  if [ -f "$SCRIPT_DIR/skills/$skill/SKILL.md" ]; then
    echo "  OK: skills/$skill"
  else
    echo "  FAIL: skills/$skill/SKILL.md missing"
    errors=$((errors + 1))
  fi
done

# MCP artifacts
if [ -f "$MCP_DIR/dist/server.js" ]; then
  echo "  OK: mcp-servers/shortcuts-mcp/dist/server.js"
else
  echo "  FAIL: mcp-servers/shortcuts-mcp/dist/server.js missing"
  errors=$((errors + 1))
fi

if [ -d "$MCP_DIR/node_modules" ]; then
  echo "  OK: mcp-servers/shortcuts-mcp/node_modules"
else
  echo "  FAIL: mcp-servers/shortcuts-mcp/node_modules missing"
  errors=$((errors + 1))
fi

echo ""
if [ "$errors" -gt 0 ]; then
  echo "==> Validation failed with $errors error(s)"
  echo "    Run sync.sh from workflow-systems to populate artifacts."
  exit 1
fi

echo "==> Validation passed"
