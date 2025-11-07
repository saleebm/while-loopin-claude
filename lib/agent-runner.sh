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
#      * ✅ Extract into dedicated Bun script using AI SDK generateObject
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
#    - ✅ Extract structured output to Bun script using AI SDK generateObject
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
source "$SHARED_SCRIPT_DIR/handoff-functions.sh"
source "$SHARED_SCRIPT_DIR/code-review.sh"
source "$SHARED_SCRIPT_DIR/context-functions.sh"

# Configuration defaults (can be overridden by command-line arguments)
ENABLE_SPEECH="${ENABLE_SPEECH:-false}"
ENABLE_CODE_REVIEW="${ENABLE_CODE_REVIEW:-false}"
MAX_CODE_REVIEWS="${MAX_CODE_REVIEWS:-5}"
RATE_LIMIT_SECONDS="${RATE_LIMIT_SECONDS:-15}"
HANDOFF_MODE="${HANDOFF_MODE:-auto}"
HANDOFF_TEMPLATE="${HANDOFF_TEMPLATE:-}"

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

# Code review helpers moved to lib/code-review.sh (sourced above)

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

    # Step 3b: Generate structured JSON output
    echo "   🔄 Extracting structured review data..."
    local REVIEW_JSON=$(generate_structured_review_json "$REVIEW_OUTPUT" '{}' "$PROJECT_DIR")
    
    # Add review_output_path to JSON
    REVIEW_JSON=$(echo "$REVIEW_JSON" | jq --arg path "$REVIEW_OUTPUT" '. + {review_output_path: $path}')
    
    echo "$REVIEW_JSON" > "$REVIEW_DIR/review_${review_num}.json"

    # Step 4: Check for critical fixes
    local CRITICAL_COUNT=$(echo "$REVIEW_JSON" | jq -r '.critical_fixes | length // 999')
    local SCORE=$(echo "$REVIEW_JSON" | jq -r '.score // 0')

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

