#!/usr/bin/env bash
# Syncs skills and builds MCP server artifacts from workflow-systems into the plugin.
# Run locally before committing/pushing the plugin repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(iter write prompt-dev chat-migration code-audit)
SKILLS_SRC="$SCRIPT_DIR/../../skills"
SKILLS_DEST="$SCRIPT_DIR/skills"
MCP_SRC="$SCRIPT_DIR/../../mcp-servers/shortcuts-mcp"
MCP_DEST="$SCRIPT_DIR/mcp-servers/shortcuts-mcp"

echo "==> Syncing workflow-tools plugin"

# --- Skills ---
rm -rf "$SKILLS_DEST"
mkdir -p "$SKILLS_DEST"

for skill in "${SKILLS[@]}"; do
  if [ ! -d "$SKILLS_SRC/$skill" ]; then
    echo "ERROR: Skill not found: $SKILLS_SRC/$skill"
    exit 1
  fi

  echo "  Syncing skill: $skill"
  rsync -a --delete \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='.DS_Store' \
    --exclude='README.md' \
    --exclude='LICENSE' \
    --exclude='*-analysis.md' \
    "$SKILLS_SRC/$skill/" "$SKILLS_DEST/$skill/"
done

# --- MCP Server (build + copy artifacts) ---
if [ ! -d "$MCP_SRC" ]; then
  echo "ERROR: shortcuts-mcp not found: $MCP_SRC"
  exit 1
fi

echo "  Building shortcuts-mcp"
if [ -f "$MCP_SRC/pnpm-lock.yaml" ]; then
  (cd "$MCP_SRC" && pnpm install --frozen-lockfile)
else
  (cd "$MCP_SRC" && pnpm install)
fi
(cd "$MCP_SRC" && pnpm build)

rm -rf "$MCP_DEST"
mkdir -p "$MCP_DEST"

echo "  Copying shortcuts-mcp artifacts"
cp -r "$MCP_SRC/dist" "$MCP_DEST/dist"
cp "$MCP_SRC/package.json" "$MCP_DEST/package.json"

# Remove test files from dist
find "$MCP_DEST/dist" -name '*.test.js' -delete

# Install production deps only in the plugin copy
(cd "$MCP_DEST" && pnpm install --prod --ignore-scripts 2>/dev/null)

# Remove lockfile from plugin copy
rm -f "$MCP_DEST/pnpm-lock.yaml" "$MCP_DEST/package-lock.json"

# --- Summary ---
echo ""
echo "==> Sync complete"
echo ""
echo "Skills:"
for skill in "${SKILLS[@]}"; do
  if [ -f "$SKILLS_DEST/$skill/SKILL.md" ]; then
    echo "  + $skill"
  else
    echo "  ! $skill (MISSING SKILL.md)"
    exit 1
  fi
done
echo ""
echo "MCP Servers:"
if [ -f "$MCP_DEST/dist/server.js" ]; then
  echo "  + shortcuts-mcp (dist/server.js)"
else
  echo "  ! shortcuts-mcp (MISSING dist/server.js)"
  exit 1
fi
echo ""
echo "Ready to commit and push."
