#!/usr/bin/env bash

# Reusable Claude Agent Runner Library
# Source this file and call run_claude_agent() with config

set -euo pipefail

################################################################################
# REQUIREMENTS FROM USER (2025-10-31):
################################################################################
#
# 1. ✅ AFTER main agent loop (up to 10 iterations), run CODE REVIEW CYCLE
#    Status: Implemented - review cycle runs after main loop completes
#
# 2. CODE REVIEW CYCLE (max 5 iterations by default, configurable):
#    - Step 1: ✅ Generate review prompt
#      * ✅ Use template from .claude/agents/code-quality-reviewer.md
#      * ✅ Include original prompt given to first Claude
#      * ✅ Save original prompt to variable for reuse
#
#    - Step 2: ✅ Run Claude to perform review
#      * ✅ Use review prompt from Step 1
#      * ✅ Output to file (like main loop does)
#      * ✅ Use reusable run_claude() function
#
#    - Step 3: ✅ Generate structured output from review using Haiku
#      * ✅ Extract into reusable generate_structured_output() function
#      * ✅ Keep existing speech functionality - uses generate_speech_summary()
#      * ✅ Allow passing additional JSON keys to merge
#      * ✅ Use proper JSON merge (jq)
#      * ✅ Output structure for code review includes required fields
#
#    - Step 4: ✅ If critical fixes needed, run Claude to apply fixes
#      * ✅ Provide full context from review output file
#      * ✅ Each critical fix gets separate Claude command
#      * ✅ Run lint after all fixes
#      * ✅ Run typecheck after lint
#      * ✅ Fix lint errors if lint fails
#      * ✅ Fix type errors if typecheck fails
#
#    - Step 5: ✅ Loop back to Step 1 for re-review
#      * ✅ Max 5 review iterations (configurable)
#      * ✅ Stop when no critical fixes or max reached
#
# 3. REFACTORING REQUIREMENTS:
#    - ✅ Extract run_claude() - reusable function to run Claude and save output
#    - ✅ Extract generate_structured_output() - reusable Haiku function
#      * ✅ Must preserve exact existing functionality
#      * ✅ Must allow passing additional JSON keys
#      * ✅ Must merge into single valid JSON object
#    - ✅ Preserve ALL existing functionality in main loop
#    - ✅ Use proper bash syntax, test for validity
#    - ✅ Make functions composable and reusable
#
# 4. ✅ UPDATE library-cleanup/run-agent.sh:
#    - ✅ Add code review as command-line argument (uses --enable-code-review)
#    - ✅ Make it flow through automatically
#
# 5. ✅ RATE LIMITING:
#    - ✅ Add 15-second sleep between main loop iterations (line 624)
#    - ✅ Add 15-second sleep between review iterations (line 475)
#
# 6. ✅ WORKING DIRECTORY:
#    - ✅ All Claude commands run from project root (cd in lines 241, 273)
#
################################################################################

# Source reusable Claude functions
# Use SHARED_SCRIPT_DIR to avoid overriding calling script's SCRIPT_DIR
SHARED_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SHARED_SCRIPT_DIR/claude-functions.sh"

# Configuration defaults (can be overridden by command-line arguments)
ENABLE_SPEECH="${ENABLE_SPEECH:-false}"
ENABLE_CODE_REVIEW="${ENABLE_CODE_REVIEW:-false}"
MAX_CODE_REVIEWS="${MAX_CODE_REVIEWS:-5}"
RATE_LIMIT_SECONDS="${RATE_LIMIT_SECONDS:-15}"

# Speak text using macOS say command (synchronous - waits for speech to finish)
speak() {
  if [[ "$ENABLE_SPEECH" == "true" ]]; then
    say "$1"
  fi
}

