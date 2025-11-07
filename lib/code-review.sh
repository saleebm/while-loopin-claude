#!/usr/bin/env bash

# Code review helpers extracted from agent-runner.sh
# Requires: claude-functions.sh to be sourced (run_claude, generate_structured_review_json)

set -euo pipefail

################################################################################
# Helper Functions for Code Review
################################################################################

# Generate review prompt from original prompt and agent output
generate_review_prompt() {
  local ORIGINAL_PROMPT="$1"
  local OUTPUT_DIR="$2"
  local PROJECT_DIR="$3"

  # Find latest agent output
  local LATEST_OUTPUT=$(ls -t "$OUTPUT_DIR"/iteration_*.log 2>/dev/null | head -1)

  # Load code quality reviewer template
  local TEMPLATE_PATH="$PROJECT_DIR/.claude/agents/code-quality-reviewer.md"
  local TEMPLATE_CONTENT=""

  if [[ -f "$TEMPLATE_PATH" ]]; then
    # Extract content after the frontmatter (after the second ---)
    TEMPLATE_CONTENT=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$TEMPLATE_PATH" | tail -n +2)
  else
    echo "⚠️  Warning: Template not found at $TEMPLATE_PATH, using inline template" >&2
    TEMPLATE_CONTENT="Review the code for quality, maintainability, and best practices."
  fi

  cat <<EOF
$TEMPLATE_CONTENT

# Original Task Given to Agent
$ORIGINAL_PROMPT

# Agent Output to Review
$(cat "$LATEST_OUTPUT" 2>/dev/null || echo "No output found")

# Required Output Format
After your detailed analysis, provide a JSON structure at the end:
{
  "score": 8,
  "critical_fixes": ["issue 1", "issue 2"],
  "suggestions": ["suggestion 1"],
  "summary": "2-3 sentence overview"
}
EOF
}

# Generate fix prompt from review JSON
generate_fix_prompt() {
  local REVIEW_JSON="$1"

  local CRITICAL_FIXES=$(echo "$REVIEW_JSON" | jq -r '.critical_fixes | join("\n- ")')
  local REVIEW_PATH=$(echo "$REVIEW_JSON" | jq -r '.review_output_path')
  local SUMMARY=$(echo "$REVIEW_JSON" | jq -r '.summary')

  cat <<EOF
# Apply Critical Fixes

## Review Summary
$SUMMARY

## Full Review Analysis
$(cat "$REVIEW_PATH" 2>/dev/null || echo "Review file not found")

## Critical Fixes Needed
- $CRITICAL_FIXES

## Your Task
Apply these critical fixes to the code. Be surgical - fix ONLY the issues listed.

After applying fixes:
1. Verify the code still works
2. Update any relevant documentation
3. Provide summary of changes made
EOF
}

################################################################################
# Process Critical Fixes - Apply each fix individually
################################################################################

# Process each critical fix from review with separate Claude commands
# Usage: process_critical_fixes REVIEW_JSON REVIEW_DIR REVIEW_NUM PROJECT_DIR
process_critical_fixes() {
  local REVIEW_JSON="$1"
  local REVIEW_DIR="$2"
  local REVIEW_NUM="$3"
  local PROJECT_DIR="$4"

  # Extract critical fixes array
  local CRITICAL_FIXES=$(echo "$REVIEW_JSON" | jq -r '.critical_fixes[]' 2>/dev/null)
  local FIX_COUNT=$(echo "$REVIEW_JSON" | jq '.critical_fixes | length')

  if [[ "$FIX_COUNT" -eq 0 ]]; then
    echo "      ℹ️  No critical fixes needed"
    return 0
  fi

  local fix_num=1
  while IFS= read -r fix; do
    echo ""
    echo "      🔧 Fix $fix_num of $FIX_COUNT: $fix"

    # Generate fix prompt for this specific issue
    local FIX_PROMPT
    read -r -d '' FIX_PROMPT <<'EOF_FIX' || true
# Apply Critical Fix

## Issue to Fix
FIX_ISSUE_HERE

## Context
This issue was identified during code review. Apply ONLY this specific fix.

## Requirements
1. Fix the issue mentioned above
2. Ensure fix doesn't break existing functionality
3. Follow project coding standards
4. Be surgical - minimal changes

## Working Directory
PROJECT_DIR_HERE

Please apply the fix now.
EOF_FIX

    # Substitute variables
    FIX_PROMPT="${FIX_PROMPT//FIX_ISSUE_HERE/$fix}"
    FIX_PROMPT="${FIX_PROMPT//PROJECT_DIR_HERE/$PROJECT_DIR}"

    # Run Claude to apply this specific fix
    local FIX_OUTPUT="$REVIEW_DIR/fix_${REVIEW_NUM}_${fix_num}.log"

    # Change to project directory before running Claude
    cd "$PROJECT_DIR" || return 1

    if ! run_claude "$FIX_PROMPT" "$FIX_OUTPUT" "sonnet"; then
      echo "      ❌ Failed to apply fix $fix_num"
      return 1
    fi

    echo "      ✅ Fix $fix_num applied"

    # Rate limiting between fix commands
    if [[ $fix_num -lt $FIX_COUNT ]]; then
      sleep 2
    fi

    ((fix_num++))
  done <<< "$CRITICAL_FIXES"

  return 0
}

