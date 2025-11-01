#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_DIR/lib/agent-runner.sh"

TMP_DIR=$(mktemp -d)
echo "Using temp test dir: $TMP_DIR"

test_agent "$TMP_DIR" 2

RUN_DIR=$(ls -dt "$TMP_DIR/runs"/* 2>/dev/null | head -1 || true)

if [[ -z "${RUN_DIR:-}" ]]; then
  echo "❌ No run directory created"
  exit 1
fi

echo "✅ Found run dir: $RUN_DIR"
ls -l "$RUN_DIR" || true