# Generate speech summary from iteration output using Claude Haiku
generate_speech_summary() {
  local OUTPUT_FILE="$1"
  local ITERATION="$2"

  if [[ ! "$ENABLE_SPEECH" == "true" ]]; then
    return
  fi

  # Use Claude Haiku to generate concise speech summary
  local SUMMARY=$(claude \
    --print \
    --model haiku \
    --dangerously-skip-permissions \
    "Read this agent iteration output and create a 1-sentence progress update to speak out loud (max 15 words):

$(cat "$OUTPUT_FILE")

Respond with ONLY the sentence to speak, nothing else." || echo "Iteration $ITERATION complete")

  echo "   📢 Summary: $SUMMARY"
  speak "$SUMMARY"
}

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
    generate_speech_summary "$REVIEW_OUTPUT" "$review_num"

    # Step 3b: Generate structured JSON output separately
    local ADDITIONAL_JSON='{
      "score": 0,
      "critical_fixes": [],
      "suggestions": [],
      "summary": "",
      "review_output_path": "'"$REVIEW_OUTPUT"'"
    }'

    echo "   🔄 Extracting structured review data..."
    local REVIEW_JSON=$(generate_structured_output "$REVIEW_OUTPUT" "$ADDITIONAL_JSON")
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
      speak "Code review passed with score $SCORE out of 10"
      return 0
    fi

    if [[ $review_num -eq $MAX_REVIEWS ]]; then
      echo ""
      echo "   ⚠️  Reached max reviews with $CRITICAL_COUNT issues remaining"
      speak "Reached maximum reviews with $CRITICAL_COUNT issues remaining"
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
      echo "   ⏳ Rate limiting: Waiting $RATE_LIMIT_SECONDS seconds before re-review..."
      sleep "$RATE_LIMIT_SECONDS"
    fi

    echo "   ✅ Fixes applied, re-reviewing..."
    echo ""
  done
}

# Run Claude agent in loop
# Usage: run_claude_agent PROMPT_FILE HANDOFF_FILE OUTPUT_DIR MAX_ITERATIONS [--enable-code-review] [--max-reviews N] [--enable-speech]
run_claude_agent() {
  local PROMPT_FILE="$1"
  local HANDOFF_FILE="$2"
  local OUTPUT_DIR="$3"
  local MAX_ITERATIONS="${4:-10}"
  shift 4 || true

  # Parse optional command-line flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --enable-code-review)
        ENABLE_CODE_REVIEW=true
        shift
        ;;
      --max-reviews)
        MAX_CODE_REVIEWS="$2"
        shift 2
        ;;
      --enable-speech)
        ENABLE_SPEECH=true
        shift
        ;;
      --rate-limit)
        RATE_LIMIT_SECONDS="$2"
        shift 2
        ;;
      *)
        echo "⚠️  Unknown option: $1"
        shift
        ;;
    esac
  done

  local TIMESTAMP=$(date +%Y%m%d_%H%M%S)

  # PROJECT_DIR should be set by calling script (repo root)
  # If not set, try to determine it from git root
  if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  fi

  # Validate inputs
  if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "❌ Error: Prompt file not found: $PROMPT_FILE"
    return 1
  fi

  # Create output directory
  mkdir -p "$OUTPUT_DIR"

  echo "🤖 Starting Claude Autonomous Agent"
  echo "📝 Prompt: $PROMPT_FILE"
  echo "📄 Handoff: $HANDOFF_FILE"
  echo "📁 Output: $OUTPUT_DIR"
  echo "🔄 Max iterations: $MAX_ITERATIONS"
  if [[ "$ENABLE_SPEECH" == "true" ]]; then
    echo "🔊 Speech enabled"
  fi
  echo ""

  speak "Starting agent with maximum $MAX_ITERATIONS iterations"

  # Read initial prompt
  local CURRENT_PROMPT=$(cat "$PROMPT_FILE")

  # Agent loop
  for i in $(seq 1 $MAX_ITERATIONS); do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Iteration $i of $MAX_ITERATIONS"
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create unique output file
    local OUTPUT_FILE="$OUTPUT_DIR/iteration_${i}_${TIMESTAMP}.log"
    echo "📄 Output: $OUTPUT_FILE"
    echo "📝 Prompt: $(wc -l < "$PROMPT_FILE") lines"
    echo "⚙️  Running Claude..."
    echo ""

    speak "Starting iteration $i"

    # Run Claude in non-interactive mode
    # Use tee to pipe output to both file AND console
    if ! claude \
      --print \
      --dangerously-skip-permissions \
      --output-format text \
      "$CURRENT_PROMPT" \
      2>&1 | tee "$OUTPUT_FILE"; then
      echo ""
      echo "❌ Error: Claude failed"
      echo "📄 Check: $OUTPUT_FILE"
      return 1
    fi

    echo ""
    echo "✅ Iteration $i complete"
    echo "📄 Saved: $OUTPUT_FILE"
    echo "📊 Output size: $(wc -c < "$OUTPUT_FILE") bytes"
    echo ""

    # Generate and speak AI summary of iteration
    echo "🔊 Generating speech summary..."
    generate_speech_summary "$OUTPUT_FILE" "$i"

    # Check for completion
    if [[ -f "$HANDOFF_FILE" ]]; then
      echo "📋 Checking handoff..."

      if grep -q "Session End" "$HANDOFF_FILE" 2>/dev/null; then
        echo "   ✅ Found 'Session End' marker"

        # Check if complete
        if grep -q "Status.*complete" "$HANDOFF_FILE" 2>/dev/null; then
          echo "   🎉 Status: complete"
          echo "🛑 Stopping - task complete!"
          speak "Task complete! Stopping agent."
          break
        else
          echo "   🔄 Status: not complete, continuing..."
          speak "Continuing to iteration $(($i + 1))"
        fi

        # Continue with handoff context
        CURRENT_PROMPT=$(generate_continuation_prompt "$i" "$HANDOFF_FILE")
        echo "   📝 Generated continuation prompt"
      else
        echo "   ⚠️  No 'Session End' marker found"
        echo "🛑 Stopping - no session end"
        break
      fi
    else
      echo "⚠️  No handoff file: $HANDOFF_FILE"
      echo "🛑 Stopping - no handoff"
      break
    fi

    echo ""
    # Rate limiting between main loop iterations
    if [[ $i -lt $MAX_ITERATIONS ]]; then
      echo "⏳ Rate limiting: Waiting $RATE_LIMIT_SECONDS seconds before next iteration..."
      sleep "$RATE_LIMIT_SECONDS"
    fi
  done

  # Summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📊 Agent Run Summary"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  if [[ $i -eq $MAX_ITERATIONS ]]; then
    echo "⚠️  Status: Reached max iterations ($MAX_ITERATIONS)"
    speak "Agent stopped. Reached maximum $MAX_ITERATIONS iterations."
  else
    echo "✅ Status: Completed in $i iteration(s)"
    speak "Agent finished successfully in $i iterations."
  fi
  echo "⏰ Finished: $(date '+%Y-%m-%d %H:%M:%S')"
  echo ""
  echo "📄 Final handoff: $HANDOFF_FILE"
  if [[ -f "$HANDOFF_FILE" ]]; then
    echo "   Size: $(wc -c < "$HANDOFF_FILE") bytes"
    echo "   Lines: $(wc -l < "$HANDOFF_FILE") lines"
  fi
  echo ""
  echo "📁 All outputs: $OUTPUT_DIR"
  echo "   Total files: $(ls -1 "$OUTPUT_DIR" 2>/dev/null | wc -l)"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Run code review cycle if enabled
  if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
    echo ""
    echo "🔍 Code review enabled, starting review cycle..."

    # Save initial prompt for review context
    local INITIAL_PROMPT=$(cat "$PROMPT_FILE")

    if run_code_review_cycle "$INITIAL_PROMPT" "$OUTPUT_DIR" "$MAX_CODE_REVIEWS" "$PROJECT_DIR"; then
      echo "✅ Code review approved"
      speak "Code review cycle completed successfully"
    else
      echo "⚠️  Code review found unresolved issues"
      speak "Code review cycle completed with issues"
    fi
  fi
}

