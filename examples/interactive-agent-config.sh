#!/usr/bin/env bash

# Example: Interactive Agent Configuration
# Shows how to use prompt_user() to configure an agent run

set -euo pipefail

# Get script directory and source functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the interactive prompt system
source "$PROJECT_DIR/lib/claude-functions.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Interactive Agent Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Configure your agent run with interactive prompts."
echo ""

# 1. Choose task type
TASK_TYPE_IDX=$(prompt_user select "What type of task?" \
  "Bug fix" \
  "New feature" \
  "Refactoring" \
  "Documentation" \
  "Testing")

TASK_TYPES=("bug-fix" "feature" "refactor" "docs" "testing")
TASK_TYPE="${TASK_TYPES[$((TASK_TYPE_IDX-1))]}"

echo ""
echo "   ✅ Task type: $TASK_TYPE"

# 2. Get task description
TASK_DESC=$(prompt_user text "Enter task description:" "")

echo ""
echo "   ✅ Description: $TASK_DESC"

# 3. Select complexity/iterations
COMPLEXITY_IDX=$(prompt_user select "Task complexity?" \
  "Simple (5 iterations)" \
  "Medium (10 iterations)" \
  "Complex (15 iterations)" \
  "Very complex (20 iterations)")

COMPLEXITIES=(5 10 15 20)
MAX_ITERATIONS="${COMPLEXITIES[$((COMPLEXITY_IDX-1))]}"

echo ""
echo "   ✅ Max iterations: $MAX_ITERATIONS"

# 4. Enable features
FEATURES=$(prompt_user multiselect "Enable features?" \
  "Code review" \
  "Speech output" \
  "Auto-commit" \
  "Lint/typecheck")

echo ""
echo "   ✅ Selected features:"

# Parse feature selections
ENABLE_CODE_REVIEW=false
ENABLE_SPEECH=false
ENABLE_AUTO_COMMIT=false
ENABLE_LINT=false

for feature_idx in $FEATURES; do
  case $feature_idx in
    1)
      ENABLE_CODE_REVIEW=true
      echo "      - Code review"
      ;;
    2)
      ENABLE_SPEECH=true
      echo "      - Speech output"
      ;;
    3)
      ENABLE_AUTO_COMMIT=true
      echo "      - Auto-commit"
      ;;
    4)
      ENABLE_LINT=true
      echo "      - Lint/typecheck"
      ;;
  esac
done

# 5. Configure code review if enabled
MAX_REVIEWS=5
if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
  if ! prompt_user confirm "Use default max reviews (5)?" "y"; then
    MAX_REVIEWS=$(prompt_user text "Enter max reviews:" "5")
    echo ""
    echo "   ✅ Max reviews: $MAX_REVIEWS"
  fi
fi

# 6. Final confirmation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Configuration Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Task Type:        $TASK_TYPE"
echo "Description:      $TASK_DESC"
echo "Max Iterations:   $MAX_ITERATIONS"
echo "Code Review:      $ENABLE_CODE_REVIEW"
if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
  echo "Max Reviews:      $MAX_REVIEWS"
fi
echo "Speech Output:    $ENABLE_SPEECH"
echo "Auto-commit:      $ENABLE_AUTO_COMMIT"
echo "Lint/Typecheck:   $ENABLE_LINT"
echo ""

if prompt_user confirm "Proceed with this configuration?" "y"; then
  echo ""
  echo "   ✅ Configuration confirmed!"
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 Starting Agent..."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "This is where you would call run_claude_agent() with:"
  echo ""
  echo "  ENABLE_CODE_REVIEW=$ENABLE_CODE_REVIEW \\"
  echo "  MAX_CODE_REVIEWS=$MAX_REVIEWS \\"
  echo "  ENABLE_SPEECH=$ENABLE_SPEECH \\"
  echo "  bash lib/agent-runner.sh \\"
  echo "    \"prompt.md\" \\"
  echo "    \"HANDOFF.md\" \\"
  echo "    \".ai-dr/agent-runs\" \\"
  echo "    \"$MAX_ITERATIONS\""
  echo ""
else
  echo ""
  echo "   ❌ Configuration cancelled"
  exit 1
fi
