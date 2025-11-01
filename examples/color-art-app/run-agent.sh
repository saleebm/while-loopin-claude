#!/usr/bin/env bash

# Example: Run autonomous Claude agent on the color art app
# This demonstrates the agent loop with a fun, visual example

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
PROMPT_FILE="$EXAMPLE_DIR/AGENT-PROMPT.md"
HANDOFF_FILE="$EXAMPLE_DIR/HANDOFF.md"
OUTPUT_DIR="$REPO_ROOT/.ai-dr/agent-runs/color-art-app"
MAX_ITERATIONS=3

# Optional: Enable features via environment variables
# Uncomment or set before running:
# export ENABLE_SPEECH=true
# export ENABLE_CODE_REVIEW=true

echo "🎨 Color Art App - Autonomous Agent Demo"
echo ""
echo "This will run Claude to improve the color art generator."
echo "Watch the code evolve over $MAX_ITERATIONS iterations!"
echo ""
echo "📍 Working directory: $EXAMPLE_DIR"
echo "📝 Prompt: $PROMPT_FILE"
echo "📄 Handoff: $HANDOFF_FILE"
echo "📁 Outputs: $OUTPUT_DIR"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to example directory so Claude operates on these files
cd "$EXAMPLE_DIR"

# Run the agent!
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
echo "  1. Run the app to see changes:"
echo "     cd $EXAMPLE_DIR"
echo "     node color-art.js"
echo ""
echo "  2. Check what changed:"
echo "     git diff color-art.js"
echo ""
echo "  3. Read the handoff:"
echo "     cat HANDOFF.md"
echo ""
echo "  4. See full logs:"
echo "     ls -la $OUTPUT_DIR"
echo ""
