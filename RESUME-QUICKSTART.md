# Resume Feature - Quick Start

## What Was Fixed

### Critical Bug Fix
The agent no longer crashes with "unbound variable" error when code review JSON extraction returns null values.

### New Resume Feature
You can now resume agent runs from where they left off instead of starting over.

## How to Use Resume

### Scenario: Interrupted Agent Run

1. **Start an agent run:**
```bash
ENABLE_CODE_REVIEW=true MAX_ITERATIONS=15 bun run agent ".specs/my-feature/AGENT-PROMPT.md"
```

2. **Stop it mid-run** (Ctrl+C) or let it fail/timeout

3. **Resume from where it stopped:**
```bash
RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=15 bun run agent ".specs/my-feature/AGENT-PROMPT.md"
```

The agent will:
- ✅ Find the last completed iteration
- ✅ Continue from the next iteration number
- ✅ Load previous context
- ✅ Reuse the same run directory
- ✅ Preserve handoff state

## Examples

### Example 1: Development Workflow
```bash
# Start working on a feature
ENABLE_CODE_REVIEW=true MAX_ITERATIONS=10 bun run agent "Implement user authentication"

# Need to switch tasks? Stop with Ctrl+C at iteration 3

# Later, resume right where you left off
RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=10 bun run agent "Implement user authentication"
# Continues from iteration 4
```

### Example 2: Debugging
```bash
# Agent fails at iteration 5 due to external issue
ENABLE_CODE_REVIEW=true MAX_ITERATIONS=15 bun run agent ".specs/complex-feature/AGENT-PROMPT.md"

# Fix the external issue, then resume
RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=15 bun run agent ".specs/complex-feature/AGENT-PROMPT.md"
# Picks up at iteration 6
```

### Example 3: Increasing Iteration Limit
```bash
# Start with conservative limit
MAX_ITERATIONS=5 bun run agent "Refactor authentication system"

# Agent needs more iterations? Resume with higher limit
RESUME_AGENT=true MAX_ITERATIONS=15 bun run agent "Refactor authentication system"
# Continues from iteration 6, but now can go up to 15
```

## Resume Behavior

### What Gets Preserved
- ✅ Iteration counter
- ✅ Run output directory
- ✅ Previous iteration context (last 100 lines)
- ✅ Handoff file state
- ✅ All iteration logs

### What Gets Reset
- ❌ Nothing! Resume is seamless

### When Resume Won't Work
- No previous run exists → starts fresh automatically
- Output directory is empty → starts fresh automatically
- Different prompt file → separate feature, starts fresh

## Command Reference

### Environment Variables

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `RESUME_AGENT` | `true`/`false` | `false` | Enable resume mode |
| `ENABLE_CODE_REVIEW` | `true`/`false` | `false` | Enable code review cycle |
| `MAX_ITERATIONS` | number | `10` | Maximum iterations to run |
| `MAX_CODE_REVIEWS` | number | `3` | Maximum review cycles |
| `ENABLE_SPEECH` | `true`/`false` | `false` | Enable speech summaries |

### Full Command Template
```bash
RESUME_AGENT=true \
ENABLE_CODE_REVIEW=true \
MAX_ITERATIONS=15 \
MAX_CODE_REVIEWS=3 \
ENABLE_SPEECH=false \
bun run agent ".specs/my-feature/AGENT-PROMPT.md"
```

## Verify Resume Works

Run the test suite:
```bash
bash tests/test_resume.sh
```

All tests should pass:
- ✅ Null error fix
- ✅ Integer comparisons
- ✅ Resume detection (no previous)
- ✅ Resume detection (with previous)

## Troubleshooting

### "No previous run found, starting fresh"
- This is normal if it's your first run
- Check that the prompt file path matches previous run
- Feature directories are separate - different paths mean different features

### Agent starts from iteration 1 even with RESUME_AGENT=true
- Verify the output directory structure: `.ai-dr/agent-runs/{feature}/`
- Check if iteration logs exist: `iteration_*.log`
- Ensure you're using the same prompt file path

### "unbound variable" error still happens
- This should be fixed! If you see this, check:
  - Are you on the latest version of `lib/agent-runner.sh`?
  - Line 168-169 should have `jq -r` with `// default` values
  - Run the test: `bash tests/test_resume.sh`

## Notes

- Resume is **opt-in** - default behavior unchanged
- Safe to use - automatically falls back to fresh start if no previous run
- Works with all agent features (code review, speech, etc.)
- Can resume across shell sessions
- Output directory determines what can be resumed

