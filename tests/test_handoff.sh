#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_DIR/lib/agent-runner.sh"

TMP_DIR=$(mktemp -d)
FEATURE_DIR="$TMP_DIR/feature"
RUNS_DIR="$TMP_DIR/runs"
mkdir -p "$FEATURE_DIR" "$RUNS_DIR"

cat > "$FEATURE_DIR/AGENT-PROMPT.md" <<'EOF'
# Minimal Prompt

Write a one-line summary and produce a handoff as needed.
EOF

HANDOFF_FILE="$FEATURE_DIR/HANDOFF.md"

run_claude_agent \
  "$FEATURE_DIR/AGENT-PROMPT.md" \
  "$HANDOFF_FILE" \
  "$RUNS_DIR" \
  1 \
  --handoff auto

if [[ ! -f "$HANDOFF_FILE" ]]; then
  echo "❌ Handoff not created"
  exit 1
fi

grep -q "Session End" "$HANDOFF_FILE" || { echo "❌ Missing 'Session End'"; exit 1; }
grep -qi "Status:" "$HANDOFF_FILE" || { echo "❌ Missing 'Status:'"; exit 1; }

echo "✅ Handoff created with required markers"

