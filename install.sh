#!/usr/bin/env bash
# Crescendo Claude Skills — Developer Onboarding
# Run once per machine: bash <(curl -s https://raw.githubusercontent.com/sajithkaimal/-sajith-skills/main/install.sh)

set -euo pipefail

CANVAS_URL="https://excalidraw-canvas-234415802046.us-central1.run.app"
MCP_EXCALIDRAW_DIR="$HOME/Projects/mcp_excalidraw"
SKILLS_REPO="https://github.com/sajithkaimal/-sajith-skills"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "=== Crescendo Claude Skills Setup ==="
echo ""

# 1. Verify gcloud auth
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@crescendo.ai"; then
  echo "Authenticating with Google..."
  gcloud auth login
fi
echo -e "${GREEN}✓ gcloud authenticated${NC}"

# 2. Clone or update mcp_excalidraw
if [ -d "$MCP_EXCALIDRAW_DIR" ]; then
  echo "Updating mcp_excalidraw..."
  git -C "$MCP_EXCALIDRAW_DIR" pull --quiet
else
  echo "Cloning mcp_excalidraw..."
  git clone https://github.com/yctimlin/mcp_excalidraw "$MCP_EXCALIDRAW_DIR" --quiet
  cd "$MCP_EXCALIDRAW_DIR" && npm ci --silent && npm run build --silent
fi
echo -e "${GREEN}✓ mcp_excalidraw ready at $MCP_EXCALIDRAW_DIR${NC}"

# 3. Register MCP server pointing to shared Cloud Run canvas
claude mcp add excalidraw -s user \
  -e "EXPRESS_SERVER_URL=$CANVAS_URL" \
  -- node "$MCP_EXCALIDRAW_DIR/dist/index.js" 2>/dev/null || \
claude mcp remove excalidraw -s user 2>/dev/null && \
claude mcp add excalidraw -s user \
  -e "EXPRESS_SERVER_URL=$CANVAS_URL" \
  -- node "$MCP_EXCALIDRAW_DIR/dist/index.js"
echo -e "${GREEN}✓ Excalidraw MCP server registered (canvas: $CANVAS_URL)${NC}"

# 4. Install skills
mkdir -p "$HOME/.claude/skills"
TMPDIR=$(mktemp -d)
git clone "$SKILLS_REPO" "$TMPDIR" --quiet --depth 1
cp -r "$TMPDIR/skills/"* "$HOME/.claude/skills/"
rm -rf "$TMPDIR"
echo -e "${GREEN}✓ Skills installed to ~/.claude/skills/${NC}"

echo ""
echo -e "${YELLOW}Setup complete! Next steps:${NC}"
echo "  1. Open the shared canvas in your browser: $CANVAS_URL"
echo "  2. Restart Claude Code to pick up the new MCP server"
echo "  3. Try it: /excalidraw draw a simple architecture diagram"
echo ""
