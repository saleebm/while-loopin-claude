#!/usr/bin/env bash

# Resume Agent - Continue work on existing feature
# Usage: bash resume-agent.sh FEATURE_NAME [MAX_ITERATIONS]

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source agent runner
source "$SCRIPT_DIR/agent-runner.sh"

# Help
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  cat <<EOF
Usage: bash resume-agent.sh FEATURE_NAME [MAX_ITERATIONS]

Resume work on an existing feature in .specs/

Arguments:
  FEATURE_NAME      Name of feature directory in .specs/
  MAX_ITERATIONS    Max iterations (default: 10)

Example:
  bash resume-agent.sh multi-phase-context-framework 15
EOF
  exit 0
fi

FEATURE_NAME="$1"
MAX_ITERATIONS="${2:-10}"

FEATURE_DIR="$PROJECT_DIR/.specs/$FEATURE_NAME"
OUTPUT_DIR="$PROJECT_DIR/.ai-dr/agent-runs/$FEATURE_NAME"

# Validate feature exists
if [[ ! -d "$FEATURE_DIR" ]]; then
  echo "❌ Feature directory not found: $FEATURE_DIR"
  exit 1
fi

if [[ ! -f "$FEATURE_DIR/AGENT-PROMPT.md" ]]; then
  echo "❌ AGENT-PROMPT.md not found in: $FEATURE_DIR"
  exit 1
fi

if [[ ! -f "$FEATURE_DIR/HANDOFF.md" ]]; then
  echo "❌ HANDOFF.md not found in: $FEATURE_DIR"
  exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 Resuming Agent: $FEATURE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Feature: $FEATURE_DIR"
echo "📄 Prompt: $FEATURE_DIR/AGENT-PROMPT.md"
echo "📝 Handoff: $FEATURE_DIR/HANDOFF.md"
echo "🔄 Max iterations: $MAX_ITERATIONS"
echo ""

# Build args
AGENT_ARGS=(
  "$FEATURE_DIR/AGENT-PROMPT.md"
  "$FEATURE_DIR/HANDOFF.md"
  "$OUTPUT_DIR"
  "$MAX_ITERATIONS"
)

# Check for analysis.json to get original config
if [[ -f "$FEATURE_DIR/analysis.json" ]]; then
  ENABLE_REVIEW=$(jq -r '.enable_code_review // false' "$FEATURE_DIR/analysis.json")
  MAX_REVIEWS=$(jq -r '.max_reviews // 5' "$FEATURE_DIR/analysis.json")
  
  if [[ "$ENABLE_REVIEW" == "true" ]]; then
    AGENT_ARGS+=(--enable-code-review --max-reviews "$MAX_REVIEWS")
    echo "🔍 Code review enabled (max $MAX_REVIEWS reviews)"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_claude_agent "${AGENT_ARGS[@]}"

echo ""
echo "✅ Agent run complete"
echo "📁 Outputs: $OUTPUT_DIR"

