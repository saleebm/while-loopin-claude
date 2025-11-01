#!/usr/bin/env bash
set -euo pipefail

# Demo script: Run generative art transformation from repo root
# Usage: bash demo-generative-art.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXAMPLE_DIR="$SCRIPT_DIR/examples/color-art-app"

echo "🎨 Generative Art Transformation Demo"
echo ""
echo "This will transform a simple 120-line color wheel into a"
echo "993-line generative art playground with 5 patterns!"
echo ""
echo "📍 Working directory: $EXAMPLE_DIR"
echo ""

# Check if we should reset first
if [[ -f "$EXAMPLE_DIR/index.html" ]]; then
  CURRENT_LINES=$(wc -l < "$EXAMPLE_DIR/index.html" | tr -d ' ')
  if [[ "$CURRENT_LINES" -gt 200 ]]; then
    echo "⚠️  index.html appears to be already transformed ($CURRENT_LINES lines)"
    echo ""
    read -p "Reset to simple starter before running? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "🔄 Resetting to simple color wheel..."
      (cd "$EXAMPLE_DIR" && git checkout index.html)
      echo "✅ Reset complete"
      echo ""
    fi
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🚀 Starting transformation..."
echo ""

# Run the agent from the example directory
cd "$EXAMPLE_DIR"
bash run-generative-agent.sh

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Transformation complete!"
echo ""
echo "📊 Results:"
echo "  • Before: 120 lines (simple rotating circles)"
echo "  • After:  $(wc -l < index.html | tr -d ' ') lines (5 generative patterns + controls)"
echo ""
echo "🎯 Next steps:"
echo "  1. View the result:  open examples/color-art-app/index.html"
echo "  2. See what changed: git diff examples/color-art-app/index.html"
echo "  3. Reset for demo:   cd examples/color-art-app && git checkout index.html"
echo ""
echo "📚 Documentation:"
echo "  • TRANSFORMATION-SUMMARY.md - Quick overview"
echo "  • WHAT-CLAUDE-BUILT.md - Technical deep dive"
echo ""
