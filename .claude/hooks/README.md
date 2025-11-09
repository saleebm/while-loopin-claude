# Claude Code Hooks

This directory contains safety and utility hooks for Claude Code that enhance its
behavior and prevent dangerous operations.

## Overview

Claude Code hooks are scripts that intercept tool operations to:
- Prevent accidental data loss
- Enforce best practices
- Manage context size
- Send notifications
- Track operation state

## Setup

1. Make hook scripts executable:
   ```bash
   chmod +x hooks/*.py hooks/*.sh
   ```

2. Add hooks to your global Claude settings:
   - Open or create `~/.claude/settings.json`
   - Copy the entire "hooks" section from `settings.sample.json`
   - Replace all instances of `/path/to/claude-code-tools` with your actual repository path
   
3. If you already have other settings in `~/.claude/settings.json`, merge the hooks section:
   ```json
   {
     "hooks": { 
       // ... content from settings.sample.json ...
     },
     // ... your other settings ...
   }
   ``` 

## Hook Types

### Notification Hooks

Triggered for various events to send notifications.

### PreToolUse Hooks

Triggered before a tool executes. Can block operations by returning non-zero exit
codes with error messages.

### PostToolUse Hooks

Triggered after a tool completes. Used for cleanup and state management.

## Available Hooks

### 1. notification_hook.sh

**Type:** Notification  
**Purpose:** Send notifications to ntfy.sh channel  
**Behavior:**
- Reads JSON input and extracts the 'message' field
- Sends notification to ntfy.sh/cc-alerts channel
- Never blocks operations

**Configuration:** Update the ntfy.sh URL in the script if using a different
channel.

### 2. bash_hook.py

**Type:** PreToolUse (Bash)  
**Purpose:** Unified safety checks for bash commands  
**Blocks:**
- `rm` commands (enforces TRASH directory pattern)
- Dangerous `git add` patterns (`-A`, `--all`, `.`, `*`)
- Unsafe `git checkout` operations
- Commands that could cause data loss

**Features:**
- Combines multiple safety checks
- Provides helpful alternative suggestions
- Prevents accidental file deletion and git mishaps

### 3. file_size_conditional_hook.py

**Type:** PreToolUse (Read)  
**Purpose:** Prevent reading large files that bloat context  
**Behavior:**
- Main agent: Blocks files > 500 lines
- Sub-agents: Blocks files > 10,000 lines
- Binary files are always allowed
- Considers offset/limit parameters

**Suggestions:**
- Use sub-agents for large file analysis
- Use grep/search tools for specific content
- Consider external tools for very large files

### 4. pretask_subtask_flag.py & posttask_subtask_flag.py

**Type:** PreToolUse/PostToolUse (Task)  
**Purpose:** Track sub-agent execution state  
**Behavior:**
- Pre: Creates `.claude_in_subtask.flag` file
- Post: Removes the flag file
- Enables different behavior for sub-agents (like larger file limits)

### 5. grep_block_hook.py

**Type:** PreToolUse (Grep)  
**Purpose:** Enforce use of ripgrep over grep  
**Behavior:**
- Always blocks grep commands
- Suggests using `rg` (ripgrep) instead
- Ensures better performance and features

## Safety Features

### Git Safety

The bash hook includes comprehensive git safety:

**Blocked Commands:**
- `git add -A`, `git add --all`, `git add .`
- `git commit -a` without message
- `git checkout -f`, `git checkout .`
- Operations that could lose uncommitted changes

**Git Commit Speed Bump:**
- First `git commit` attempt is blocked with a reminder about user approval
- If the user requires approval before commits, do NOT retry
- If approval isn't needed or was already given, retry to proceed
- Uses `.claude_git_commit_warning.flag` file to track state
- Second attempt always succeeds (flag is cleared)

**Alternatives Suggested:**
- `git add -u` for modified files
- `git add <specific-files>` for targeted staging
- `git stash` before dangerous operations
- `git switch` for branch changes

### File Deletion Safety

**Instead of `rm`:**
- Move files to `TRASH/` directory
- Document in `TRASH-FILES.md` with reason
- Preserves ability to recover files

Example:
```bash
# Instead of: rm unwanted.txt
mv unwanted.txt TRASH/
echo "unwanted.txt - moved to TRASH/ - no longer needed" >> TRASH-FILES.md
```

### Context Management

The file size hook prevents Claude from reading huge files that would:
- Consume excessive context
- Slow down processing
- Potentially cause errors

## Customization

### Adding New Hooks

1. Create your hook script in the `hooks/` directory
2. Add it to your `settings.json`:
   ```json
   {
     "matcher": "ToolName",
     "hooks": [{
       "type": "command",
       "command": "$CLAUDE_CODE_TOOLS_PATH/hooks/your_hook.py"
     }]
   }
   ```

### Hook Return Codes

- `0`: Allow operation to proceed
- Non-zero: Block operation (error message goes to stderr)

### Hook Input/Output

Hooks receive:
- Tool parameters as JSON on stdin
- Environment variables with context

Hooks output:
- Approval/rejection via exit code
- Error messages to stderr
- Logs to stdout (not shown to user)

## Best Practices

1. **Make hooks fast** - They run synchronously before operations
2. **Provide helpful errors** - Explain why operations are blocked
3. **Suggest alternatives** - Help users accomplish their goals safely
4. **Log for debugging** - Use stdout for diagnostic information
5. **Test thoroughly** - Hooks can significantly impact Claude's behavior

## Troubleshooting

### Hooks not triggering

- Verify `settings.json` is in the correct location
- Check file permissions (`chmod +x`)
- Ensure paths use `$CLAUDE_CODE_TOOLS_PATH`
- Test with `echo` statements to debug

### Operations being blocked unexpectedly

- Check hook logic for edge cases
- Review blocking conditions
- Add logging to understand decisions
- Consider making hooks more permissive for sub-agents

### Performance issues

- Hooks run synchronously - keep them fast
- Avoid network calls in hooks
- Cache results when possible
- Consider async notifications post-operation
