# While Loopin' Claude

AI-orchestrated autonomous agent system for Claude CLI. Lets Claude run in a loop until tasks complete.

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **[QUICK-START.md](QUICK-START.md)** | Get running in 5 minutes |
| **[ARCHITECTURE.md](ARCHITECTURE.md)** | System design, diagrams, and components |
| **[API-SPEC.md](API-SPEC.md)** | Language-agnostic interface specifications |
| **[CLAUDE.md](CLAUDE.md)** | Development guide and best practices |

## What It Does

- 🤖 **Autonomous Execution** - Claude runs in iterative loops until task completion
- 🧠 **AI Configuration** - Analyzes prompts to determine optimal settings
- 📁 **Smart Organization** - Auto-creates feature directories with specs
- ✅ **Quality Assurance** - Optional code review with automatic fixes
- 🌐 **Live Preview** - Real-time browser updates with WebSocket
- 🔊 **Feedback Options** - Rate limiting, speech output, progress tracking

## Quick Start

> 📖 **See [QUICK-START.md](QUICK-START.md) for detailed setup and common use cases**

### Fastest Demo (30 seconds)
```bash
# Clone and run interactive demo
git clone https://github.com/yourusername/while-loopin-claude.git
cd while-loopin-claude
npm install
bash examples/quick-test.sh
```

### Basic Usage
```bash
# Run agent with inline prompt
bun run agent "Fix the authentication bug in user login"

# Run agent with prompt file
bun run agent path/to/plan.txt

# Run with live preview
bash examples/color-art-app/run-agent-live.sh
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
│   └── {feature-name}/   # Auto-generated per task
│       ├── AGENT-PROMPT.md
│       ├── HANDOFF.md
│       ├── analysis.json
│       └── README.md
├── .ai-dr/
│   ├── prompts/          # Saved prompts
│   └── agent-runs/       # Agent outputs
│       └── {feature-name}/
│           └── {run-id}/           # Per-execution outputs
│               ├── iteration_*.log
│               └── reviews/
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
bash lib/agent-runner.sh \
  .specs/my-feature/AGENT-PROMPT.md \
  .specs/my-feature/HANDOFF.md \
  .ai-dr/agent-runs/my-feature \
  10 \
  --enable-code-review \
  --max-reviews 5 \
  --handoff auto \
  --handoff-template templates/handoff-system-prompt.md
```

### Custom Integration

See `lib/agent-runner.sh` for the core `run_claude_agent()` function:

```bash
source lib/agent-runner.sh

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

### Terminal Color Art

Simple Node.js terminal art generator:

```bash
cd examples/color-art-app
bash run-agent.sh      # Run autonomous agent
node color-art.js      # See the terminal art
```

Demonstrates basic autonomous iteration with prompt files.

### Generative Art Playground

Watch Claude autonomously build a complete generative art system from a simple HTML starter:

```bash
# Run from repo root (easiest!)
bun run demo

# Or run from example directory
cd examples/color-art-app
bash run-generative-agent.sh
```

**What happens:**
- Transforms `index.html` from 120 lines → 993 lines
- Builds 5 complete generative art patterns
- Adds color theory system and interactive controls
- Shows the agent's progress in real-time
- Opens the result when complete

**Before/After:**
```bash
# View simple starter
open examples/color-art-app/index.html  # Before: rotating circles

# Run transformation
bun run demo

# View the result
open examples/color-art-app/index.html  # After: full generative art system
```

**What Claude Builds:**
- **5 Generative Patterns**: Flow Field, Fractal Tree, Particle Galaxy, Sacred Geometry, Plasma Waves
- **ColorPalette System**: 8 color schemes with HSLA → HEX conversion
- **Interactive Controls**: Keyboard shortcuts, mouse interactions, UI sliders
- **60 FPS Performance**: Optimized canvas rendering with thousands of particles
- **Export Features**: Save frames as PNG, reproducible seeds

Compare the before/after:
- **Before**: `index.html` (120 lines, rotating circles)
- **After**: `index-transformed-demo.html` (993 lines, full system)

See `TRANSFORMATION-SUMMARY.md` and `WHAT-CLAUDE-BUILT.md` for complete documentation of what gets created.

### Additional Examples

See `examples/` directory for:
- Simple bug fix task
- Feature implementation
- Refactoring project
- Custom integration

## Architecture

> 📖 **See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed system design, diagrams, and component specifications**

### Core Components

1. **smart-agent.sh** - AI orchestrator that analyzes prompts and determines configuration
2. **agent-runner.sh** - Execution engine that runs Claude in iterative loops
3. **claude-functions.sh** - Reusable utilities for Claude execution and JSON parsing

### New Components (Context Framework)
4. **context-functions.sh** - Persistent context tracking across iterations
5. **master-agent.sh** - Multi-phase task orchestration
6. **phase-agent.sh** - Individual phase execution wrapper
7. **live-server.js** - WebSocket server for real-time browser updates

## Building Your Own Implementation

> 📖 **See [API-SPEC.md](API-SPEC.md) for language-agnostic interface specifications**

The patterns demonstrated here can be implemented in any language:

- **Python**: Use the Anthropic SDK
- **TypeScript/JavaScript**: Node.js implementation
- **Go**: HTTP client with structured types
- **Ruby/Java/C#**: Follow the interface contracts

All core interfaces, schemas, and contracts are documented in [API-SPEC.md](API-SPEC.md).

## Best Practices

> 📖 **See [CLAUDE.md](CLAUDE.md) for comprehensive development guide**

Key topics covered:
- How to write effective prompts
- Feature spec organization
- Handoff document format
- Testing and validation
- Extension guidelines

## License

MIT
