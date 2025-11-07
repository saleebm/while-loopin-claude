#!/usr/bin/env bash

# Custom Prompt Demo
# Shows how to integrate interactive prompts into your own scripts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source the interactive prompt system
source "$PROJECT_DIR/lib/claude-functions.sh"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎨 Custom Script with Interactive Prompts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Example 1: Simple confirmation
if prompt_user confirm "Would you like to create a new project?" "y"; then

  # Example 2: Get project details
  PROJECT_NAME=$(prompt_user text "Project name:" "my-app")

  # Example 3: Choose template
  TEMPLATE_IDX=$(prompt_user select "Choose project template:" \
    "React + TypeScript" \
    "Next.js" \
    "Express API" \
    "Vanilla JS")

  TEMPLATES=("react-ts" "nextjs" "express" "vanilla")
  TEMPLATE="${TEMPLATES[$((TEMPLATE_IDX-1))]}"

  # Example 4: Select features
  FEATURES=$(prompt_user multiselect "Select features:" \
    "ESLint" \
    "Prettier" \
    "Jest" \
    "GitHub Actions" \
    "Docker")

  # Convert feature selections
  FEATURE_NAMES=("ESLint" "Prettier" "Jest" "GitHub Actions" "Docker")
  SELECTED_FEATURES=()

  for idx in $FEATURES; do
    SELECTED_FEATURES+=("${FEATURE_NAMES[$((idx-1))]}")
  done

  # Display configuration
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📋 Project Configuration"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Name:     $PROJECT_NAME"
  echo "Template: $TEMPLATE"
  echo "Features:"
  for feature in "${SELECTED_FEATURES[@]}"; do
    echo "  - $feature"
  done
  echo ""

  # Final confirmation
  if prompt_user confirm "Create project with this configuration?" "y"; then
    echo ""
    echo "✅ Creating project..."

    # Simulate project creation
    mkdir -p "/tmp/$PROJECT_NAME"
    echo "Project: $PROJECT_NAME" > "/tmp/$PROJECT_NAME/README.md"
    echo "Template: $TEMPLATE" >> "/tmp/$PROJECT_NAME/README.md"
    echo "Features: ${SELECTED_FEATURES[*]}" >> "/tmp/$PROJECT_NAME/README.md"

    echo "✅ Project created at: /tmp/$PROJECT_NAME"
    echo ""
    echo "Next steps:"
    echo "  cd /tmp/$PROJECT_NAME"
    echo "  cat README.md"
  else
    echo ""
    echo "❌ Project creation cancelled"
  fi

else
  echo ""
  echo "👋 No problem! Run this script again when ready."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Demo complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
