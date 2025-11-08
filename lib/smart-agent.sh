#!/usr/bin/env bash

# Smart AI-Orchestrated Agent Runner
# Uses Claude to analyze prompt and determine all configuration
# No hard-coded logic - AI figures everything out

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared agent library
source "$SCRIPT_DIR/agent-runner.sh"
source "$SCRIPT_DIR/master-agent.sh"

# Help message
show_help() {
  cat <<EOF
Usage: bash smart-agent.sh [PROMPT]

Smart AI orchestrator that analyzes your prompt and automatically:
- Determines task type (bug fix, feature, refactor, etc.)
- Creates appropriate .specs/{feature-name}/ structure
- Generates enhanced prompt and initial handoff
- Configures and runs agent with optimal settings

Arguments:
  PROMPT    Either a file path or raw text prompt

Examples:
  bash smart-agent.sh "Fix the frontmatter corruption bug"
  bash smart-agent.sh plan-file.txt
  bash smart-agent.sh "Add dark mode support to the editor"

The AI will:
- Analyze your prompt to understand intent
- Determine relevant files and context
- Create feature directory with all needed files
- Run agent with appropriate configuration
EOF
}

# Check arguments
if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
  show_help
  exit 0
fi

# Get prompt (either from file or direct text)
PROMPT_INPUT="$1"
PROMPT_TEXT=""

if [[ -f "$PROMPT_INPUT" ]]; then
  PROMPT_TEXT=$(cat "$PROMPT_INPUT")
  echo "📄 Reading prompt from file: $PROMPT_INPUT"
else
  PROMPT_TEXT="$PROMPT_INPUT"
  echo "📝 Using inline prompt"
fi

echo ""
echo "🤖 Analyzing prompt with AI..."
echo ""

# Create temp file for prompt analysis
TEMP_DIR=$(mktemp -d)
TEMP_PROMPT="$TEMP_DIR/prompt.txt"
TEMP_ANALYSIS_PROMPT="$TEMP_DIR/analysis-prompt.md"

# Save user's prompt to temp file
echo "$PROMPT_TEXT" > "$TEMP_PROMPT"

# Create analysis prompt that references the temp file
cat > "$TEMP_ANALYSIS_PROMPT" <<'EOF'
Analyze this prompt and return a structured JSON configuration for running an autonomous agent.

Read the user's prompt from the file and analyze it.

Your Task:
1. What type of task is this? (be specific and creative - don't just say "bug fix" or "feature", describe it precisely)
2. What should the feature folder be named? (kebab-case slug)
3. What files are likely relevant to this task?
4. How complex is this task? (estimate iterations needed)
5. Should this include code review?
6. Create an enhanced version of the prompt with full context
7. Write an initial handoff document

Required JSON Structure:
{
  "feature_name": "descriptive-kebab-case-name",
  "prompt_type": "specific task type description",
  "complexity": 5,
  "max_iterations": 10,
  "enable_code_review": true,
  "max_reviews": 5,
  "use_master_agent": false,
  "estimated_complexity": "low|medium|high|very-high",
  "relevant_files": [
    "src/components/MilkdownEditor.tsx",
    "src/core/mdx-parser.ts"
  ],
  "enhanced_prompt": "Detailed prompt with full context...",
  "initial_handoff": "# Agent Handoff\n\n## Status\nStarting\n\n## Task\n...",
  "reasoning": "Why I chose these settings..."
}

Use "use_master_agent": true for tasks that:
- Require multiple distinct phases (e.g., "build complete auth system")
- Have complex dependencies between components
- Need coordinated work across different subsystems
- Have estimated_complexity of "very-high"

Use "use_master_agent": false for tasks that:
- Are single-focused (e.g., "fix this bug", "add this feature")
- Can be completed in a linear fashion
- Have low to high complexity but not very-high

Return ONLY valid JSON, nothing else.
EOF

# Run analysis using Claude CLI which handles auth properly
cd "$PROJECT_DIR" || exit 1

# Use run_claude_json function that works with Claude CLI
ANALYSIS_OUTPUT=$(mktemp)
if run_claude_json "$(<"$TEMP_ANALYSIS_PROMPT")" "haiku" > "$ANALYSIS_OUTPUT" 2>&1; then
  ANALYSIS_JSON=$(cat "$ANALYSIS_OUTPUT")
  EXTRACT_EXIT_CODE=0
else
  EXTRACT_EXIT_CODE=1
  ANALYSIS_JSON=""
fi
rm -f "$ANALYSIS_OUTPUT"

# Cleanup temp files
rm -rf "$TEMP_DIR"

# Validate JSON
if [[ $EXTRACT_EXIT_CODE -ne 0 ]] || ! echo "$ANALYSIS_JSON" | jq empty 2>/dev/null; then
  echo "❌ Error: Failed to extract valid analysis JSON"
  echo ""
  echo "Output from extraction:"
  echo "$ANALYSIS_JSON"
  echo ""
  echo "Falling back to minimal configuration..."
  
  # Create minimal fallback configuration
  ANALYSIS_JSON='{
    "feature_name": "task",
    "prompt_type": "General task",
    "complexity": 5,
    "max_iterations": 10,
    "enable_code_review": true,
    "max_reviews": 3,
    "relevant_files": [],
    "enhanced_prompt": "'"$(cat "$PROMPT_INPUT" | jq -Rs .)"'",
    "initial_handoff": "# Agent Handoff\n\n## Session End\nStatus: starting\n\n## Task\nStarting new task",
    "reasoning": "Using default settings due to analysis error"
  }'
