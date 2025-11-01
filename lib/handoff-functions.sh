#!/usr/bin/env bash

# Handoff generation and orchestration helpers
# Requires: jq, claude CLI

set -euo pipefail

# Generate handoff decision prompt combining iteration output and prior handoff
# Usage: generate_handoff_prompt OUTPUT_FILE PRIOR_HANDOFF_FILE TEMPLATE_PATH
generate_handoff_prompt() {
  local OUTPUT_FILE="$1"
  local PRIOR_HANDOFF_FILE="$2"
  local TEMPLATE_PATH="$3"

  local TEMPLATE_CONTENT=""
  if [[ -n "$TEMPLATE_PATH" && -f "$TEMPLATE_PATH" ]]; then
    TEMPLATE_CONTENT=$(cat "$TEMPLATE_PATH")
  else
    TEMPLATE_CONTENT="# Handoff Decision & Draft

You are an autonomous agent coordinator. Decide whether to create/update a handoff.
If a handoff is created, include:
- Summary of work completed
- Outstanding tasks / next steps
- Issues found (with brief context)
- Clear status line: 'Status: <complete|in_progress|blocked>'
- A literal line 'Session End' at the end of the document
"
  fi

  local PRIOR_HANDOFF_CONTENT="(none)"
  if [[ -f "$PRIOR_HANDOFF_FILE" ]]; then
    PRIOR_HANDOFF_CONTENT=$(cat "$PRIOR_HANDOFF_FILE")
  fi

  cat <<EOF
$TEMPLATE_CONTENT

## Previous Iteration Output
$(cat "$OUTPUT_FILE" 2>/dev/null || echo "(missing output)")

## Prior Handoff (optional)
$PRIOR_HANDOFF_CONTENT

## Required JSON (return ONLY JSON)
{
  "should_create": true,
  "end_session": false,
  "status": "in_progress",
  "handoff_markdown": "# Agent Handoff\n\n## Status\nIn Progress\n\n## Work Completed\n- ...\n\n## Next Steps\n- ...\n\n## Issues Found\n- ...\n\nSession End\n"
}
EOF
}

# Decide whether to create handoff and return JSON
# Usage: decide_handoff PROMPT ITERATION DECISION_DIR
decide_handoff() {
  local PROMPT="$1"
  local ITERATION="$2"
  local DECISION_DIR="$3"

  mkdir -p "$DECISION_DIR"

  # Use shared JSON helper
  local RESULT
  RESULT=$(run_claude_json "$PROMPT" "haiku")

  # Validate JSON, fallback to minimal structure
  if ! echo "$RESULT" | jq empty 2>/dev/null; then
    RESULT='{"should_create":true,"end_session":false,"status":"in_progress","handoff_markdown":"Session End\nStatus: in_progress\n"}'
  fi

  echo "$RESULT" | jq '.' > "$DECISION_DIR/handoff_decision_${ITERATION}.json"
  echo "$RESULT"
}

# Write handoff markdown to file (overwrite)
# Usage: write_handoff HANDOFF_FILE MARKDOWN
write_handoff() {
  local HANDOFF_FILE="$1"
  local MARKDOWN="$2"
  mkdir -p "$(dirname "$HANDOFF_FILE")"
  printf "%s\n" "$MARKDOWN" > "$HANDOFF_FILE"
}

# Ensure the handoff exists for the iteration and is well-formed
# Usage: ensure_handoff OUTPUT_FILE HANDOFF_FILE PROJECT_DIR ITERATION RUN_OUTPUT_DIR HANDOFF_MODE HANDOFF_TEMPLATE
ensure_handoff() {
  local OUTPUT_FILE="$1"
  local HANDOFF_FILE="$2"
  local PROJECT_DIR="$3"
  local ITERATION="$4"
  local RUN_OUTPUT_DIR="$5"
  local HANDOFF_MODE="${6:-auto}"
  local HANDOFF_TEMPLATE="${7:-}"

  case "$HANDOFF_MODE" in
    off)
      echo "   ℹ️  Handoff mode: off (skipping)"
      return 0
      ;;
    manual)
      echo "   ℹ️  Handoff mode: manual (not auto-generating)"
      return 0
      ;;
    auto|*) ;;
  esac

  echo "   📝 Evaluating handoff creation..."

  local PROMPT
  PROMPT=$(generate_handoff_prompt "$OUTPUT_FILE" "$HANDOFF_FILE" "$HANDOFF_TEMPLATE")

  local DECISION_JSON
  DECISION_JSON=$(decide_handoff "$PROMPT" "$ITERATION" "$RUN_OUTPUT_DIR")

  local SHOULD_CREATE=$(echo "$DECISION_JSON" | jq -r '.should_create // true')
  local END_SESSION=$(echo "$DECISION_JSON" | jq -r '.end_session // false')
  local STATUS=$(echo "$DECISION_JSON" | jq -r '.status // "in_progress"')
  local HANDOFF_MD=$(echo "$DECISION_JSON" | jq -r '.handoff_markdown // ""')

  # Fallback stub if none provided
  if [[ -z "$HANDOFF_MD" ]] || [[ "$SHOULD_CREATE" != "true" ]]; then
    HANDOFF_MD="# Agent Handoff\n\n## Status\n${STATUS}\n\n## Notes\nAuto-generated minimal handoff for iteration ${ITERATION}.\n\nSession End\n"
  fi

  # Ensure required markers
  if ! echo "$HANDOFF_MD" | grep -q '^Session End\b'; then
    HANDOFF_MD+=$'\nSession End\n'
  fi
  if ! echo "$HANDOFF_MD" | grep -qi '^Status:'; then
    HANDOFF_MD+=$"Status: ${STATUS}\n"
  fi

  write_handoff "$HANDOFF_FILE" "$HANDOFF_MD"

  echo "   ✅ Handoff updated: $HANDOFF_FILE"
  echo "   📄 Decision JSON: $RUN_OUTPUT_DIR/handoff_decision_${ITERATION}.json"
}


