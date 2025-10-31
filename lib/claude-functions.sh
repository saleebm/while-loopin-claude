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
