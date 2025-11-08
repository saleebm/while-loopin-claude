#!/usr/bin/env bash

# Master Agent Orchestrator
# Coordinates multi-phase agent execution with planning and context aggregation

set -euo pipefail

# Source required libraries
MASTER_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$MASTER_SCRIPT_DIR/claude-functions.sh"
source "$MASTER_SCRIPT_DIR/context-functions.sh"
source "$MASTER_SCRIPT_DIR/agent-runner.sh"

################################################################################
# run_claude_planning() - Run planning agent to generate phase breakdown
################################################################################
# Usage: run_claude_planning GOAL OUTPUT_FILE FEATURE_DIR
#
# Parameters:
#   GOAL         - High-level goal to break down
#   OUTPUT_FILE  - Where to save planning agent output
#   FEATURE_DIR  - Feature directory for context
#
# Returns: 0 on success, 1 on failure
################################################################################
run_claude_planning() {
  local GOAL="$1"
  local OUTPUT_FILE="$2"
  local FEATURE_DIR="$3"

  echo "🎯 Running planning agent..."
  echo "   Goal: $GOAL"

  # Get project context
  local PROJECT_CONTEXT=""
  if [[ -f "package.json" ]]; then
    PROJECT_CONTEXT+="Package.json exists\n"
    PROJECT_CONTEXT+="Dependencies: $(jq -r '.dependencies | keys | join(", ")' package.json 2>/dev/null || echo 'unknown')\n"
  fi
  if [[ -f "tsconfig.json" ]]; then
    PROJECT_CONTEXT+="TypeScript project\n"
  fi
  if [[ -d "lib" ]]; then
    PROJECT_CONTEXT+="Has lib/ directory\n"
  fi

  # Load planning template
  local TEMPLATE_FILE="$MASTER_SCRIPT_DIR/../templates/planning-agent-prompt.md"
  if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "❌ Error: Planning template not found: $TEMPLATE_FILE"
    return 1
  fi

  local PLANNING_PROMPT=$(cat "$TEMPLATE_FILE")
  PLANNING_PROMPT="${PLANNING_PROMPT//\{USER_GOAL\}/$GOAL}"
  PLANNING_PROMPT="${PLANNING_PROMPT//\{PROJECT_CONTEXT\}/$PROJECT_CONTEXT}"

  # Run Claude to generate phase breakdown
  if ! run_claude "$PLANNING_PROMPT" "$OUTPUT_FILE" "sonnet"; then
    echo "❌ Planning agent failed"
    return 1
  fi

  echo "   ✅ Planning complete"
  return 0
}

################################################################################
# generate_phases_json() - Extract and validate phases JSON from planning output
################################################################################
# Usage: generate_phases_json PLANNING_OUTPUT OUTPUT_JSON
#
# Parameters:
#   PLANNING_OUTPUT - File containing planning agent output
#   OUTPUT_JSON     - Where to save phases.json
#
# Returns: 0 on success, 1 on failure
################################################################################
generate_phases_json() {
  local PLANNING_OUTPUT="$1"
  local OUTPUT_JSON="$2"

  echo "📋 Extracting phase breakdown..."

  # Use Claude Haiku to extract just the JSON from the output
  local EXTRACT_PROMPT="Extract ONLY the JSON object from this planning output. Output nothing but the JSON:

$(cat "$PLANNING_OUTPUT")

Return ONLY the JSON, no markdown, no explanation."

  local JSON_OUTPUT=$(mktemp)
  if ! run_claude "$EXTRACT_PROMPT" "$JSON_OUTPUT" "haiku"; then
    echo "❌ Failed to extract JSON"
    rm -f "$JSON_OUTPUT"
    return 1
  fi

  # Validate JSON
  if ! jq empty "$JSON_OUTPUT" 2>/dev/null; then
    echo "❌ Invalid JSON generated"
    echo "   Output: $(cat "$JSON_OUTPUT")"
    rm -f "$JSON_OUTPUT"
    return 1
  fi

  # Copy to output
  cp "$JSON_OUTPUT" "$OUTPUT_JSON"
  rm -f "$JSON_OUTPUT"

  local PHASE_COUNT=$(jq -r '.phases | length' "$OUTPUT_JSON")
  echo "   ✅ Extracted $PHASE_COUNT phases"

  return 0
}

