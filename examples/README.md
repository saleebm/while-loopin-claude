# Examples

Demonstrations of While Loopin' Claude usage patterns.

## Quick Reference

| Example | Type | Description |
|---------|------|-------------|
| [simple-task.md](./simple-task.md) | Prompt | Basic file creation task |
| [bug-fix.md](./bug-fix.md) | Prompt | Fix bug with quality checks |
| [color-art-app/](./color-art-app/) | Live App | 🚀 Visual app with live browser preview |
| [test-interactive-prompts.sh](./test-interactive-prompts.sh) | Script | Test suite for interactive prompts |
| [interactive-agent-config.sh](./interactive-agent-config.sh) | Script | Interactive configuration wizard |

## Running Examples

### 🚀 Live Development Mode (RECOMMENDED!)

**Maximum dopamine delivery!** Watch Claude build in real-time with live browser preview:

```bash
# Color art app with live preview
bash examples/color-art-app/run-agent-live.sh
```

**What you get:**
- 🌐 Auto-opens browser with your app
- 📊 Real-time progress overlay showing Claude's work
- 🔄 Instant auto-reload when files change
- ✨ Beautiful animations and visual feedback

See [color-art-app/LIVE-DEVELOPMENT.md](./color-art-app/LIVE-DEVELOPMENT.md) for full details!

### Prompt Examples

Each markdown file serves as both documentation and a runnable prompt:

```bash
# Run directly
bun run agent "$(cat examples/simple-task.md)"

# With code review
ENABLE_CODE_REVIEW=true bun run agent "$(cat examples/bug-fix.md)"

# With custom config
MAX_ITERATIONS=20 ENABLE_SPEECH=true bun run agent "$(cat examples/simple-task.md)"
```

### Interactive Prompt Examples

Test and explore the interactive prompt system:

```bash
# Test all prompt types
bash examples/test-interactive-prompts.sh

# Test with speech enabled
ENABLE_SPEECH=true bash examples/test-interactive-prompts.sh

# Interactive configuration wizard
bash examples/interactive-agent-config.sh
```

## What Examples Demonstrate

### color-art-app/
- **Live browser preview** with auto-reload
- **Real-time progress overlay** showing agent status
- Visual feedback for maximum engagement
- Auto-opening browser on agent start
- WebSocket-based live updates
- See [LIVE-DEVELOPMENT.md](./color-art-app/LIVE-DEVELOPMENT.md) for architecture details

### simple-task.md
- Minimal agent setup
- File creation
- Basic handoff format
- Completion detection

### bug-fix.md
- Bug fixing workflow
- Code review integration
- Test creation
- Quality validation

### test-interactive-prompts.sh
- All interactive prompt types (text, select, multiselect, confirm)
- Alert sound integration
- Speech output support
- Input validation
- Result display

### interactive-agent-config.sh
- Building configuration wizards
- Chaining prompts logically
- Conditional prompts
- Converting selections to config
- Final confirmation pattern

## Creating Your Own

Use examples as templates:

1. Copy example file
2. Modify task description
3. Update completion criteria
4. Adjust expected outputs
5. Run with `bun run agent`

Or create plain text prompts:

```bash
# Direct prompt
bun run agent "Your task description here"

# From file
echo "Your task" > task.txt
bun run agent task.txt
```

## Expected Outcomes

After running examples, you should see:

```
.specs/{example-name}/
├── AGENT-PROMPT.md    # AI-enhanced prompt
├── HANDOFF.md         # Final status
├── analysis.json      # Configuration
└── README.md          # Navigation

.ai-dr/agent-runs/{example-name}/
├── iteration_*.log    # Agent outputs
└── reviews/           # (if code review enabled)

src/                   # Created files
└── ...
```

## Next Steps

After running examples:

1. Review `.specs/{example-name}/HANDOFF.md` for status
2. Check `.ai-dr/agent-runs/{example-name}/` for detailed logs
3. Verify created files match expectations
4. Examine `analysis.json` to see AI reasoning

## Troubleshooting

**Agent doesn't stop:**
- Check handoff includes "Session End" marker
- Verify status is "complete"
- Review iteration logs for errors

**Files not created:**
- Check agent has write permissions
- Review error messages in iteration logs
- Verify working directory is correct

**Code review fails:**
- Ensure lint/typecheck scripts exist
- Check review template exists
- Review lint/typecheck output logs

See `../CLAUDE.md` for more troubleshooting guidance.
