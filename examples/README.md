# Examples

Demonstrations of While Loopin' Claude usage patterns.

## Quick Reference

| Example | Complexity | Code Review | Description |
|---------|-----------|-------------|-------------|
| [simple-task.md](./simple-task.md) | Low | No | Basic file creation task |
| [bug-fix.md](./bug-fix.md) | Medium | Yes | Fix bug with quality checks |

## Running Examples

Each example is a markdown file that serves as both documentation and a runnable prompt:

```bash
# Run directly
bun run agent "$(cat examples/simple-task.md)"

# With code review
ENABLE_CODE_REVIEW=true bun run agent "$(cat examples/bug-fix.md)"

# With custom config
MAX_ITERATIONS=20 ENABLE_SPEECH=true bun run agent "$(cat examples/simple-task.md)"
```

## What Examples Demonstrate

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