################################################################################
# generate_phase_prompt() - Create phase-specific agent prompt
################################################################################
# Usage: generate_phase_prompt PHASE_DATA MASTER_CONTEXT OUTPUT_FILE
#
# Parameters:
#   PHASE_DATA      - JSON string with phase information
#   MASTER_CONTEXT  - Path to master context file
#   OUTPUT_FILE     - Where to save generated prompt
#
# Returns: 0 on success, 1 on failure
################################################################################
generate_phase_prompt() {
  local PHASE_DATA="$1"
  local MASTER_CONTEXT="$2"
  local OUTPUT_FILE="$3"

  local PHASE_NAME=$(echo "$PHASE_DATA" | jq -r '.name')
  local PHASE_DESC=$(echo "$PHASE_DATA" | jq -r '.description')
  local SUCCESS_CRITERIA=$(echo "$PHASE_DATA" | jq -r '.success_criteria | join("\n- ")')
  local TESTING_STRATEGY=$(echo "$PHASE_DATA" | jq -r '.testing_strategy // "Test the implementation"')
  local KEY_FILES=$(echo "$PHASE_DATA" | jq -r '.key_files[]? // empty' | sed 's/^/- /')

  # Read previous phase context if available
  local PREVIOUS_CONTEXT=""
  if [[ -f "$MASTER_CONTEXT" ]]; then
    PREVIOUS_CONTEXT="
## Context from Previous Phases

$(cat "$MASTER_CONTEXT")
"
  fi

  # Generate prompt
  cat > "$OUTPUT_FILE" <<EOF
# Phase: $PHASE_NAME

## Phase Description
$PHASE_DESC

## Success Criteria
- $SUCCESS_CRITERIA

## Testing Strategy
$TESTING_STRATEGY

$(if [[ -n "$KEY_FILES" ]]; then
echo "## Key Files to Modify"
echo "$KEY_FILES"
fi)

$PREVIOUS_CONTEXT

## Your Task

Implement this phase according to the description and success criteria above.

**Critical Requirements:**
1. Test your changes incrementally
2. Update context files (context/instructions.md, progress.md, findings.md, achievements.md)
3. Document all decisions and discoveries
4. When complete, update HANDOFF.md with "Session End" and "Status: complete"
5. Include validation proof in achievements.md

## Workflow

1. Read and understand the phase description
2. Plan your implementation approach
3. Implement incrementally with testing
4. Update context files as you progress
5. Validate against success criteria
6. Mark complete in HANDOFF.md when done

Begin implementing this phase now.
EOF

  return 0
}

################################################################################
# check_phase_complete() - Check if phase completed successfully
################################################################################
# Usage: check_phase_complete HANDOFF_FILE
#
# Parameters:
#   HANDOFF_FILE - Path to phase handoff file
#
# Returns: 0 if complete, 1 if incomplete or failed
################################################################################
check_phase_complete() {
  local HANDOFF_FILE="$1"

  if [[ ! -f "$HANDOFF_FILE" ]]; then
    echo "   ❌ No handoff file found"
    return 1
  fi

  # Check for "Session End" marker
  if ! grep -q "Session End" "$HANDOFF_FILE" 2>/dev/null; then
    echo "   ❌ No 'Session End' marker"
    return 1
  fi

  # Check for "Status: complete"
  if grep -q "Status.*complete" "$HANDOFF_FILE" 2>/dev/null; then
    echo "   ✅ Phase marked complete"
    return 0
  else
    echo "   ❌ Phase not marked complete"
    return 1
  fi
}

################################################################################
# aggregate_phase_context() - Aggregate phase results to master context
################################################################################
# Usage: aggregate_phase_context PHASE_DIR MASTER_CONTEXT
#
# Parameters:
#   PHASE_DIR       - Phase directory with context files
#   MASTER_CONTEXT  - Master context file to update
#
# Returns: 0 on success
################################################################################
aggregate_phase_context() {
  local PHASE_DIR="$1"
  local MASTER_CONTEXT="$2"

  local PHASE_NAME=$(basename "$PHASE_DIR")

  echo "📝 Aggregating context from $PHASE_NAME..."

  # Create master context if doesn't exist
  if [[ ! -f "$MASTER_CONTEXT" ]]; then
    cat > "$MASTER_CONTEXT" <<EOF
# Master Agent Context

## Completed Phases

EOF
  fi

  # Append phase summary
  cat >> "$MASTER_CONTEXT" <<EOF

### $PHASE_NAME

**Status**: Complete

**Achievements**:
$(cat "$PHASE_DIR/context/achievements.md" 2>/dev/null | grep -A 999 "## Recent Achievements" | tail -n +2 | head -20)

**Key Findings**:
$(cat "$PHASE_DIR/context/findings.md" 2>/dev/null | grep -A 999 "## Key Discoveries" | tail -n +2 | head -10)

---

EOF

  echo "   ✅ Context aggregated"
  return 0
}

################################################################################
# resolve_phase_order() - Get phases in dependency order
################################################################################
# Usage: resolve_phase_order PHASES_JSON
#
# Parameters:
#   PHASES_JSON - Path to phases.json file
#
# Returns: Space-separated list of phase IDs in execution order
################################################################################
resolve_phase_order() {
  local PHASES_JSON="$1"

  # Simple dependency resolution (assumes linear dependencies)
  # For complex dependency graphs, use topological sort
  jq -r '.phases | sort_by(.depends_on | length) | .[].id' "$PHASES_JSON"
}

