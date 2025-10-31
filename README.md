# While Loopin' Claude

AI-orchestrated autonomous agent system for Claude CLI. Lets Claude run in a loop until tasks complete.

## What It Does

- Runs Claude autonomously with iterative handoffs
- AI analyzes your prompt and determines optimal configuration
- Auto-creates feature directories with specs, handoffs, outputs
- Optional code review cycles with automatic fix application
- Rate limiting and speech feedback support

## Quick Start

```bash
# Install in your project
cp -r lib/ your-project/.specs/_shared/

# Run agent with inline prompt
bun run agent "Fix the authentication bug in user login"

# Run agent with prompt file
bun run agent path/to/plan.txt
```

## How It Works

1. **AI Analysis**: Claude analyzes your prompt to determine:
   - Task type and complexity
   - Feature name (kebab-case slug)
   - Max iterations needed
   - Whether code review should run
   - Relevant files and context

2. **Setup**: Creates `.specs/{feature-name}/` with:
   - `AGENT-PROMPT.md` - Enhanced prompt with full context
   - `HANDOFF.md` - Session handoff for iteration tracking
   - `analysis.json` - AI configuration and reasoning
   - `README.md` - Navigation and metadata

3. **Execution**: Runs agent loop:
   - Claude processes prompt
   - Updates handoff after each iteration
   - Checks for completion marker
   - Continues until done or max iterations

4. **Code Review** (optional): After main loop:
   - Reviews code quality
   - Applies critical fixes
   - Runs lint and typecheck
   - Re-reviews until quality threshold met

## Directory Structure

```
your-project/
├── .specs/
│   ├── _shared/          # Agent system (copy lib/ here)
│   │   ├── agent-runner.sh
│   │   ├── claude-functions.sh
│   │   └── smart-agent.sh
│   └── {feature-name}/   # Auto-generated per task
│       ├── AGENT-PROMPT.md
│       ├── HANDOFF.md
│       ├── analysis.json
│       └── README.md
├── .ai-dr/
│   ├── prompts/          # Saved prompts
│   └── agent-runs/       # Agent outputs
│       └── {feature-name}/
│           ├── iteration_*.log
│           └── reviews/
└── package.json
```

## Configuration

All configuration is AI-determined from your prompt, but you can override:

```bash
# Enable code review
ENABLE_CODE_REVIEW=true bun run agent "your prompt"

# Set max iterations
MAX_ITERATIONS=20 bun run agent "your prompt"

# Enable speech feedback (macOS)
ENABLE_SPEECH=true bun run agent "your prompt"

# Adjust rate limiting
RATE_LIMIT_SECONDS=30 bun run agent "your prompt"
```

## Advanced Usage

### Direct Runner Usage

```bash
# Run agent with specific config
bash .specs/_shared/agent-runner.sh \
  .specs/my-feature/AGENT-PROMPT.md \
  .specs/my-feature/HANDOFF.md \
  .ai-dr/agent-runs/my-feature \
  10 \
  --enable-code-review \
  --max-reviews 5
```

### Custom Integration

See `lib/agent-runner.sh` for the core `run_claude_agent()` function:

```bash
source .specs/_shared/agent-runner.sh

run_claude_agent \
  "$PROMPT_FILE" \
  "$HANDOFF_FILE" \
  "$OUTPUT_DIR" \
  "$MAX_ITERATIONS" \
  --enable-code-review
```

## Requirements

- [Claude CLI](https://github.com/anthropics/claude-cli) installed and configured
- Bash 4.0+
- `jq` for JSON processing
- Bun (for `bun run agent` script)

## Examples

See `examples/` directory for:
- Simple bug fix task
- Feature implementation
- Refactoring project
- Custom integration

## Architecture

Three core components:

1. **smart-agent.sh** - AI orchestrator
   - Analyzes prompts
   - Generates configuration
   - Sets up feature directories

2. **agent-runner.sh** - Execution engine
   - Runs Claude in loop
   - Manages handoffs
   - Coordinates code review

3. **claude-functions.sh** - Utilities
   - Reusable Claude execution
   - JSON generation with Haiku
   - Structured output helpers

## Best Practices

See `CLAUDE.md` for:
- How to write effective prompts
- Feature spec organization
- Handoff document format
- Testing and validation
- Extension guidelines

## License

MIT