################################################################################
# detect_resume_state() - Find last completed iteration for resume
################################################################################
# Usage: detect_resume_state OUTPUT_DIR
# Returns: JSON with last_iteration, run_dir, and handoff_file
################################################################################
detect_resume_state() {
  local OUTPUT_DIR="$1"
  
  # Find the most recent run directory
  local LATEST_RUN=$(ls -dt "$OUTPUT_DIR"/*-* 2>/dev/null | head -1)
  
  if [[ -z "$LATEST_RUN" || ! -d "$LATEST_RUN" ]]; then
    echo '{"last_iteration": 0, "run_dir": "", "handoff_file": ""}'
    return 0
  fi
  
  # Find the highest iteration number
  local MAX_ITER=0
  for logfile in "$LATEST_RUN"/iteration_*.log; do
    if [[ -f "$logfile" ]]; then
      local iter_num=$(basename "$logfile" | sed 's/iteration_\([0-9]*\)\.log/\1/')
      if [[ "$iter_num" =~ ^[0-9]+$ ]] && [[ "$iter_num" -gt "$MAX_ITER" ]]; then
        MAX_ITER="$iter_num"
      fi
    fi
  done
  
  # Look for handoff file in the parent directory (typical location)
  local PARENT_DIR=$(dirname "$OUTPUT_DIR")
  local HANDOFF_FILE=""
  if [[ -f "$PARENT_DIR/HANDOFF.md" ]]; then
    HANDOFF_FILE="$PARENT_DIR/HANDOFF.md"
  fi
  
  echo "{\"last_iteration\": $MAX_ITER, \"run_dir\": \"$LATEST_RUN\", \"handoff_file\": \"$HANDOFF_FILE\"}"
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
      --handoff)
        HANDOFF_MODE="$2"
        shift 2
        ;;
      --handoff-template)
        HANDOFF_TEMPLATE="$2"
        shift 2
        ;;
      *)
        echo "⚠️  Unknown option: $1"
        shift
        ;;
    esac
  done

  local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  local RUN_ID="${TIMESTAMP}-$$"

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

  # Create output directory (base and per-run)
  mkdir -p "$OUTPUT_DIR"
  
  # Check for resume mode
  local START_ITERATION=1
  local RESUME_MODE=false
  local RESUME_CONTEXT=""
  
  if [[ "${RESUME_AGENT:-false}" == "true" ]]; then
    echo "🔄 Resume mode enabled, checking for previous run..."
    local RESUME_STATE=$(detect_resume_state "$OUTPUT_DIR")
    local LAST_ITER=$(echo "$RESUME_STATE" | jq -r '.last_iteration')
    local LAST_RUN_DIR=$(echo "$RESUME_STATE" | jq -r '.run_dir')
    local LAST_HANDOFF=$(echo "$RESUME_STATE" | jq -r '.handoff_file')
    
    if [[ "$LAST_ITER" -gt 0 ]] && [[ -d "$LAST_RUN_DIR" ]]; then
      RESUME_MODE=true
      START_ITERATION=$((LAST_ITER + 1))
      RUN_OUTPUT_DIR="$LAST_RUN_DIR"
      
      echo "   ✅ Found previous run: iteration $LAST_ITER"
      echo "   📁 Resuming in: $RUN_OUTPUT_DIR"
      echo "   🔢 Starting from iteration: $START_ITERATION"
      
      # Load last iteration output for context
      local LAST_OUTPUT="$RUN_OUTPUT_DIR/iteration_${LAST_ITER}.log"
      if [[ -f "$LAST_OUTPUT" ]]; then
        RESUME_CONTEXT="
## Resuming from Previous Session

Last completed iteration: $LAST_ITER
Previous output summary:
\`\`\`
$(tail -100 "$LAST_OUTPUT")
\`\`\`
"
        echo "   📄 Loaded context from iteration $LAST_ITER"
      fi
      
      # Override handoff file if found
      if [[ -n "$LAST_HANDOFF" ]] && [[ -f "$LAST_HANDOFF" ]]; then
        HANDOFF_FILE="$LAST_HANDOFF"
        echo "   📋 Using existing handoff: $HANDOFF_FILE"
      fi
    else
      echo "   ℹ️  No previous run found, starting fresh"
      RESUME_MODE=false
      START_ITERATION=1
      RUN_OUTPUT_DIR="$OUTPUT_DIR/$RUN_ID"
      mkdir -p "$RUN_OUTPUT_DIR"
    fi
  else
    RUN_OUTPUT_DIR="$OUTPUT_DIR/$RUN_ID"
    mkdir -p "$RUN_OUTPUT_DIR"
  fi

  # Initialize context files for this agent run
  # Derive FEATURE_DIR from PROMPT_FILE or HANDOFF_FILE (both in .specs/{feature}/)
  local FEATURE_DIR
  if [[ "$PROMPT_FILE" == *.specs/* ]]; then
    # Extract feature directory from prompt file path
    FEATURE_DIR=$(dirname "$PROMPT_FILE")
  elif [[ "$HANDOFF_FILE" == *.specs/* ]]; then
    # Fallback to handoff file path
    FEATURE_DIR=$(dirname "$HANDOFF_FILE")
  else
    # Fallback to project-wide context if not in .specs structure
    FEATURE_DIR="$PROJECT_DIR"
  fi

  local CONTEXT_DIR="$FEATURE_DIR/context"
  if ! ensure_context_files "$CONTEXT_DIR"; then
    echo "❌ Error: Failed to initialize context files"
    echo "   Context directory: $CONTEXT_DIR"
    echo "   Please check directory permissions and try again"
    return 1
  fi

  echo "🤖 Starting Claude Autonomous Agent"
  echo "📝 Prompt: $PROMPT_FILE"
  echo "📄 Handoff: $HANDOFF_FILE"
  echo "📁 Output (run): $RUN_OUTPUT_DIR"
  echo "🔄 Max iterations: $MAX_ITERATIONS"
  if [[ "$ENABLE_SPEECH" == "true" ]]; then
    echo "🔊 Speech enabled"
  fi
  echo ""

  speak "Starting agent with maximum $MAX_ITERATIONS iterations"

  # Read initial prompt and append context file requirements
  local CONTEXT_INSTRUCTIONS='

## Context File Requirements
You MUST maintain the following context files in the `context/` directory:
- `context/instructions.md` - Complete instructions for your current phase
- `context/progress.md` - Progress tracking with measurable milestones
- `context/findings.md` - Discoveries, insights, and thought processes
- `context/achievements.md` - Recent achievements with validation proof

Update these files after each significant action or discovery.
'
  local CURRENT_PROMPT=$(cat "$PROMPT_FILE")
  CURRENT_PROMPT="${CURRENT_PROMPT}${CONTEXT_INSTRUCTIONS}"
  
  # Add resume context if resuming
  if [[ "$RESUME_MODE" == "true" ]] && [[ -n "$RESUME_CONTEXT" ]]; then
    CURRENT_PROMPT="${CURRENT_PROMPT}${RESUME_CONTEXT}"
  fi

  # Agent loop
  for i in $(seq $START_ITERATION $MAX_ITERATIONS); do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Iteration $i of $MAX_ITERATIONS"
    echo "⏰ $(date '+%Y-%m-%d %H:%M:%S')"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Create unique output file in run subdir
    local OUTPUT_FILE="$RUN_OUTPUT_DIR/iteration_${i}.log"
    echo "📄 Output: $OUTPUT_FILE"
    echo "📝 Prompt: $(wc -l < "$PROMPT_FILE") lines"
    echo "⚙️  Running Claude..."
    echo ""

    speak "Starting iteration $i"

    # Run Claude in non-interactive mode via helper (tee handled inside)
    if ! run_claude "$CURRENT_PROMPT" "$OUTPUT_FILE" "sonnet"; then
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

    # Validate context files compliance
    echo "🔍 Validating context files..."
    if ! ensure_context_files "$CONTEXT_DIR"; then
      echo "   ❌ Error: Failed to ensure context files exist"
      echo "   Context directory: $CONTEXT_DIR"
      echo "   Attempting recovery..."

      # Attempt recovery by creating directory and retrying
      if ! mkdir -p "$CONTEXT_DIR" || ! ensure_context_files "$CONTEXT_DIR"; then
        echo "   ❌ Recovery failed - stopping agent"
        return 1
      fi
      echo "   ✅ Recovery successful"
    fi

    if check_context_files_updated "$CONTEXT_DIR"; then
      echo "   ✅ Context files updated"
    else
      echo "   ⚠️  Context files need attention"
    fi
    echo ""

    # Generate and speak AI summary of iteration
    echo "🔊 Generating speech summary..."
    generate_speech_summary "$OUTPUT_FILE" "$i"

    # Auto-generate/update handoff for next iteration if enabled
    local DEFAULT_HANDOFF_TEMPLATE=""
    if [[ -z "$HANDOFF_TEMPLATE" ]]; then
      # Prefer repo-level template if present
      if [[ -n "$PROJECT_DIR" && -f "$PROJECT_DIR/templates/handoff-system-prompt.md" ]]; then
        DEFAULT_HANDOFF_TEMPLATE="$PROJECT_DIR/templates/handoff-system-prompt.md"
      fi
    fi
    ensure_handoff \
      "$OUTPUT_FILE" \
      "$HANDOFF_FILE" \
      "$PROJECT_DIR" \
      "$i" \
      "$RUN_OUTPUT_DIR" \
      "${HANDOFF_MODE}" \
      "${HANDOFF_TEMPLATE:-$DEFAULT_HANDOFF_TEMPLATE}"

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
  echo "📁 Run outputs: $RUN_OUTPUT_DIR"
  echo "   Total files: $(ls -1 "$RUN_OUTPUT_DIR" 2>/dev/null | wc -l)"
  echo ""
  echo "📋 Context files:"
  get_context_summary "$CONTEXT_DIR" | sed 's/^/   /'
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Run code review cycle if enabled
  if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
    echo ""
    echo "🔍 Code review enabled, starting review cycle..."

    # Save initial prompt for review context
    local INITIAL_PROMPT=$(cat "$PROMPT_FILE")

    if run_code_review_cycle "$INITIAL_PROMPT" "$RUN_OUTPUT_DIR" "$MAX_CODE_REVIEWS" "$PROJECT_DIR"; then
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

## Context File Requirements
You MUST maintain the following context files in the \`context/\` directory:
- \`context/instructions.md\` - Complete instructions for your current phase
- \`context/progress.md\` - Progress tracking with measurable milestones
- \`context/findings.md\` - Discoveries, insights, and thought processes
- \`context/achievements.md\` - Recent achievements with validation proof

Update these files after each significant action or discovery.

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
