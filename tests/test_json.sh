#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_DIR/lib/claude-functions.sh"

TMP_FILE=$(mktemp)
echo "This is a tiny output to summarize." > "$TMP_FILE"

JSON=$(generate_structured_output "$TMP_FILE" '{"score":0}')
echo "$JSON" | jq empty >/dev/null 2>&1 || { echo "❌ Not valid JSON"; exit 1; }

echo "$JSON" | jq -e '.speech' >/dev/null 2>&1 || { echo "❌ Missing speech key"; exit 1; }

echo "✅ Structured output is valid JSON with speech key"

