#!/bin/bash
# AI Dr. Prompt Storage Hook
# Automatically stores user prompts with context for analysis and workflow generation
# Organizes prompts by date and archives previous days
#
# ARCHIVE EXTRACTION GUIDE:
# -------------------------
# Archives are stored in .ai-dr/prompts/archives/ as YYYY-MM-DD.tar.gz files
#
# To extract a specific day's prompts:
#   tar -xzf .ai-dr/prompts/archives/2025-08-15.tar.gz
#
# To extract to a specific location:
#   tar -xzf .ai-dr/prompts/archives/2025-08-15.tar.gz -C /path/to/extract/
#
# To view archive contents without extracting:
#   tar -tzf .ai-dr/prompts/archives/2025-08-15.tar.gz
#
# To extract a single file from archive:
#   tar -xzf .ai-dr/prompts/archives/2025-08-15.tar.gz 2025-08-15/prompt_20250815_120001.md
#
# To search within archived prompts without extracting:
#   tar -xzOf .ai-dr/prompts/archives/2025-08-15.tar.gz | grep "search term"

# Configuration
CURRENT_DIR=$(pwd)
BASE_STORAGE_DIR="$CURRENT_DIR/.ai-dr/prompts"
TODAY=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
ARCHIVE_DIR="$BASE_STORAGE_DIR/archives"

# Create date-based storage directory structure
STORAGE_DIR="$BASE_STORAGE_DIR/$TODAY"
mkdir -p "$STORAGE_DIR"
mkdir -p "$ARCHIVE_DIR"

# Read JSON input from stdin
input_json=$(cat)

# Extract values from JSON input using jq or fallback parsing
if command -v jq >/dev/null 2>&1; then
    user_prompt=$(echo "$input_json" | jq -r '.prompt // empty')
    session_id=$(echo "$input_json" | jq -r '.session_id // "unknown"')
    hook_cwd=$(echo "$input_json" | jq -r '.cwd // empty')
else
    # Fallback parsing without jq
    user_prompt=$(echo "$input_json" | grep -o '"prompt":"[^"]*"' | sed 's/"prompt":"//' | sed 's/"$//')
    session_id=$(echo "$input_json" | grep -o '"session_id":"[^"]*"' | sed 's/"session_id":"//' | sed 's/"$//')
    hook_cwd=$(echo "$input_json" | grep -o '"cwd":"[^"]*"' | sed 's/"cwd":"//' | sed 's/"$//')
fi

# Use hook cwd if available, otherwise current directory
if [ -n "$hook_cwd" ]; then
    CURRENT_DIR="$hook_cwd"
    # Update paths with new CURRENT_DIR
    BASE_STORAGE_DIR="$CURRENT_DIR/.ai-dr/prompts"
    STORAGE_DIR="$BASE_STORAGE_DIR/$TODAY"
    ARCHIVE_DIR="$BASE_STORAGE_DIR/archives"
    mkdir -p "$STORAGE_DIR"
    mkdir -p "$ARCHIVE_DIR"
fi