################################################################################
# Run Lint and Typecheck - Validate code quality
################################################################################

# Run lint and typecheck, fix issues if found
# Usage: run_lint_and_typecheck REVIEW_DIR REVIEW_NUM PROJECT_DIR
run_lint_and_typecheck() {
  local REVIEW_DIR="$1"
  local REVIEW_NUM="$2"
  local PROJECT_DIR="$3"

  # Change to project directory
  cd "$PROJECT_DIR" || return 1

  local lint_failed=false
  local typecheck_failed=false

  # Run lint
  echo "      📋 Running lint..."
  if ! bun run lint > "$REVIEW_DIR/lint_${REVIEW_NUM}.log" 2>&1; then
    lint_failed=true
    echo "      ⚠️  Lint found issues"

    # Run Claude to fix lint issues
    echo "      🔧 Applying lint fixes..."
    local LINT_OUTPUT
    LINT_OUTPUT=$(cat "$REVIEW_DIR/lint_${REVIEW_NUM}.log")

    local LINT_FIX_PROMPT
    read -r -d '' LINT_FIX_PROMPT <<'EOF_LINT' || true
# Fix Linting Issues

## Lint Output
LINT_OUTPUT_HERE

## Your Task
Fix all linting issues shown above. Follow project linting standards.

## Working Directory
You are in: PROJECT_DIR_HERE

Please fix the linting issues now.
EOF_LINT

    # Substitute variables
    LINT_FIX_PROMPT="${LINT_FIX_PROMPT//LINT_OUTPUT_HERE/$LINT_OUTPUT}"
    LINT_FIX_PROMPT="${LINT_FIX_PROMPT//PROJECT_DIR_HERE/$PROJECT_DIR}"

    if ! run_claude "$LINT_FIX_PROMPT" "$REVIEW_DIR/lint_fix_${REVIEW_NUM}.log" "sonnet"; then
      echo "      ❌ Failed to fix lint issues"
      return 1
    fi

    echo "      ✅ Lint fixes applied"

    # Re-run lint to verify
    if bun run lint > "$REVIEW_DIR/lint_recheck_${REVIEW_NUM}.log" 2>&1; then
      echo "      ✅ Lint now passes"
      lint_failed=false
    fi
  else
    echo "      ✅ Lint passed"
  fi

  # Run typecheck
  echo "      📋 Running typecheck..."
  if ! bun run typecheck > "$REVIEW_DIR/typecheck_${REVIEW_NUM}.log" 2>&1; then
    typecheck_failed=true
    echo "      ⚠️  Typecheck found issues"

    # Run Claude to fix type issues
    echo "      🔧 Applying typecheck fixes..."
    local TYPE_OUTPUT
    TYPE_OUTPUT=$(cat "$REVIEW_DIR/typecheck_${REVIEW_NUM}.log")

    local TYPE_FIX_PROMPT
    read -r -d '' TYPE_FIX_PROMPT <<'EOF_TYPE' || true
# Fix Type Errors

## Typecheck Output
TYPE_OUTPUT_HERE

## Your Task
Fix all type errors shown above. Ensure type safety throughout.

## Working Directory
You are in: PROJECT_DIR_HERE

Please fix the type errors now.
EOF_TYPE

    # Substitute variables
    TYPE_FIX_PROMPT="${TYPE_FIX_PROMPT//TYPE_OUTPUT_HERE/$TYPE_OUTPUT}"
    TYPE_FIX_PROMPT="${TYPE_FIX_PROMPT//PROJECT_DIR_HERE/$PROJECT_DIR}"

    if ! run_claude "$TYPE_FIX_PROMPT" "$REVIEW_DIR/type_fix_${REVIEW_NUM}.log" "sonnet"; then
      echo "      ❌ Failed to fix type issues"
      return 1
    fi

    echo "      ✅ Type fixes applied"

    # Re-run typecheck to verify
    if bun run typecheck > "$REVIEW_DIR/typecheck_recheck_${REVIEW_NUM}.log" 2>&1; then
      echo "      ✅ Typecheck now passes"
      typecheck_failed=false
    fi
  else
    echo "      ✅ Typecheck passed"
  fi

  # Return success only if both pass
  if [[ "$lint_failed" == "false" ]] && [[ "$typecheck_failed" == "false" ]]; then
    return 0
  else
    return 1
  fi
}

