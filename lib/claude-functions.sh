#!/usr/bin/env bash

# Reusable Claude execution functions
# Source this file to use run_claude() and generate_structured_output()

set -euo pipefail

################################################################################
# run_claude() - Execute Claude and save output to file
################################################################################
# Usage: run_claude PROMPT OUTPUT_FILE [MODEL] [OPTIONS...]
#
# Parameters:
#   PROMPT       - The prompt to send to Claude (string)
#   OUTPUT_FILE  - Path to save output
#   MODEL        - Optional model (default: sonnet)
#   OPTIONS      - Additional claude CLI options
#
# Returns: 0 on success, 1 on failure
################################################################################
run_claude() {
  local PROMPT="$1"
  local OUTPUT_FILE="$2"
  local MODEL="${3:-sonnet}"
  shift 2
  [[ $# -gt 0 ]] && shift  # Remove MODEL if provided

  local ADDITIONAL_OPTS=("$@")

  # Run Claude with tee to show output AND save to file
  # Use parameter expansion to handle empty array in set -u mode
  if ! claude \
    --print \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    --output-format text \
    ${ADDITIONAL_OPTS[@]+"${ADDITIONAL_OPTS[@]}"} \
    "$PROMPT" \
    2>&1 | tee "$OUTPUT_FILE"; then
    return 1
  fi

  return 0
}

################################################################################
# run_claude_json() - Execute Claude expecting JSON result; unwrap CLI envelope
################################################################################
# Usage: run_claude_json PROMPT [MODEL]
# Prints the best-effort JSON string (no fences) to stdout
run_claude_json() {
  local PROMPT="$1"
  local MODEL="${2:-haiku}"

  local RAW_JSON
  RAW_JSON=$(claude \
    --print \
    --model "$MODEL" \
    --output-format json \
    --dangerously-skip-permissions \
    "$PROMPT" || echo '{"type":"result","result":"{\"error\":true}"}')

  local RESULT=$(echo "$RAW_JSON" | jq -r '.result // "{}"')

  if echo "$RESULT" | grep -q '```json'; then
    RESULT=$(echo "$RESULT" | sed -n '/```json/,/```/p' | sed '1d;$d')
  fi

  # Validate JSON; if invalid, return minimal valid JSON
  if ! echo "$RESULT" | jq empty 2>/dev/null; then
    echo '{}'
  else
    echo "$RESULT"
  fi
}

################################################################################
# generate_structured_output() - Use Haiku to create structured JSON output
################################################################################
# Usage: generate_structured_output INPUT_FILE [ADDITIONAL_JSON]
#
# Parameters:
#   INPUT_FILE       - File containing text to analyze
#   ADDITIONAL_JSON  - Optional JSON string with additional keys to merge
#                      Example: '{"score": 8, "issues": ["fix1", "fix2"]}'
#
# Output: Prints JSON to stdout
#
# Default output structure:
# {
#   "speech": "sentence to speak out loud",
#   ...additional keys...
# }
################################################################################
generate_structured_output() {
  local INPUT_FILE="$1"
  local ADDITIONAL_JSON="${2:-{}}"

  # Base prompt for structured output
  local PROMPT="Analyze this output and create a JSON response with:
1. \"speech\": A concise 1-sentence summary (max 15 words) to speak out loud

$(cat "$INPUT_FILE")

Respond with ONLY valid JSON, nothing else. Example:
{
  \"speech\": \"Your summary here\"
}
"

  # If additional JSON provided, update prompt
  if [[ "$ADDITIONAL_JSON" != "{}" ]]; then
    # Extract additional keys from JSON
    local ADDITIONAL_KEYS=$(echo "$ADDITIONAL_JSON" | jq -r 'keys | join(", ")')

    PROMPT="Analyze this output and create a JSON response with:
1. \"speech\": A concise 1-sentence summary (max 15 words) to speak out loud
2. Additional required keys: $ADDITIONAL_KEYS

$(cat "$INPUT_FILE")

Respond with ONLY valid JSON matching this structure:
$(echo "$ADDITIONAL_JSON" | jq -c 'with_entries(.value = "<your value>")')"
  fi

  # Run Haiku to generate structured output
  # IMPORTANT: --output-format json wraps response in CLI envelope
  local HAIKU_RAW=$(claude \
    --print \
    --model haiku \
    --output-format json \
    --dangerously-skip-permissions \
    "$PROMPT" || echo '{"type":"result","result":"{\"speech\": \"Processing complete\", \"error\": true}"}')

  # Extract .result from CLI wrapper
  local HAIKU_RESULT=$(echo "$HAIKU_RAW" | jq -r '.result')

  # Extract JSON from markdown code block if present
  if echo "$HAIKU_RESULT" | grep -q '```json'; then
    HAIKU_RESULT=$(echo "$HAIKU_RESULT" | sed -n '/```json/,/```/p' | sed '1d;$d')
  fi

  # Validate extracted JSON
  if ! echo "$HAIKU_RESULT" | jq empty; then
    echo '{"speech": "Processing complete", "error": true}'
    return 0
  fi

  # If additional JSON provided, merge it
  if [[ "$ADDITIONAL_JSON" != "{}" ]]; then
    # Merge: ADDITIONAL_JSON as base, HAIKU_RESULT overrides
    echo "$ADDITIONAL_JSON" "$HAIKU_RESULT" | jq -s '.[0] * .[1]' || echo "$HAIKU_RESULT"
  else
    echo "$HAIKU_RESULT"
  fi
}

################################################################################
# speak_from_json() - Extract speech field from JSON and speak it
################################################################################
# Usage: speak_from_json JSON_STRING
#
# Parameters:
#   JSON_STRING - JSON containing "speech" field
################################################################################
speak_from_json() {
  local JSON_STRING="$1"
  local SPEECH=$(echo "$JSON_STRING" | jq -r '.speech // "Processing complete"' 2>/dev/null || echo "Processing complete")

  if [[ "${ENABLE_SPEECH:-false}" == "true" ]]; then
    echo "   📢 $SPEECH"
    say "$SPEECH"
  fi
}

################################################################################
# Interactive Prompt System
################################################################################
# Modular, composable functions for getting user input with alerts and speech
################################################################################

################################################################################
# play_alert() - Play system alert sound
################################################################################
# Usage: play_alert
################################################################################
play_alert() {
  # Play system alert sound (macOS)
  afplay /System/Library/Sounds/Glass.aiff 2>/dev/null || true
}

################################################################################
# speak_prompt() - Speak prompt text if speech enabled
################################################################################
# Usage: speak_prompt TEXT
#
# Parameters:
#   TEXT - Text to speak
################################################################################
speak_prompt() {
  local TEXT="$1"

  if [[ "${ENABLE_SPEECH:-false}" == "true" ]]; then
    say "$TEXT"
  fi
}

################################################################################
# prompt_text() - Get text input from user
################################################################################
# Usage: prompt_text QUESTION [DEFAULT_VALUE]
#
# Parameters:
#   QUESTION       - Question to ask user
#   DEFAULT_VALUE  - Optional default value
#
# Returns: User's input (or default if empty)
################################################################################
prompt_text() {
  local QUESTION="$1"
  local DEFAULT="${2:-}"
  local RESPONSE=""

  echo ""
  echo "❓ $QUESTION"
  if [[ -n "$DEFAULT" ]]; then
    echo "   (default: $DEFAULT)"
  fi
  echo -n "   > "
  read -r RESPONSE

  if [[ -z "$RESPONSE" && -n "$DEFAULT" ]]; then
    RESPONSE="$DEFAULT"
  fi

  echo "$RESPONSE"
}

################################################################################
# prompt_select() - Present single-choice menu
################################################################################
# Usage: prompt_select QUESTION OPTION1 OPTION2 [OPTION3...]
#
# Parameters:
#   QUESTION - Question to ask
#   OPTIONS  - Space-separated options (minimum 2)
#
# Returns: Selected option (1-based index)
#
# Example:
#   CHOICE=$(prompt_select "Choose model:" "sonnet" "opus" "haiku")
################################################################################
prompt_select() {
  local QUESTION="$1"
  shift
  local OPTIONS=("$@")

  if [[ ${#OPTIONS[@]} -lt 2 ]]; then
    echo "❌ Error: prompt_select requires at least 2 options" >&2
    return 1
  fi

  echo ""
  echo "❓ $QUESTION"
  echo ""

  local i=1
  for option in "${OPTIONS[@]}"; do
    echo "   $i) $option"
    ((i++))
  done

  echo ""
  echo -n "   Select (1-${#OPTIONS[@]}): "

  local CHOICE=""
  while true; do
    read -r CHOICE

    # Validate numeric input
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ $CHOICE -ge 1 ]] && [[ $CHOICE -le ${#OPTIONS[@]} ]]; then
      break
    else
      echo "   Invalid choice. Please enter 1-${#OPTIONS[@]}: "
    fi
  done

  echo "$CHOICE"
}

################################################################################
# prompt_multiselect() - Present multi-choice menu
################################################################################
# Usage: prompt_multiselect QUESTION OPTION1 OPTION2 [OPTION3...]
#
# Parameters:
#   QUESTION - Question to ask
#   OPTIONS  - Space-separated options (minimum 2)
#
# Returns: Space-separated list of selected indices (1-based)
#
# Example:
#   CHOICES=$(prompt_multiselect "Select features:" "auth" "db" "api")
#   # User enters: 1 3
#   # Returns: "1 3"
################################################################################
prompt_multiselect() {
  local QUESTION="$1"
  shift
  local OPTIONS=("$@")

  if [[ ${#OPTIONS[@]} -lt 2 ]]; then
    echo "❌ Error: prompt_multiselect requires at least 2 options" >&2
    return 1
  fi

  echo ""
  echo "❓ $QUESTION"
  echo "   (enter space-separated numbers, e.g., '1 3 4')"
  echo ""

  local i=1
  for option in "${OPTIONS[@]}"; do
    echo "   $i) $option"
    ((i++))
  done

  echo ""
  echo -n "   Select: "

  local CHOICES=""
  while true; do
    read -r CHOICES

    # Validate all are numeric and in range
    local VALID=true
    for choice in $CHOICES; do
      if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ $choice -lt 1 ]] || [[ $choice -gt ${#OPTIONS[@]} ]]; then
        VALID=false
        break
      fi
    done

    if [[ "$VALID" == "true" && -n "$CHOICES" ]]; then
      break
    else
      echo "   Invalid choices. Please enter space-separated numbers (1-${#OPTIONS[@]}): "
    fi
  done

  echo "$CHOICES"
}

################################################################################
# prompt_confirm() - Simple yes/no confirmation
################################################################################
# Usage: prompt_confirm QUESTION [DEFAULT]
#
# Parameters:
#   QUESTION - Question to ask
#   DEFAULT  - Optional default ("y" or "n")
#
# Returns: 0 for yes, 1 for no
#
# Example:
#   if prompt_confirm "Enable code review?"; then
#     echo "Enabled"
#   fi
################################################################################
prompt_confirm() {
  local QUESTION="$1"
  local DEFAULT="${2:-}"
  local PROMPT="y/n"

  if [[ "$DEFAULT" == "y" ]]; then
    PROMPT="Y/n"
  elif [[ "$DEFAULT" == "n" ]]; then
    PROMPT="y/N"
  fi

  echo ""
  echo -n "❓ $QUESTION ($PROMPT): "

  local RESPONSE=""
  read -r RESPONSE

  # Use default if empty
  if [[ -z "$RESPONSE" && -n "$DEFAULT" ]]; then
    RESPONSE="$DEFAULT"
  fi

  # Normalize to lowercase
  RESPONSE=$(echo "$RESPONSE" | tr '[:upper:]' '[:lower:]')

  if [[ "$RESPONSE" == "y" || "$RESPONSE" == "yes" ]]; then
    return 0
  else
    return 1
  fi
}

################################################################################
# update_live_progress() - Send progress update to live server
################################################################################
# Usage: update_live_progress ITERATION MAX_ITERATIONS STATUS [MESSAGE]
#
# Parameters:
#   ITERATION      - Current iteration number
#   MAX_ITERATIONS - Maximum iterations
#   STATUS         - Status: "idle", "running", "complete"
#   MESSAGE        - Optional status message
#
# Sends JSON update to live server progress API if it's running
################################################################################
update_live_progress() {
  local ITERATION="$1"
  local MAX_ITERATIONS="$2"
  local STATUS="$3"
  local MESSAGE="${4:-}"

  # Only send if live server might be running
  if command -v curl >/dev/null 2>&1; then
    local TIMESTAMP=$(date +%s)000  # milliseconds
    local JSON_PAYLOAD=$(cat <<EOF
{
  "iteration": $ITERATION,
  "maxIterations": $MAX_ITERATIONS,
  "status": "$STATUS",
  "statusDetail": "$MESSAGE",
  "lastUpdate": "$MESSAGE",
  "timestamp": $TIMESTAMP
}
EOF
)

    # Send to live server (don't fail if server not running)
    curl -s -X POST \
      -H "Content-Type: application/json" \
      -d "$JSON_PAYLOAD" \
      http://localhost:3001/update >/dev/null 2>&1 || true
  fi
}

################################################################################
# prompt_user() - Main interactive prompt dispatcher
################################################################################
# Usage: prompt_user TYPE QUESTION [OPTIONS...]
#
# Parameters:
#   TYPE     - Prompt type: "text", "select", "multiselect", "confirm"
#   QUESTION - Question to ask user
#   OPTIONS  - Additional parameters based on type
#
# Features:
#   - Plays alert sound before prompting
#   - Speaks question if ENABLE_SPEECH=true
#   - Dispatches to appropriate prompt function
#
# Examples:
#   # Text input
#   NAME=$(prompt_user text "Enter your name:")
#
#   # Single select
#   MODEL=$(prompt_user select "Choose model:" "sonnet" "opus" "haiku")
#
#   # Multi select
#   FEATURES=$(prompt_user multiselect "Select features:" "auth" "db" "api")
#
#   # Confirmation
#   if prompt_user confirm "Enable code review?" "y"; then
#     echo "Enabled"
#   fi
################################################################################
prompt_user() {
  local TYPE="$1"
  local QUESTION="$2"
  shift 2
  local OPTIONS=("$@")

  # Play alert sound
  play_alert

  # Speak question if enabled
  speak_prompt "$QUESTION"

  # Dispatch to appropriate function
  case "$TYPE" in
    text)
      prompt_text "$QUESTION" "${OPTIONS[0]:-}"
      ;;
    select)
      prompt_select "$QUESTION" "${OPTIONS[@]}"
      ;;
    multiselect)
      prompt_multiselect "$QUESTION" "${OPTIONS[@]}"
      ;;
    confirm)
      prompt_confirm "$QUESTION" "${OPTIONS[0]:-}"
      ;;
    *)
      echo "❌ Error: Unknown prompt type '$TYPE'" >&2
      echo "   Valid types: text, select, multiselect, confirm" >&2
      return 1
      ;;
  esac
}
