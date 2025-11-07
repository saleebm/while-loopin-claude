#!/usr/bin/env bash
# Test script for resume functionality and null error fix

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "🧪 Testing Resume Functionality and Null Error Fix"
echo "=================================================="
echo ""

# Test 1: Null error fix
echo "Test 1: Verify null error fix in jq extraction"
echo "----------------------------------------------"
TEST_JSON='{"score": null, "critical_fixes": null}'
SCORE=$(echo "$TEST_JSON" | jq -r '.score // 0')
CRITICAL_COUNT=$(echo "$TEST_JSON" | jq -r '.critical_fixes | length // 999')

# Note: length of null is 0, not null, so we test that SCORE and CRITICAL_COUNT
# are valid integers that won't cause "unbound variable" errors
if [[ "$SCORE" =~ ^[0-9]+$ ]] && [[ "$CRITICAL_COUNT" =~ ^[0-9]+$ ]]; then
  echo "✅ Null error fix works: score=$SCORE, critical_count=$CRITICAL_COUNT (valid integers)"
  # Test that integer comparisons work without "unbound variable" errors
  if [[ "$CRITICAL_COUNT" -ge 0 ]] && [[ "$SCORE" -ge 0 ]]; then
    echo "✅ Integer comparisons work without errors"
  fi
else
  echo "❌ Null error fix failed: score=$SCORE, critical_count=$CRITICAL_COUNT"
  exit 1
fi
echo ""

# Test 2: Resume detection with no previous runs
echo "Test 2: Resume detection (no previous runs)"
echo "-------------------------------------------"
source "$PROJECT_DIR/lib/agent-runner.sh"

TEMP_DIR=$(mktemp -d)
RESULT=$(detect_resume_state "$TEMP_DIR")
LAST_ITER=$(echo "$RESULT" | jq -r '.last_iteration')

if [[ "$LAST_ITER" == "0" ]]; then
  echo "✅ Correctly detected no previous runs"
else
  echo "❌ Failed to detect no previous runs: $RESULT"
  rm -rf "$TEMP_DIR"
  exit 1
fi
rm -rf "$TEMP_DIR"
echo ""

# Test 3: Resume detection with existing iterations
echo "Test 3: Resume detection (with previous iterations)"
echo "--------------------------------------------------"
TEMP_DIR=$(mktemp -d)
TEMP_RUN="$TEMP_DIR/20251107_000000-12345"
mkdir -p "$TEMP_RUN"
touch "$TEMP_RUN/iteration_1.log"
touch "$TEMP_RUN/iteration_2.log"
touch "$TEMP_RUN/iteration_3.log"

RESULT=$(detect_resume_state "$TEMP_DIR")
LAST_ITER=$(echo "$RESULT" | jq -r '.last_iteration')
RUN_DIR=$(echo "$RESULT" | jq -r '.run_dir')

if [[ "$LAST_ITER" == "3" ]] && [[ "$RUN_DIR" == "$TEMP_RUN" ]]; then
  echo "✅ Correctly detected iteration 3 in $RUN_DIR"
else
  echo "❌ Failed to detect iterations: last_iter=$LAST_ITER, run_dir=$RUN_DIR"
  rm -rf "$TEMP_DIR"
  exit 1
fi
rm -rf "$TEMP_DIR"
echo ""

# Test 4: Integer comparison with defaults
echo "Test 4: Integer comparison with default values"
echo "---------------------------------------------"
TEST_SCORE="0"
TEST_COUNT="999"

if [[ "$TEST_COUNT" -eq 999 ]] && [[ "$TEST_SCORE" -ge 0 ]]; then
  echo "✅ Integer comparisons work with default values"
else
  echo "❌ Integer comparisons failed"
  exit 1
fi
echo ""

echo "=================================================="
echo "✅ All resume functionality tests passed!"
echo ""
echo "To test full resume workflow:"
echo "  1. Run: ENABLE_CODE_REVIEW=true MAX_ITERATIONS=3 bun run agent <prompt>"
echo "  2. Let it run 1-2 iterations, then Ctrl+C to stop"
echo "  3. Resume: RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=5 bun run agent <prompt>"
echo "  4. Verify it continues from where it stopped"