# Generate continuation prompt from handoff
generate_continuation_prompt() {
  local ITERATION="$1"
  local HANDOFF_FILE="$2"

  cat <<EOF
# Continuation from Iteration $ITERATION

Read the handoff at \`$HANDOFF_FILE\` for full context.

## Your Task
Continue where previous agent left off:
1. Read handoff for status and findings
2. Follow investigation steps or alternative approaches
3. Test incrementally after each change
4. Update handoff with discoveries
5. Mark complete when done

## Critical
- Test after EACH change
- Document all findings
- Ask questions if uncertain
- Keep changes minimal

Read handoff now and continue.
EOF
}

# Quick test function
test_agent() {
  local TEST_DIR="$1"
  local MAX_ITERATIONS="${2:-2}"

  mkdir -p "$TEST_DIR"

  # Create simple test prompt
  cat > "$TEST_DIR/prompt.md" <<'EOF'
# Simple Test Task

Create a test file at `test-output/hello.txt` with content "Hello from agent iteration".

After creating the file:
1. Verify it exists
2. Read its contents
3. Write handoff to `test-output/HANDOFF.md` with "Session End" and "Status: complete"

That's it. Simple task to test agent loop.
EOF

  # Run agent
  run_claude_agent \
    "$TEST_DIR/prompt.md" \
    "$TEST_DIR/HANDOFF.md" \
    "$TEST_DIR/runs" \
    "$MAX_ITERATIONS"
}