fi

# Extract configuration
FEATURE_NAME=$(echo "$ANALYSIS_JSON" | jq -r '.feature_name')
PROMPT_TYPE=$(echo "$ANALYSIS_JSON" | jq -r '.prompt_type')
MAX_ITERATIONS=$(echo "$ANALYSIS_JSON" | jq -r '.max_iterations')
ENABLE_CODE_REVIEW=$(echo "$ANALYSIS_JSON" | jq -r '.enable_code_review')
MAX_REVIEWS=$(echo "$ANALYSIS_JSON" | jq -r '.max_reviews')
USE_MASTER_AGENT=$(echo "$ANALYSIS_JSON" | jq -r '.use_master_agent // "false"')
ESTIMATED_COMPLEXITY=$(echo "$ANALYSIS_JSON" | jq -r '.estimated_complexity // "medium"')
ENHANCED_PROMPT=$(echo "$ANALYSIS_JSON" | jq -r '.enhanced_prompt')
INITIAL_HANDOFF=$(echo "$ANALYSIS_JSON" | jq -r '.initial_handoff')
REASONING=$(echo "$ANALYSIS_JSON" | jq -r '.reasoning')

# Allow override via environment variable
if [[ "${MASTER_AGENT:-}" == "true" ]]; then
  USE_MASTER_AGENT=true
fi

# Display analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 AI Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Task Type: $PROMPT_TYPE"
echo "📁 Feature Name: $FEATURE_NAME"
echo "📊 Complexity: $ESTIMATED_COMPLEXITY"
echo "🔄 Max Iterations: $MAX_ITERATIONS"
echo "🔍 Code Review: $ENABLE_CODE_REVIEW"
if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
  echo "📊 Max Reviews: $MAX_REVIEWS"
fi
echo "🎯 Master Agent: $USE_MASTER_AGENT"
echo ""
echo "💡 Reasoning:"
echo "$REASONING" | sed 's/^/   /'
echo ""

