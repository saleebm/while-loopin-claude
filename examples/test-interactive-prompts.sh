#!/usr/bin/env bash

# Test script for interactive prompt system
# Demonstrates all prompt types with examples

set -euo pipefail

# Get script directory and source functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source claude-functions which contains the prompt system
source "$PROJECT_DIR/lib/claude-functions.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧪 Interactive Prompt System Test"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script tests all interactive prompt types:"
echo "  1. Text input (with defaults)"
echo "  2. Single select menu"
echo "  3. Multi-select menu"
echo "  4. Yes/No confirmation"
echo "  5. Main dispatcher (prompt_user)"
echo ""
echo "Each test will:"
echo "  - Play an alert sound"
echo "  - Show the prompt"
echo "  - Wait for your input"
echo "  - Display the result"
echo ""
echo "Press Enter to begin tests..."
read -r

# Test 1: Text input
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 1: Text Input"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PROJECT_NAME=$(prompt_user text "Enter project name:" "my-awesome-project")
echo ""
echo "   Result: PROJECT_NAME='$PROJECT_NAME'"

# Test 2: Single select
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 2: Single Select Menu"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MODEL_CHOICE=$(prompt_user select "Choose Claude model:" "claude-sonnet" "claude-opus" "claude-haiku")
MODELS=("claude-sonnet" "claude-opus" "claude-haiku")
SELECTED_MODEL="${MODELS[$((MODEL_CHOICE-1))]}"
echo ""
echo "   Result: Selected option $MODEL_CHOICE → '$SELECTED_MODEL'"

# Test 3: Multi-select
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 3: Multi-Select Menu"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

FEATURE_CHOICES=$(prompt_user multiselect "Select features to enable:" "Authentication" "Database" "API" "Email" "Analytics")
echo ""
echo "   Result: Selected options: $FEATURE_CHOICES"

# Convert to array and show selected features
FEATURES=("Authentication" "Database" "API" "Email" "Analytics")
echo "   Selected features:"
for choice in $FEATURE_CHOICES; do
  echo "     - ${FEATURES[$((choice-1))]}"
done

# Test 4: Confirmation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Test 4: Yes/No Confirmation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if prompt_user confirm "Enable code review?" "y"; then
  echo ""
  echo "   Result: Code review ENABLED"
  ENABLE_REVIEW=true
else
  echo ""
  echo "   Result: Code review DISABLED"
  ENABLE_REVIEW=false
fi

if prompt_user confirm "Enable speech output?" "n"; then
  echo ""
  echo "   Result: Speech output ENABLED"
  ENABLE_SPEECH_TEST=true
else
  echo ""
  echo "   Result: Speech output DISABLED"
  ENABLE_SPEECH_TEST=false
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Text Input:"
echo "  Project Name: $PROJECT_NAME"
echo ""
echo "Single Select:"
echo "  Selected Model: $SELECTED_MODEL"
echo ""
echo "Multi-Select:"
echo "  Selected Features: $FEATURE_CHOICES"
for choice in $FEATURE_CHOICES; do
  echo "    - ${FEATURES[$((choice-1))]}"
done
echo ""
echo "Confirmations:"
echo "  Code Review: $ENABLE_REVIEW"
echo "  Speech Output: $ENABLE_SPEECH_TEST"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All tests complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