################################################################################
# Code Review Cycle Function
################################################################################

# Run code review cycle until quality threshold met or max reviews reached
# Usage: run_code_review_cycle ORIGINAL_PROMPT AGENT_OUTPUT_DIR MAX_REVIEWS PROJECT_DIR
run_code_review_cycle() {
  local ORIGINAL_PROMPT="$1"
  local AGENT_OUTPUT_DIR="$2"
  local MAX_REVIEWS="${3:-5}"
  local PROJECT_DIR="$4"
  local REVIEW_DIR="$AGENT_OUTPUT_DIR/reviews"

  mkdir -p "$REVIEW_DIR"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🔍 Starting Code Review Cycle (max $MAX_REVIEWS reviews)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  for review_num in $(seq 1 $MAX_REVIEWS); do
    echo "🔍 Review Iteration $review_num of $MAX_REVIEWS"
    echo ""

    # Step 1: Generate review prompt
    local REVIEW_PROMPT=$(generate_review_prompt "$ORIGINAL_PROMPT" "$AGENT_OUTPUT_DIR" "$PROJECT_DIR")

    # Step 2: Run code review
    local REVIEW_OUTPUT="$REVIEW_DIR/review_${review_num}.log"
    echo "   📝 Running code review..."
    if ! run_claude "$REVIEW_PROMPT" "$REVIEW_OUTPUT" "sonnet"; then
      echo "   ❌ Review failed"
      return 1
    fi

    # Step 3a: Generate speech summary (like main loop does)
    echo ""
    echo "   🔊 Generating speech summary..."
    if type -t generate_speech_summary >/dev/null 2>&1; then
      generate_speech_summary "$REVIEW_OUTPUT" "$review_num"
    fi

    # Step 3b: Generate structured JSON output
    echo "   🔄 Extracting structured review data..."
    local REVIEW_JSON=$(generate_structured_review_json "$REVIEW_OUTPUT" '{}' "$PROJECT_DIR")
    
    # Add review_output_path to JSON
    REVIEW_JSON=$(echo "$REVIEW_JSON" | jq --arg path "$REVIEW_OUTPUT" '. + {review_output_path: $path}')
    
    echo "$REVIEW_JSON" > "$REVIEW_DIR/review_${review_num}.json"

    # Step 4: Check for critical fixes
    local CRITICAL_COUNT=$(echo "$REVIEW_JSON" | jq '.critical_fixes | length')
    local SCORE=$(echo "$REVIEW_JSON" | jq '.score')

    echo "   📊 Score: $SCORE/10"
    echo "   🔧 Critical fixes needed: $CRITICAL_COUNT"

    if [[ "$CRITICAL_COUNT" -eq 0 ]] && [[ "$SCORE" -ge 8 ]]; then
      echo ""
      echo "   ✅ Code review passed! Score: $SCORE/10"
      echo "🛑 Review cycle complete"
      if type -t speak >/dev/null 2>&1; then
        speak "Code review passed with score $SCORE out of 10"
      fi
      return 0
    fi

    if [[ $review_num -eq $MAX_REVIEWS ]]; then
      echo ""
      echo "   ⚠️  Reached max reviews with $CRITICAL_COUNT issues remaining"
      if type -t speak >/dev/null 2>&1; then
        speak "Reached maximum reviews with $CRITICAL_COUNT issues remaining"
      fi
      return 1
    fi

    # Step 5: Process each critical fix individually
    echo ""
    echo "   🔧 Processing $CRITICAL_COUNT critical fixes..."
    if ! process_critical_fixes "$REVIEW_JSON" "$REVIEW_DIR" "$review_num" "$PROJECT_DIR"; then
      echo "   ❌ Critical fix processing failed"
      return 1
    fi

    # Step 6: Run lint and typecheck
    echo ""
    echo "   🧪 Running lint and typecheck..."
    if ! run_lint_and_typecheck "$REVIEW_DIR" "$review_num" "$PROJECT_DIR"; then
      echo "   ⚠️  Lint/typecheck found issues (will re-review)"
    fi

    # Rate limiting between review iterations
    if [[ $review_num -lt $MAX_REVIEWS ]]; then
      echo ""
      echo "   ⏳ Rate limiting: Waiting ${RATE_LIMIT_SECONDS:-15} seconds before re-review..."
      sleep "${RATE_LIMIT_SECONDS:-15}"
    fi

    echo "   ✅ Fixes applied, re-reviewing..."
    echo ""
  done
}


