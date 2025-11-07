#!/usr/bin/env bash

# Reusable Context File Management Functions
# Source this file to use context management utilities

set -euo pipefail

################################################################################
# sanitize_path() - Sanitize file paths to prevent path traversal attacks
################################################################################
# Usage: sanitize_path PATH
#
# Parameters:
#   PATH - File or directory path to sanitize
#
# Returns: 0 on success (safe path), 1 if path is potentially malicious
# Prints: Sanitized absolute path to stdout
################################################################################
sanitize_path() {
  local INPUT_PATH="$1"

  if [[ -z "$INPUT_PATH" ]]; then
    echo "❌ Error: Empty path provided"
    return 1
  fi

  # Check for path traversal patterns
  if [[ "$INPUT_PATH" =~ \.\./|\.\.\\ ]]; then
    echo "❌ Error: Path traversal detected in: $INPUT_PATH"
    return 1
  fi

  # Check for null bytes
  if [[ "$INPUT_PATH" =~ $'\0' ]]; then
    echo "❌ Error: Null byte detected in path: $INPUT_PATH"
    return 1
  fi

  # Resolve to absolute path to prevent relative path exploits
  # If path doesn't exist yet, get absolute path of parent directory
  if [[ -e "$INPUT_PATH" ]]; then
    local RESOLVED_PATH
    if RESOLVED_PATH="$(cd "$(dirname "$INPUT_PATH")" && pwd)/$(basename "$INPUT_PATH")" 2>/dev/null; then
      echo "$RESOLVED_PATH"
      return 0
    else
      echo "❌ Error: Failed to resolve path: $INPUT_PATH"
      return 1
    fi
  else
    # For non-existent paths, validate the parent directory
    local PARENT_DIR
    PARENT_DIR="$(dirname "$INPUT_PATH")"
    local BASENAME
    BASENAME="$(basename "$INPUT_PATH")"

    # Ensure basename doesn't contain path separators
    if [[ "$BASENAME" =~ / ]]; then
      echo "❌ Error: Invalid filename in path: $INPUT_PATH"
      return 1
    fi

    # Convert to absolute path
    if [[ "$INPUT_PATH" == /* ]]; then
      # Already absolute
      echo "$INPUT_PATH"
      return 0
    else
      # Make absolute relative to current directory
      echo "$(pwd)/$INPUT_PATH"
      return 0
    fi
  fi
}

################################################################################
# ensure_context_directory() - Create context directory if it doesn't exist
################################################################################
# Usage: ensure_context_directory CONTEXT_DIR
#
# Parameters:
#   CONTEXT_DIR - Path to context directory
#
# Returns: 0 on success, 1 on failure
################################################################################
ensure_context_directory() {
  local CONTEXT_DIR="$1"

  if [[ -z "$CONTEXT_DIR" ]]; then
    echo "❌ Error: CONTEXT_DIR not provided"
    return 1
  fi

  # Sanitize path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$CONTEXT_DIR"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  CONTEXT_DIR="$SAFE_PATH"

  if [[ ! -d "$CONTEXT_DIR" ]]; then
    if ! mkdir -p "$CONTEXT_DIR" 2>/dev/null; then
      echo "❌ Error: Failed to create context directory: $CONTEXT_DIR"
      echo "   Please check directory permissions and try again"
      return 1
    fi
    echo "   📁 Created context directory: $CONTEXT_DIR"
  fi

  return 0
}

################################################################################
# init_context_file() - Initialize a context file with template content
################################################################################
# Usage: init_context_file FILE_PATH TEMPLATE_TYPE
#
# Parameters:
#   FILE_PATH      - Path to the context file to create
#   TEMPLATE_TYPE  - Type of template (instructions, progress, findings, achievements)
#
# Returns: 0 on success, 1 on failure
################################################################################
init_context_file() {
  local FILE_PATH="$1"
  local TEMPLATE_TYPE="$2"

  # Sanitize file path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$FILE_PATH"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  FILE_PATH="$SAFE_PATH"

  if [[ -f "$FILE_PATH" ]]; then
    # File already exists, don't overwrite
    return 0
  fi

  case "$TEMPLATE_TYPE" in
    instructions)
      cat > "$FILE_PATH" <<'EOF'
# Phase Instructions

## Current Phase
[To be filled by agent]

## Complete Instructions
[To be filled by agent]

## Constraints
[To be filled by agent]

## Success Criteria
[To be filled by agent]

## Last Updated
[To be filled by agent]
EOF
      ;;
    progress)
      cat > "$FILE_PATH" <<'EOF'
# Progress Tracking

## Milestones
- [ ] [To be filled by agent]

## Current Status
[To be filled by agent]

## Completed Actions
[To be filled by agent]

## Next Steps
[To be filled by agent]

## Blockers
[To be filled by agent]

## Last Updated
[To be filled by agent]
EOF
      ;;
    findings)
      cat > "$FILE_PATH" <<'EOF'
# Findings and Insights

## Key Discoveries
[To be filled by agent]

## Thought Process
[To be filled by agent]

## Questions and Answers
[To be filled by agent]

## Learnings
[To be filled by agent]

## Last Updated
[To be filled by agent]
EOF
      ;;
    achievements)
      cat > "$FILE_PATH" <<'EOF'
# Achievements and Validation

## Recent Achievements
[To be filled by agent]

## Quality Metrics
[To be filled by agent]

## Last Updated
[To be filled by agent]
EOF
      ;;
    *)
      echo "❌ Error: Unknown template type: $TEMPLATE_TYPE"
      return 1
      ;;
  esac

  return 0
}

################################################################################
# ensure_context_files() - Ensure all context files exist
################################################################################
# Usage: ensure_context_files CONTEXT_DIR
#
# Parameters:
#   CONTEXT_DIR - Path to context directory
#
# Returns: 0 on success, 1 on failure
################################################################################
ensure_context_files() {
  local CONTEXT_DIR="$1"

  # Sanitize path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$CONTEXT_DIR"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  CONTEXT_DIR="$SAFE_PATH"

  if ! ensure_context_directory "$CONTEXT_DIR"; then
    return 1
  fi

  local FILES_CREATED=0

  # Create each context file if it doesn't exist
  if [[ ! -f "$CONTEXT_DIR/instructions.md" ]]; then
    init_context_file "$CONTEXT_DIR/instructions.md" "instructions"
    echo "   📝 Created instructions.md"
    FILES_CREATED=$((FILES_CREATED + 1))
  fi

  if [[ ! -f "$CONTEXT_DIR/progress.md" ]]; then
    init_context_file "$CONTEXT_DIR/progress.md" "progress"
    echo "   📊 Created progress.md"
    FILES_CREATED=$((FILES_CREATED + 1))
  fi

  if [[ ! -f "$CONTEXT_DIR/findings.md" ]]; then
    init_context_file "$CONTEXT_DIR/findings.md" "findings"
    echo "   🔍 Created findings.md"
    FILES_CREATED=$((FILES_CREATED + 1))
  fi

  if [[ ! -f "$CONTEXT_DIR/achievements.md" ]]; then
    init_context_file "$CONTEXT_DIR/achievements.md" "achievements"
    echo "   ✅ Created achievements.md"
    FILES_CREATED=$((FILES_CREATED + 1))
  fi

  if [[ $FILES_CREATED -gt 0 ]]; then
    echo "   📁 Context files initialized in: $CONTEXT_DIR"
  fi

  return 0
}

################################################################################
# read_context() - Read a specific context file
################################################################################
# Usage: read_context CONTEXT_DIR FILE_TYPE
#
# Parameters:
#   CONTEXT_DIR - Path to context directory
#   FILE_TYPE   - Type of context file (instructions, progress, findings, achievements)
#
# Returns: 0 on success, 1 on failure, prints content to stdout
################################################################################
read_context() {
  local CONTEXT_DIR="$1"
  local FILE_TYPE="$2"

  # Sanitize context directory
  local SAFE_DIR
  if ! SAFE_DIR=$(sanitize_path "$CONTEXT_DIR"); then
    echo "$SAFE_DIR"  # Print error message from sanitize_path
    return 1
  fi

  # Validate file type to prevent injection
  case "$FILE_TYPE" in
    instructions|progress|findings|achievements)
      ;;
    *)
      echo "❌ Error: Invalid file type: $FILE_TYPE"
      return 1
      ;;
  esac

  local FILE_PATH="$SAFE_DIR/${FILE_TYPE}.md"

  if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ Error: Context file not found: $FILE_PATH"
    return 1
  fi

  cat "$FILE_PATH"
  return 0
}

################################################################################
# update_context_timestamp() - Update the "Last Updated" timestamp in a context file
################################################################################
# Usage: update_context_timestamp FILE_PATH
#
# Parameters:
#   FILE_PATH - Path to the context file
#
# Returns: 0 on success, 1 on failure
################################################################################
update_context_timestamp() {
  local FILE_PATH="$1"
  local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  # Sanitize file path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$FILE_PATH"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  FILE_PATH="$SAFE_PATH"

  if [[ ! -f "$FILE_PATH" ]]; then
    echo "❌ Error: File not found: $FILE_PATH"
    return 1
  fi

  # Validate timestamp format to prevent injection (YYYY-MM-DD HH:MM:SS)
  if [[ ! "$TIMESTAMP" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]]; then
    echo "❌ Error: Invalid timestamp format: $TIMESTAMP"
    return 1
  fi

  # Update the Last Updated section
  if grep -q "## Last Updated" "$FILE_PATH"; then
    # Use sed to update the line after "## Last Updated"
    local SED_ERROR
    local SED_RESULT
    if [[ "$(uname)" == "Darwin" ]]; then
      # macOS sed syntax - escape timestamp for use in sed
      # Note: stderr is captured for error reporting, not suppressed
      SED_ERROR=$(sed -i '' "/## Last Updated/,/^$/ {
        /## Last Updated/n
        s/.*/Last updated: $TIMESTAMP/
      }" "$FILE_PATH" 2>&1)
      SED_RESULT=$?

      if [[ $SED_RESULT -ne 0 ]]; then
        # If sed pattern doesn't work, try simpler fallback
        SED_ERROR=$(sed -i '' "s/## Last Updated.*/## Last Updated\nLast updated: $TIMESTAMP/" "$FILE_PATH" 2>&1)
        SED_RESULT=$?

        if [[ $SED_RESULT -ne 0 ]]; then
          echo "❌ Error: Failed to update timestamp in $FILE_PATH"
          echo "   sed error: $SED_ERROR"
          return 1
        fi
      fi
    else
      # Linux sed syntax - escape timestamp for use in sed
      # Note: stderr is captured for error reporting, not suppressed
      SED_ERROR=$(sed -i "/## Last Updated/,/^$/ {
        /## Last Updated/n
        s/.*/Last updated: $TIMESTAMP/
      }" "$FILE_PATH" 2>&1)
      SED_RESULT=$?

      if [[ $SED_RESULT -ne 0 ]]; then
        # If sed pattern doesn't work, try simpler fallback
        SED_ERROR=$(sed -i "s/## Last Updated.*/## Last Updated\nLast updated: $TIMESTAMP/" "$FILE_PATH" 2>&1)
        SED_RESULT=$?

        if [[ $SED_RESULT -ne 0 ]]; then
          echo "❌ Error: Failed to update timestamp in $FILE_PATH"
          echo "   sed error: $SED_ERROR"
          return 1
        fi
      fi
    fi
  else
    echo "⚠️  Warning: No '## Last Updated' section found in $FILE_PATH"
    return 1
  fi

  return 0
}

################################################################################
# check_context_files_updated() - Check if context files have been updated by agent
################################################################################
# Usage: check_context_files_updated CONTEXT_DIR
#
# Parameters:
#   CONTEXT_DIR - Path to context directory
#
# Returns: 0 if files appear updated, 1 if they still have template content
################################################################################
check_context_files_updated() {
  local CONTEXT_DIR="$1"

  # Sanitize path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$CONTEXT_DIR"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  CONTEXT_DIR="$SAFE_PATH"

  local NOT_UPDATED=0

  for FILE in instructions.md progress.md findings.md achievements.md; do
    if [[ -f "$CONTEXT_DIR/$FILE" ]]; then
      # Check if file still contains placeholder text
      if grep -q "\[To be filled by agent\]" "$CONTEXT_DIR/$FILE" 2>/dev/null; then
        echo "   ⚠️  $FILE still contains template placeholders"
        NOT_UPDATED=$((NOT_UPDATED + 1))
      fi
    fi
  done

  if [[ $NOT_UPDATED -gt 0 ]]; then
    echo "   ℹ️  $NOT_UPDATED context file(s) not yet updated by agent"
    return 1
  fi

  return 0
}

################################################################################
# get_context_summary() - Generate a brief summary of context files status
################################################################################
# Usage: get_context_summary CONTEXT_DIR
#
# Parameters:
#   CONTEXT_DIR - Path to context directory
#
# Returns: 0 on success, prints summary to stdout
################################################################################
get_context_summary() {
  local CONTEXT_DIR="$1"

  # Sanitize path to prevent path traversal attacks
  local SAFE_PATH
  if ! SAFE_PATH=$(sanitize_path "$CONTEXT_DIR"); then
    echo "$SAFE_PATH"  # Print error message from sanitize_path
    return 1
  fi
  CONTEXT_DIR="$SAFE_PATH"

  if [[ ! -d "$CONTEXT_DIR" ]]; then
    echo "No context directory found"
    return 0
  fi

  echo "Context Files Summary:"
  for FILE in instructions.md progress.md findings.md achievements.md; do
    if [[ -f "$CONTEXT_DIR/$FILE" ]]; then
      local SIZE=$(wc -c < "$CONTEXT_DIR/$FILE")
      local LINES=$(wc -l < "$CONTEXT_DIR/$FILE")
      echo "  - $FILE: $LINES lines, $SIZE bytes"
    else
      echo "  - $FILE: NOT FOUND"
    fi
  done

  return 0
}