################################################################################
# run_master_agent() - Main master agent orchestrator
################################################################################
# Usage: run_master_agent GOAL FEATURE_DIR [MAX_ITERATIONS_PER_PHASE]
#
# Parameters:
#   GOAL                      - High-level goal to accomplish
#   FEATURE_DIR               - Base directory for this feature
#   MAX_ITERATIONS_PER_PHASE  - Max iterations per phase (default: 10)
#
# Returns: 0 on success, 1 on failure
################################################################################
run_master_agent() {
  local GOAL="$1"
  local FEATURE_DIR="$2"
  local MAX_ITERATIONS_PER_PHASE="${3:-10}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 Master Agent Starting"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Goal: $GOAL"
  echo "Feature Directory: $FEATURE_DIR"
  echo "Max Iterations/Phase: $MAX_ITERATIONS_PER_PHASE"
  echo ""

  # Create feature directory structure
  mkdir -p "$FEATURE_DIR"
  ensure_context_files "$FEATURE_DIR/context"

  # Step 1: Run planning agent
  local PLANNING_OUTPUT="$FEATURE_DIR/planning.log"
  if ! run_claude_planning "$GOAL" "$PLANNING_OUTPUT" "$FEATURE_DIR"; then
    echo "❌ Planning failed"
    return 1
  fi

  # Step 2: Generate phases.json
  local PHASES_JSON="$FEATURE_DIR/phases.json"
  if ! generate_phases_json "$PLANNING_OUTPUT" "$PHASES_JSON"; then
    echo "❌ Phase extraction failed"
    return 1
  fi

  # Display phase plan
  echo ""
  echo "📋 Phase Plan:"
  jq -r '.phases[] | "   \(.id): \(.name) (\(.max_iterations) iterations)"' "$PHASES_JSON"
  echo ""

  # Step 3: Execute phases in order
  local MASTER_CONTEXT="$FEATURE_DIR/master-context.md"
  local PHASE_ORDER=$(resolve_phase_order "$PHASES_JSON")
  local TOTAL_PHASES=$(echo "$PHASE_ORDER" | wc -w | tr -d ' ')
  local CURRENT_PHASE_NUM=0

  for PHASE_ID in $PHASE_ORDER; do
    CURRENT_PHASE_NUM=$((CURRENT_PHASE_NUM + 1))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Phase $CURRENT_PHASE_NUM of $TOTAL_PHASES: $PHASE_ID"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get phase data
    local PHASE_DATA=$(jq -r --arg id "$PHASE_ID" '.phases[] | select(.id == $id)' "$PHASES_JSON")
    local PHASE_NAME=$(echo "$PHASE_DATA" | jq -r '.name')
    local PHASE_MAX_ITER=$(echo "$PHASE_DATA" | jq -r '.max_iterations // 10')

    # Create phase directory
    local PHASE_DIR="$FEATURE_DIR/$PHASE_ID"
    mkdir -p "$PHASE_DIR"
    ensure_context_files "$PHASE_DIR/context"

    # Generate phase prompt
    local PHASE_PROMPT="$PHASE_DIR/AGENT-PROMPT.md"
    generate_phase_prompt "$PHASE_DATA" "$MASTER_CONTEXT" "$PHASE_PROMPT"

    echo "   Phase: $PHASE_NAME"
    echo "   Directory: $PHASE_DIR"
    echo "   Max Iterations: $PHASE_MAX_ITER"
    echo ""

    # Run agent for this phase
    local PHASE_HANDOFF="$PHASE_DIR/HANDOFF.md"
    local PHASE_OUTPUT_DIR="$PHASE_DIR/runs"

    # Set PROJECT_DIR for agent-runner
    export PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"

    if ! run_claude_agent \
      "$PHASE_PROMPT" \
      "$PHASE_HANDOFF" \
      "$PHASE_OUTPUT_DIR" \
      "$PHASE_MAX_ITER"; then
      echo ""
      echo "❌ Phase $PHASE_ID failed"
      return 1
    fi

    # Check phase completion
    echo ""
    echo "🔍 Validating phase completion..."
    if ! check_phase_complete "$PHASE_HANDOFF"; then
      echo ""
      echo "❌ Phase $PHASE_ID did not complete successfully"
      echo "   Review: $PHASE_HANDOFF"
      return 1
    fi

    # Aggregate context
    aggregate_phase_context "$PHASE_DIR" "$MASTER_CONTEXT"

    echo ""
    echo "✅ Phase $PHASE_ID complete"
  done

  # Final summary
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 Master Agent Complete"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Goal: $GOAL"
  echo "Phases Completed: $TOTAL_PHASES"
  echo "Master Context: $MASTER_CONTEXT"
  echo ""
  echo "Phase Directories:"
  for PHASE_ID in $PHASE_ORDER; do
    echo "   - $FEATURE_DIR/$PHASE_ID"
  done
  echo ""

  return 0
}

# Export functions for use by other scripts
export -f run_master_agent
export -f run_claude_planning
export -f generate_phases_json
export -f generate_phase_prompt
export -f check_phase_complete
export -f aggregate_phase_context
export -f resolve_phase_order
