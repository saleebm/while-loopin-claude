#!/usr/bin/env bash

# 🚀 Run Claude agent with LIVE browser preview and real-time progress
# This is the DOPAMINE-INDUCING version with visual feedback!

set -euo pipefail

# Get directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
EXAMPLE_DIR="$SCRIPT_DIR"

# Set PROJECT_DIR for agent-runner.sh
export PROJECT_DIR="$REPO_ROOT"

# Source the agent runner library (includes claude-functions.sh)
source "$REPO_ROOT/lib/agent-runner.sh"

################################################################################
# Interactive Configuration (if INTERACTIVE_MODE not disabled)
################################################################################

# Allow disabling interactive mode via environment variable
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"

if [[ "$INTERACTIVE_MODE" == "true" ]]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎨 Color Art App - LIVE Agent Demo"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Let's configure your live agent session..."
  echo ""

  # Max iterations
  if [[ -z "${MAX_ITERATIONS:-}" ]]; then
    play_alert
    speak_prompt "How many iterations should the agent run?"
    ITERATIONS_CHOICE=$(prompt_select "Max iterations (how many times should Claude improve the code):" "3 (Quick demo)" "5 (Standard)" "10 (Extended)" "20 (Deep work)")

    case $ITERATIONS_CHOICE in
      1) MAX_ITERATIONS=3 ;;
      2) MAX_ITERATIONS=5 ;;
      3) MAX_ITERATIONS=10 ;;
      4) MAX_ITERATIONS=20 ;;
    esac
  fi

  # Enable speech
  if [[ -z "${ENABLE_SPEECH:-}" ]]; then
    play_alert
    speak_prompt "Enable speech feedback?"
    if prompt_confirm "Enable speech feedback? (hear progress updates)" "n"; then
      ENABLE_SPEECH=true
    else
      ENABLE_SPEECH=false
    fi
  fi

  # Enable code review
  if [[ -z "${ENABLE_CODE_REVIEW:-}" ]]; then
    play_alert
    speak_prompt "Enable code review after agent completes?"
    if prompt_confirm "Enable code review? (quality checks after completion)" "n"; then
      ENABLE_CODE_REVIEW=true
    else
      ENABLE_CODE_REVIEW=false
    fi
  fi

  # Rate limiting
  if [[ -z "${RATE_LIMIT_SECONDS:-}" ]]; then
    play_alert
    speak_prompt "Set rate limit between iterations"
    RATE_CHOICE=$(prompt_select "Rate limit (delay between iterations):" "5 seconds (Fast)" "15 seconds (Standard)" "30 seconds (Conservative)")

    case $RATE_CHOICE in
      1) RATE_LIMIT_SECONDS=5 ;;
      2) RATE_LIMIT_SECONDS=15 ;;
      3) RATE_LIMIT_SECONDS=30 ;;
    esac
  fi

  # Auto-open browser
  if [[ -z "${AUTO_OPEN:-}" ]]; then
    play_alert
    speak_prompt "Auto-open browser?"
    if prompt_confirm "Auto-open browser?" "y"; then
      AUTO_OPEN=true
    else
      AUTO_OPEN=false
    fi
  fi

  echo ""
  echo "✅ Configuration complete!"
  echo ""
  echo "📋 Summary:"
  echo "   • Max iterations: $MAX_ITERATIONS"
  echo "   • Speech feedback: ${ENABLE_SPEECH:-false}"
  echo "   • Code review: ${ENABLE_CODE_REVIEW:-false}"
  echo "   • Rate limit: ${RATE_LIMIT_SECONDS:-15}s"
  echo "   • Auto-open browser: ${AUTO_OPEN:-true}"
  echo ""

  play_alert
  if ! prompt_confirm "Start the agent?" "y"; then
    echo "❌ Cancelled by user"
    exit 0
  fi

  echo ""
fi

# Set defaults if not configured interactively
MAX_ITERATIONS="${MAX_ITERATIONS:-3}"
RATE_LIMIT_SECONDS="${RATE_LIMIT_SECONDS:-15}"
AUTO_OPEN="${AUTO_OPEN:-true}"

# Configuration
PROMPT_FILE="$EXAMPLE_DIR/AGENT-PROMPT.md"
HANDOFF_FILE="$EXAMPLE_DIR/HANDOFF.md"
OUTPUT_DIR="$REPO_ROOT/.ai-dr/agent-runs/color-art-app"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Live Agent Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Features enabled:"
echo "   • 🌐 Live browser preview with auto-reload"
echo "   • 📊 Real-time agent progress overlay"
echo "   • 🔄 Instant visual feedback on changes"
echo "   • 💚 Maximum dopamine delivery!"
echo ""
echo "📍 Working directory: $EXAMPLE_DIR"
echo "📝 Prompt: $PROMPT_FILE"
echo "🔄 Max iterations: $MAX_ITERATIONS"
echo ""

