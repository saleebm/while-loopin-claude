#!/usr/bin/env bash

# Quick test script for live development mode
# Sets defaults for a fast demo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Quick Test - Live Development Mode"
echo ""
echo "Running with fast defaults:"
echo "  • 3 iterations (quick demo)"
echo "  • 5 second rate limit"
echo "  • Auto-open browser"
echo "  • No code review"
echo "  • No speech"
echo ""

# Run with quick defaults, no interactive prompts
INTERACTIVE_MODE=false \
MAX_ITERATIONS=3 \
RATE_LIMIT_SECONDS=5 \
AUTO_OPEN=true \
ENABLE_SPEECH=false \
ENABLE_CODE_REVIEW=false \
bash "$SCRIPT_DIR/color-art-app/run-agent-live.sh"
