#!/usr/bin/env bash

# Run autonomous Claude agent on the GENERATIVE ART playground
# This will create stunning visual art with HSLA color theory

set -euo pipefail

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXAMPLE_DIR="$SCRIPT_DIR"

# Set PROJECT_DIR for agent-runner.sh
export PROJECT_DIR="$REPO_ROOT"

# Source the agent runner library
source "$REPO_ROOT/lib/agent-runner.sh"

# Configuration
PROMPT_FILE="$EXAMPLE_DIR/AGENT-PROMPT-GENERATIVE.md"
HANDOFF_FILE="$EXAMPLE_DIR/HANDOFF-GENERATIVE.md"
OUTPUT_DIR="$REPO_ROOT/.ai-dr/agent-runs/generative-art"
MAX_ITERATIONS=5

echo "🌈 Generative Art Playground - Autonomous Agent"
echo ""
echo "Claude will transform index.html into a mind-blowing"
echo "generative art experience with HSLA color theory!"
echo ""
echo "📍 Working directory: $EXAMPLE_DIR"
echo "📝 Prompt: $PROMPT_FILE"
echo "📄 Handoff: $HANDOFF_FILE"
echo "📁 Outputs: $OUTPUT_DIR"
echo "🔄 Max iterations: $MAX_ITERATIONS"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to example directory so Claude operates on these files
cd "$EXAMPLE_DIR"

# Run the agent with more iterations for creative exploration
run_claude_agent \
  "$PROMPT_FILE" \
  "$HANDOFF_FILE" \
  "$OUTPUT_DIR" \
  $MAX_ITERATIONS \
  --handoff auto \
  --handoff-template "$REPO_ROOT/templates/handoff-system-prompt.md"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Agent run complete!"
echo ""
echo "🎯 Next steps:"
echo ""
echo "  1. Open the art in your browser:"
echo "     open index.html"
echo "     # or:"
echo "     python3 -m http.server 8000"
echo "     # then visit: http://localhost:8000"
echo ""
echo "  2. Check what changed:"
echo "     git diff index.html"
echo ""
echo "  3. Read the handoff:"
echo "     cat HANDOFF-GENERATIVE.md"
echo ""
echo "  4. See full logs:"
echo "     ls -la $OUTPUT_DIR"
echo ""
echo "🎨 Prepare to be amazed by generative beauty!"
echo ""