# Check if node_modules/ws exists
if [ ! -d "$REPO_ROOT/node_modules/ws" ]; then
  echo "📦 Installing dependencies..."
  cd "$REPO_ROOT"
  npm install
  echo ""
fi

# Start live server in background
echo "🚀 Starting live server..."
LIVE_SERVER_PID=""

cleanup() {
  if [ -n "$LIVE_SERVER_PID" ]; then
    echo ""
    echo "🛑 Stopping live server..."
    kill $LIVE_SERVER_PID 2>/dev/null || true
  fi
}
trap cleanup EXIT

cd "$REPO_ROOT"
WATCH_DIR="$EXAMPLE_DIR" AUTO_OPEN="$AUTO_OPEN" node lib/live-server.js &
LIVE_SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 3

# Send initial progress update
update_live_progress 0 "$MAX_ITERATIONS" "idle" "Agent starting..."

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Change to example directory so Claude operates on these files
cd "$EXAMPLE_DIR"

# Enhanced agent loop with live updates
run_claude_agent_with_live_updates() {
  local CURRENT_ITERATION=0

  # Override the iteration loop to send progress updates
  for ((i=1; i<=MAX_ITERATIONS; i++)); do
    CURRENT_ITERATION=$i

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔄 Iteration $CURRENT_ITERATION of $MAX_ITERATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Send progress update: iteration starting
    update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "running" "Running iteration $CURRENT_ITERATION..."

    # Build the iteration output file
    local ITERATION_OUTPUT="$OUTPUT_DIR/iteration-$(printf "%03d" $CURRENT_ITERATION).md"
    mkdir -p "$OUTPUT_DIR"

    # Create the prompt for this iteration
    local ITERATION_PROMPT="$PROMPT_FILE"
    if [ -f "$HANDOFF_FILE" ]; then
      ITERATION_PROMPT="$(cat "$PROMPT_FILE")

Previous session handoff:
$(cat "$HANDOFF_FILE")
"
    fi

    # Run Claude
    echo "🤖 Running Claude..."
    if run_claude "$ITERATION_PROMPT" "$ITERATION_OUTPUT" "sonnet"; then
      local OUTPUT_SIZE=$(wc -c < "$ITERATION_OUTPUT" | tr -d ' ')
      echo ""
      echo "✅ Iteration $CURRENT_ITERATION complete"
      echo "📊 Output size: $(numfmt --to=iec-i --suffix=B $OUTPUT_SIZE 2>/dev/null || echo "${OUTPUT_SIZE} bytes")"

      # Update progress
      update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "running" "Iteration $CURRENT_ITERATION complete, reviewing..."

      # Check if we should continue
      if [ -f "$HANDOFF_FILE" ]; then
        if grep -qi "Status: complete" "$HANDOFF_FILE" 2>/dev/null; then
          echo ""
          echo "🎯 Agent marked work as complete!"
          update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "complete" "All iterations complete!"
          break
        fi
      fi

      # Rate limiting
      if [ $i -lt $MAX_ITERATIONS ]; then
        local DELAY="${RATE_LIMIT_SECONDS:-15}"
        echo ""
        echo "⏸️  Rate limiting: waiting ${DELAY}s before next iteration..."
        update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "running" "Waiting ${DELAY}s before next iteration..."
        sleep "$DELAY"
      fi
    else
      echo "❌ Claude execution failed"
      update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "idle" "Error in iteration $CURRENT_ITERATION"
      return 1
    fi

    echo ""
  done

  # Final status
  update_live_progress "$CURRENT_ITERATION" "$MAX_ITERATIONS" "complete" "Agent loop complete!"
}

# Run the enhanced agent loop
run_claude_agent_with_live_updates

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "✨ Agent run complete!"
echo ""
echo "🎯 The browser window should still be open showing your app!"
echo "   Check out the changes in real-time."
echo ""
echo "📝 Next steps:"
echo "  1. The app is still running at http://localhost:3000"
echo "  2. Check what changed: git diff index.html"
echo "  3. Read the handoff: cat HANDOFF.md"
echo "  4. See full logs: ls -la $OUTPUT_DIR"
echo ""
echo "Press Ctrl+C to stop the live server..."
echo ""

# Keep server running until user stops it
wait $LIVE_SERVER_PID