# Interactive configuration (if not set via env vars)
# Allow user to override AI suggestions
if [[ "${INTERACTIVE_MODE:-true}" == "true" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚙️  Configuration"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # Confirm or adjust max iterations
  if prompt_user confirm "Use AI-suggested max iterations ($MAX_ITERATIONS)?" "y"; then
    echo "   ✅ Using $MAX_ITERATIONS iterations"
  else
    MAX_ITERATIONS=$(prompt_user text "Enter max iterations:" "$MAX_ITERATIONS")
    echo "   ✅ Set to $MAX_ITERATIONS iterations"
  fi

  # Confirm or adjust code review
  if prompt_user confirm "Enable code review? (AI suggested: $ENABLE_CODE_REVIEW)" "$ENABLE_CODE_REVIEW"; then
    ENABLE_CODE_REVIEW=true
    echo "   ✅ Code review enabled"

    # Optionally adjust max reviews
    if prompt_user confirm "Use AI-suggested max reviews ($MAX_REVIEWS)?" "y"; then
      echo "   ✅ Using $MAX_REVIEWS reviews"
    else
      MAX_REVIEWS=$(prompt_user text "Enter max reviews:" "$MAX_REVIEWS")
      echo "   ✅ Set to $MAX_REVIEWS reviews"
    fi
  else
    ENABLE_CODE_REVIEW=false
    echo "   ⏭️  Code review disabled"
  fi

  # Enable speech option
  if [[ "${ENABLE_SPEECH:-false}" != "true" ]]; then
    if prompt_user confirm "Enable speech summaries?" "n"; then
      ENABLE_SPEECH=true
      export ENABLE_SPEECH
      echo "   ✅ Speech enabled"
    else
      echo "   ⏭️  Speech disabled"
    fi
  fi

  # Master agent option (only show if AI suggested it or complexity is very-high)
  if [[ "$USE_MASTER_AGENT" == "true" ]] || [[ "$ESTIMATED_COMPLEXITY" == "very-high" ]]; then
    if prompt_user confirm "Use master agent for multi-phase execution? (AI suggested: $USE_MASTER_AGENT)" "$USE_MASTER_AGENT"; then
      USE_MASTER_AGENT=true
      echo "   ✅ Master agent enabled"
    else
      USE_MASTER_AGENT=false
      echo "   ⏭️  Using standard agent"
    fi
  fi

  echo ""
fi

# Create feature directory structure
FEATURE_DIR="$PROJECT_DIR/.specs/$FEATURE_NAME"
OUTPUT_DIR="$PROJECT_DIR/.ai-dr/agent-runs/$FEATURE_NAME"

mkdir -p "$FEATURE_DIR"
mkdir -p "$OUTPUT_DIR"

# Save analysis JSON
echo "$ANALYSIS_JSON" > "$FEATURE_DIR/analysis.json"
echo "💾 Saved analysis: $FEATURE_DIR/analysis.json"

# Create AGENT-PROMPT.md
echo "$ENHANCED_PROMPT" > "$FEATURE_DIR/AGENT-PROMPT.md"
echo "💾 Created prompt: $FEATURE_DIR/AGENT-PROMPT.md"

# Create initial HANDOFF.md
echo "$INITIAL_HANDOFF" > "$FEATURE_DIR/HANDOFF.md"
echo "💾 Created handoff: $FEATURE_DIR/HANDOFF.md"

# Create README.md for navigation
cat > "$FEATURE_DIR/README.md" <<EOF
# $FEATURE_NAME

## Task Type
$PROMPT_TYPE

## Files
- [AGENT-PROMPT.md](./AGENT-PROMPT.md) - Enhanced prompt for agent
- [HANDOFF.md](./HANDOFF.md) - Current status and handoff
- [analysis.json](./analysis.json) - AI analysis and configuration

## Outputs
Agent outputs: \`.ai-dr/agent-runs/$FEATURE_NAME/\`

## Configuration
- Max iterations: $MAX_ITERATIONS
- Code review: $ENABLE_CODE_REVIEW
$(if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then echo "- Max reviews: $MAX_REVIEWS"; fi)
EOF

echo "💾 Created README: $FEATURE_DIR/README.md"
echo ""

# Choose execution mode based on USE_MASTER_AGENT flag
if [[ "$USE_MASTER_AGENT" == "true" ]]; then
  # Master Agent Mode - Multi-Phase Execution
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎯 Starting Master Agent (Multi-Phase Mode)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Master agent takes the original user goal and feature directory
  # It will handle planning, phase breakdown, and execution
  run_master_agent "$PROMPT_TEXT" "$FEATURE_DIR" "$MAX_ITERATIONS"

  echo ""
  echo "✅ Master agent complete"
  echo "📁 Feature dir: $FEATURE_DIR"
  echo "📁 Phase outputs: $FEATURE_DIR/phase-*/"
else
  # Standard Agent Mode - Single Phase Execution
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🚀 Starting Standard Agent (Single-Phase Mode)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  # Build agent arguments
  AGENT_ARGS=(
    "$FEATURE_DIR/AGENT-PROMPT.md"
    "$FEATURE_DIR/HANDOFF.md"
    "$OUTPUT_DIR"
    "$MAX_ITERATIONS"
  )

  if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
    AGENT_ARGS+=(--enable-code-review --max-reviews "$MAX_REVIEWS")
  fi

  # Run the standard agent
  run_claude_agent "${AGENT_ARGS[@]}"

  echo ""
  echo "✅ Smart agent complete"
  echo "📁 Feature dir: $FEATURE_DIR"
  echo "📁 Outputs: $OUTPUT_DIR"
fi
