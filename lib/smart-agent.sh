#!/usr/bin/env bash

# Smart AI-Orchestrated Agent Runner
# Uses Claude to analyze prompt and determine all configuration
# No hard-coded logic - AI figures everything out

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared agent library
source "$SCRIPT_DIR/agent-runner.sh"

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
  "relevant_files": [
    "src/components/MilkdownEditor.tsx",
    "src/core/mdx-parser.ts"
  ],
  "enhanced_prompt": "Detailed prompt with full context...",
  "initial_handoff": "# Agent Handoff\n\n## Status\nStarting\n\n## Task\n...",
  "reasoning": "Why I chose these settings..."
}

Return ONLY valid JSON, nothing else.
EOF

# Run Claude in JSON mode with the prompt file
cd "$PROJECT_DIR" || exit 1

ANALYSIS_JSON=$(claude \
  --print \
  --output-format json \
  --dangerously-skip-permissions \
  "$(cat "$TEMP_ANALYSIS_PROMPT")

# User's Prompt to Analyze
$(cat "$TEMP_PROMPT")")

# Cleanup temp files
rm -rf "$TEMP_DIR"

# Extract the actual result from CLI JSON wrapper
CLAUDE_RESULT=$(echo "$ANALYSIS_JSON" | jq -r '.result')

# Extract JSON from markdown code block (```json ... ```)
ANALYSIS_JSON=$(echo "$CLAUDE_RESULT" | sed -n '/```json/,/```/p' | sed '1d;$d')

# Validate JSON
if ! echo "$ANALYSIS_JSON" | jq empty; then
  echo "❌ Error: Extracted invalid JSON"
  echo ""
  echo "Full extracted content:"
  echo "$ANALYSIS_JSON"
  echo ""
  echo "Original Claude result:"
  echo "$CLAUDE_RESULT"
  exit 1
fi

# Extract configuration
FEATURE_NAME=$(echo "$ANALYSIS_JSON" | jq -r '.feature_name')
PROMPT_TYPE=$(echo "$ANALYSIS_JSON" | jq -r '.prompt_type')
MAX_ITERATIONS=$(echo "$ANALYSIS_JSON" | jq -r '.max_iterations')
ENABLE_CODE_REVIEW=$(echo "$ANALYSIS_JSON" | jq -r '.enable_code_review')
MAX_REVIEWS=$(echo "$ANALYSIS_JSON" | jq -r '.max_reviews')
ENHANCED_PROMPT=$(echo "$ANALYSIS_JSON" | jq -r '.enhanced_prompt')
INITIAL_HANDOFF=$(echo "$ANALYSIS_JSON" | jq -r '.initial_handoff')
REASONING=$(echo "$ANALYSIS_JSON" | jq -r '.reasoning')

# Display analysis
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 AI Analysis Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Task Type: $PROMPT_TYPE"
echo "📁 Feature Name: $FEATURE_NAME"
echo "🔄 Max Iterations: $MAX_ITERATIONS"
echo "🔍 Code Review: $ENABLE_CODE_REVIEW"
if [[ "$ENABLE_CODE_REVIEW" == "true" ]]; then
  echo "📊 Max Reviews: $MAX_REVIEWS"
fi
echo ""
echo "💡 Reasoning:"
echo "$REASONING" | sed 's/^/   /'
echo ""

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

# Run the agent
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Agent"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

run_claude_agent "${AGENT_ARGS[@]}"

echo ""
echo "✅ Smart agent complete"
echo "📁 Feature dir: $FEATURE_DIR"
echo "📁 Outputs: $OUTPUT_DIR"