# Function to archive previous days' prompts
archive_old_prompts() {
    # Find all date directories (YYYY-MM-DD format) except today
    for date_dir in "$BASE_STORAGE_DIR"/*; do
        if [ -d "$date_dir" ]; then
            dir_name=$(basename "$date_dir")
            
            # Skip if it's today's directory or archives directory
            if [[ "$dir_name" == "$TODAY" ]] || [[ "$dir_name" == "archives" ]]; then
                continue
            fi
            
            # Check if it matches date format (YYYY-MM-DD)
            if [[ "$dir_name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                archive_file="$ARCHIVE_DIR/${dir_name}.tar.gz"
                
                # Only archive if not already archived
                if [ ! -f "$archive_file" ]; then
                    echo "📦 Archiving prompts from $dir_name..."
                    
                    # Get list of files before archiving
                    files_to_archive=()
                    while IFS= read -r -d '' file; do
                        files_to_archive+=("$file")
                    done < <(find "$date_dir" -type f -name "*.md" -print0)
                    
                    if [ ${#files_to_archive[@]} -gt 0 ]; then
                        # Create tar.gz archive
                        tar -czf "$archive_file" -C "$BASE_STORAGE_DIR" "$dir_name" 2>/dev/null
                        
                        if [ $? -eq 0 ]; then
                            # Verify archive was created and has content
                            if [ -f "$archive_file" ] && [ -s "$archive_file" ]; then
                                # Remove only the files that were archived, not the directory
                                for file in "${files_to_archive[@]}"; do
                                    rm -f "$file"
                                    echo "  ✓ Removed: $(basename "$file")"
                                done
                                
                                # Remove the directory only if it's empty
                                rmdir "$date_dir" 2>/dev/null && echo "  ✓ Removed empty directory: $dir_name"
                                
                                echo "✅ Archived $dir_name (${#files_to_archive[@]} files)"
                            else
                                echo "⚠️ Archive created but appears empty, keeping original files"
                                rm -f "$archive_file"
                            fi
                        else
                            echo "⚠️ Failed to archive: $dir_name"
                        fi
                    else
                        echo "  → No files to archive in $dir_name"
                        # Remove empty directory
                        rmdir "$date_dir" 2>/dev/null
                    fi
                fi
            fi
        fi
    done
    
    # Also migrate any loose prompt files in the base directory to today's folder
    for prompt_file in "$BASE_STORAGE_DIR"/prompt_*.md; do
        if [ -f "$prompt_file" ]; then
            filename=$(basename "$prompt_file")
            # Extract date from filename (format: prompt_YYYYMMDD_HHMMSS.md)
            file_date=$(echo "$filename" | sed -n 's/prompt_\([0-9]\{8\}\)_.*/\1/p')
            
            if [ -n "$file_date" ]; then
                # Convert YYYYMMDD to YYYY-MM-DD
                formatted_date="${file_date:0:4}-${file_date:4:2}-${file_date:6:2}"
                target_dir="$BASE_STORAGE_DIR/$formatted_date"
                
                # Create target directory and move file
                mkdir -p "$target_dir"
                mv "$prompt_file" "$target_dir/"
                echo "📁 Migrated $filename to $formatted_date/"
            fi
        fi
    done
}

# Function to extract and store prompt
store_prompt() {
    local prompt_file="$STORAGE_DIR/prompt_${TIMESTAMP}.md"
    
    # Create prompt file with metadata
    cat > "$prompt_file" << EOF
---
timestamp: $(date -Iseconds)
session_id: ${session_id}
project: $(basename "$CURRENT_DIR")
user: $(whoami)
---

# User Prompt

$user_prompt

## Context

**Working Directory:** $CURRENT_DIR
**Git Branch:** $(git branch --show-current 2>/dev/null || echo "not a git repo")
**Git Status:** 
\`\`\`
$(git status --porcelain 2>/dev/null || echo "not a git repo")
\`\`\`

**Recent Files Modified:**
\`\`\`
$(if command -v git &> /dev/null && [ -d ".git" ]; then
  # Use git to list files, which respects .gitignore
  git ls-files --modified --others --exclude-standard | while read -r file; do
    # Check if file was modified in last 24 hours
    if [ -f "$file" ] && [ $(find "$file" -mtime -1 2>/dev/null | wc -l) -gt 0 ]; then
      echo "$file"
    fi
  done | head -10
else
  # Fallback if git is not available
  find . -name "*.ts" -o -name "*.js" -o -name "*.md" -o -name "*.json" -mtime -1 -not -path "*/.git/*" -not -path "*/node_modules/*" -not -path "*/.ai-dr/*" 2>/dev/null | head -10
fi)
\`\`\`

**Todo Context:**
\`\`\`
$(if [ -f "$CURRENT_DIR/.ai-dr/todos/current.md" ]; then cat "$CURRENT_DIR/.ai-dr/todos/current.md"; else echo "No active todos"; fi)
\`\`\`

EOF

    echo "✅ Prompt stored: $prompt_file"
    
    # Trigger analysis if enabled
    if [ "$AI_DR_AUTO_ANALYSIS" = "true" ]; then
        echo "🔄 Triggering prompt analysis..."
        # This would call our analysis system
        # For now, just log that it would happen
        echo "📝 Analysis queued for: $prompt_file"
    fi
}

# Archive old prompts first (runs once per day when first prompt is stored)
archive_old_prompts

# Store the prompt if we have user input
if [ -n "$user_prompt" ]; then
    store_prompt
fi

# Optional: Send notification
# if command -v osascript >/dev/null 2>&1; then
#     osascript -e "display notification \"Prompt stored for AI Dr. analysis\" with title \"AI Dr. Hook\""
# elif command -v notify-send >/dev/null 2>&1; then
#     notify-send "AI Dr. Hook" "Prompt stored for analysis"
# fi