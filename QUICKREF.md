# Quick Reference

Concise command reference for While Loopin' Claude.

## Installation

```bash
# Copy to project
cp -r lib /path/to/project/.specs/_shared/
mkdir -p /path/to/project/.ai-dr/{prompts,agent-runs}

# Add to package.json
{
  "scripts": {
    "agent": "bash .specs/_shared/smart-agent.sh"
  }
}
```

## Basic Usage

```bash
# Run with inline prompt
bun run agent "Fix the login bug"

# Run with prompt file
bun run agent plan.txt

# Direct execution (no bun)
bash .specs/_shared/smart-agent.sh "Your prompt"
```

## Configuration

```bash
# Enable code review
ENABLE_CODE_REVIEW=true bun run agent "Your prompt"

# Set max iterations
MAX_ITERATIONS=20 bun run agent "Your prompt"

# Enable speech (macOS)
ENABLE_SPEECH=true bun run agent "Your prompt"

# Adjust rate limiting
RATE_LIMIT_SECONDS=30 bun run agent "Your prompt"

# Combine options
ENABLE_CODE_REVIEW=true MAX_ITERATIONS=15 bun run agent "Your prompt"
```

## File Locations

```
.specs/{feature-name}/
├── AGENT-PROMPT.md      # Enhanced prompt
├── HANDOFF.md           # Status and handoff
├── analysis.json        # AI configuration
└── README.md            # Navigation

.ai-dr/agent-runs/{feature-name}/
├── iteration_*.log      # Agent outputs
└── reviews/             # Review outputs
    ├── review_*.log
    ├── review_*.json
    ├── fix_*.log
    ├── lint_*.log
    └── typecheck_*.log
```

## Handoff Format

```markdown
# Agent Handoff

## Session End
Status: complete

## Current State
[What's working/broken]

## Next Steps
1. [Action items]

## Findings
[Critical discoveries]
```

**Critical:** Must include "Session End" marker and Status for agent to stop.

## Common Tasks

### Simple File Creation
```bash
bun run agent "Create src/utils.ts with helper functions"
```

### Bug Fix
```bash
bun run agent "Fix TypeError in getUserData function"
```

### Feature Implementation
```bash
bun run agent "Add dark mode toggle to settings page"
```

### Refactoring
```bash
bun run agent "Refactor authentication module to use async/await"
```

### With Code Review
```bash
ENABLE_CODE_REVIEW=true bun run agent "Implement user registration"
```

## Debugging

### Check Agent Status
```bash
# View latest handoff
cat .specs/{feature-name}/HANDOFF.md

# View latest iteration
ls -lt .ai-dr/agent-runs/{feature-name}/ | head
tail .ai-dr/agent-runs/{feature-name}/iteration_*.log
```

### Verify Setup
```bash
# Test scripts are executable
bash -n .specs/_shared/agent-runner.sh
bash -n .specs/_shared/smart-agent.sh

# Check permissions
ls -la .specs/_shared/
```

### Common Issues

**Agent doesn't stop:**
- Check handoff has "Session End" marker
- Verify Status is "complete"

**"Command not found: claude":**
```bash
npm install -g @anthropic/claude-cli
```

**"Command not found: jq":**
```bash
brew install jq  # macOS
apt install jq   # Linux
```

**Permission denied:**
```bash
chmod +x .specs/_shared/*.sh
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| ENABLE_CODE_REVIEW | false | Run code review after main loop |
| MAX_CODE_REVIEWS | 5 | Max review iterations |
| MAX_ITERATIONS | 10 | Max agent iterations |
| ENABLE_SPEECH | false | Enable macOS speech feedback |
| RATE_LIMIT_SECONDS | 15 | Delay between iterations |

## Direct Function Usage

```bash
# Source the library
source .specs/_shared/agent-runner.sh

# Run agent with custom config
run_claude_agent \
  "$PROMPT_FILE" \
  "$HANDOFF_FILE" \
  "$OUTPUT_DIR" \
  10 \
  --enable-code-review

# Run Claude command
run_claude "Your prompt" "output.log" "sonnet"

# Generate structured output
RESULT=$(generate_structured_output "output.log" '{"extra": "data"}')
```

## Documentation Map

- `README.md` - Full usage guide and architecture
- `CLAUDE.md` - Development best practices
- `INSTALL.md` - Installation instructions
- `SUMMARY.md` - Setup verification
- `QUICKREF.md` - This file
- `examples/` - Runnable examples
- `templates/` - Reusable templates

## Examples

```bash
# Simple task
bun run agent "$(cat examples/simple-task.md)"

# Bug fix with review
ENABLE_CODE_REVIEW=true bun run agent "$(cat examples/bug-fix.md)"
```
