#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_DIR/lib/agent-runner.sh"

TMP_DIR=$(mktemp -d)
FEATURE_DIR="$TMP_DIR/feature"
RUNS_DIR="$TMP_DIR/runs"
mkdir -p "$FEATURE_DIR" "$RUNS_DIR"

cat > "$FEATURE_DIR/AGENT-PROMPT.md" <<'EOF'
# Minimal Prompt for Review

Make a trivial change in memory and prepare for review.
EOF

HANDOFF_FILE="$FEATURE_DIR/HANDOFF.md"

run_claude_agent \
  "$FEATURE_DIR/AGENT-PROMPT.md" \
  "$HANDOFF_FILE" \
  "$RUNS_DIR" \
  1 \
  --enable-code-review \
  --max-reviews 1

RUN_DIR=$(ls -dt "$RUNS_DIR"/* 2>/dev/null | head -1 || true)
REVIEW_JSON="$RUN_DIR/reviews/review_1.json"

if [[ ! -f "$REVIEW_JSON" ]]; then
  echo "❌ Review JSON not found: $REVIEW_JSON"
  exit 1
fi

jq empty "$REVIEW_JSON" >/dev/null 2>&1 || { echo "❌ Invalid JSON"; exit 1; }

echo "✅ Review JSON exists and is valid"

