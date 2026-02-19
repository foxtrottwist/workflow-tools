#!/usr/bin/env bash
# Rebuilds MCP server artifacts from workflow-systems into the plugin.
# Skills are edited directly in the plugin — no syncing needed.
# Run locally before committing/pushing the plugin repo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SRC="$SCRIPT_DIR/../../mcp-servers/shortcuts-mcp"
MCP_DEST="$SCRIPT_DIR/mcp-servers/shortcuts-mcp"

echo "==> Building workflow-tools plugin artifacts"

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

# Install production deps with npm for a flat, portable node_modules.
# pnpm creates relative symlinks that work correctly, but Claude Code's plugin
# cache resolves them to absolute paths pointing back to the marketplace directory.
# When the marketplace updates (transitive dep version bumps), those absolute
# paths go stale and the server fails to start. npm's flat layout avoids this.
(cd "$MCP_DEST" && npm install --omit=dev --ignore-scripts --no-audit --no-fund 2>/dev/null)

# Remove lockfile from plugin copy
rm -f "$MCP_DEST/pnpm-lock.yaml" "$MCP_DEST/package-lock.json"

# --- Summary ---
echo ""
echo "==> Build complete"
echo ""
echo "MCP Servers:"
if [ -f "$MCP_DEST/dist/server.js" ]; then
  echo "  + shortcuts-mcp (dist/server.js)"
else
  echo "  ! shortcuts-mcp (MISSING dist/server.js)"
  exit 1
fi
echo ""
echo "Run build.sh to validate the full plugin structure."
