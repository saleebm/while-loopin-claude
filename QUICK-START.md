# 🚀 While Loopin' Claude - Quick Start Guide

[← Back to README](README.md) | [Architecture →](ARCHITECTURE.md) | [API Spec →](API-SPEC.md) | [Dev Guide →](CLAUDE.md)

---

Get up and running in 5 minutes with AI-powered autonomous development!

## Prerequisites

✅ **Required**:
- [Claude CLI](https://github.com/anthropics/claude-cli) installed and configured
- Bash 4.0+ (macOS/Linux)
- jq (JSON processor)

✅ **Optional** (for live preview):
- Node.js 14+
- npm or bun

## 1. Clone & Install (30 seconds)

```bash
# Clone the repository
git clone https://github.com/yourusername/while-loopin-claude.git
cd while-loopin-claude

# Install dependencies (for live preview features)
npm install

# Verify Claude CLI is working
claude --version
```

## 2. One-Line Quick Start

### 🎯 Fastest Demo (No Setup)
```bash
bash examples/quick-test.sh
```
Runs a fast demo: 3 iterations, 5s rate limit, auto-opens browser.

### 🎮 Interactive Demo (With Sound Alerts)
```bash
bash examples/color-art-app/run-agent-live.sh
```
Follow the interactive prompts with sound alerts 🔔

### 💻 Simple Task
```bash
bun run agent "Create a hello.txt file with 'Hello from Claude!'"
```
Watch Claude analyze, execute, and complete your task!

## 3. The Live Development Experience

### What You Get

✨ **Browser Auto-Opens** → See your app
📊 **Progress Overlay** → Know what Claude is doing
🔄 **Auto-Reload** → Changes appear instantly
🎮 **Interactive Config** → Control everything
🔔 **Sound Alerts** → Hear when input needed
🗣️ **Speech Feedback** → Optional audio updates

### Custom Configuration

```bash
# Set any options via environment variables:
MAX_ITERATIONS=5 \
ENABLE_SPEECH=true \
RATE_LIMIT_SECONDS=10 \
INTERACTIVE_MODE=false \
bash examples/color-art-app/run-agent-live.sh
```

### All Options

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `MAX_ITERATIONS` | 1-100 | 10 | How many loops before stopping |
| `ENABLE_SPEECH` | true/false | false | Speak progress updates (macOS) |
| `ENABLE_CODE_REVIEW` | true/false | false | Run quality review after |
| `RATE_LIMIT_SECONDS` | 1-300 | 15 | Delay between iterations |
| `AUTO_OPEN` | true/false | true | Open browser automatically |
| `INTERACTIVE_MODE` | true/false | true | Show configuration prompts |
| `PORT` | 1024-65535 | 3000 | Live server port |

## 4. Common Use Cases

### Fix a Bug
```bash
bun run agent "Fix the login validation that allows empty passwords"
```

### Add a Feature
```bash
bun run agent "Add dark mode toggle to the settings page with localStorage persistence"
```

### Refactor Code
```bash
bun run agent "Refactor user service to use async/await instead of callbacks"
```

### Multi-Step Task (From File)
```bash
cat > task.md << 'EOF'
Build a todo list feature with:
1. Add/remove todos
2. Mark as complete
3. Filter by status (all/active/completed)
4. Persist to localStorage
5. Clean UI with Tailwind CSS
EOF

bun run agent task.md
```

## 5. How It Works

```
Your Prompt → AI Analysis → Task Configuration → Agent Loop → Completion
```

1. **You provide a task** description
2. **Claude analyzes** complexity and determines configuration
3. **Agent loops** executing iterations
4. **Each iteration** builds on previous work via handoff
5. **Automatic detection** when task is complete

### What Gets Created

```
.specs/{your-feature}/
├── AGENT-PROMPT.md      # Enhanced prompt with context
├── HANDOFF.md           # Current state between iterations
├── analysis.json        # AI-determined configuration
├── README.md           # Feature navigation
└── context/            # Persistent context tracking
    ├── instructions.md  # Current phase instructions
    ├── progress.md     # What's been accomplished
    ├── findings.md     # Discoveries and insights
    └── achievements.md # Validated results

.ai-dr/agent-runs/{feature}/{timestamp}/
├── iteration_1.log     # Claude's first attempt
├── iteration_2.log     # Building on iteration 1
└── ...                # Continues until complete
```

## 6. Tips for Success

### ✅ Write Clear, Specific Prompts
```bash
# ❌ Too vague
bun run agent "fix the bug"

# ✅ Specific and actionable
bun run agent "Fix the login form to show error when password is less than 8 characters"
```

### ✅ Let AI Determine Complexity
The system automatically configures:
- Number of iterations needed
- Whether code review is required
- Which files are relevant
- Task complexity scoring

### ✅ Monitor Progress
```bash
# Watch live output
tail -f .ai-dr/agent-runs/*/latest/iteration_*.log

# Check current status
cat .specs/*/HANDOFF.md | grep Status

# View context
cat .specs/*/context/progress.md
```

### ✅ Use Code Review for Critical Changes
```bash
ENABLE_CODE_REVIEW=true bun run agent "Refactor authentication system"
```

## 7. Troubleshooting

### Claude CLI Not Found
```bash
# Install Claude CLI first
npm install -g @anthropic/claude-cli
claude auth login
```

### Permission Denied
```bash
# Make scripts executable
chmod +x lib/*.sh
chmod +x examples/**/*.sh
```

### Rate Limiting Issues
```bash
# Increase delay between iterations
RATE_LIMIT_SECONDS=30 bun run agent "complex task"
```

### Agent Keeps Running
```bash
# Set max iterations limit
MAX_ITERATIONS=5 bun run agent "your task"

# Or manually mark complete
echo "Status: complete" >> .specs/*/HANDOFF.md
```

### WebSocket Connection Failed
```bash
# Check if port is in use
lsof -i :3000
# Use different port
PORT=3001 bash examples/color-art-app/run-agent-live.sh
```

## 8. Advanced Usage

### Multi-Phase Execution (Coming Soon)
```bash
# Complex tasks automatically split into phases
bun run agent "Build complete e-commerce checkout flow with payment integration"
```

### Custom Model Selection
```bash
# Use Haiku for speed, Opus for complexity
MODEL=opus bun run agent "Complex architectural refactor"
MODEL=haiku bun run agent "Simple formatting fix"
```

### Parallel Agent Execution
```bash
# Run multiple features simultaneously (separate terminals)
bun run agent "Feature A" &
bun run agent "Feature B" &
```

## 9. Next Steps

### 📚 Learn More
- [README.md](README.md) - Complete documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System design & diagrams
- [API-SPEC.md](API-SPEC.md) - Build your own implementation
- [examples/](examples/) - More demo applications

### 🎯 Try These Real Tasks
1. **Debug Helper**: "Find and fix the memory leak in the user list component"
2. **Feature Builder**: "Add CSV export functionality to the data table"
3. **Test Writer**: "Create unit tests for the authentication service"
4. **Refactoring**: "Convert class components to React hooks"
5. **Documentation**: "Generate API documentation from code comments"

### 🛠 Build Your Own
- Implement in Python/TypeScript/Go
- Create custom prompt templates
- Build IDE integrations
- Add monitoring dashboards

## Getting Help

- **Full Docs**: `LIVE-MODE-SUMMARY.md`
- **Examples**: `examples/` directory
- **Issues**: [GitHub Issues](https://github.com/yourusername/while-loopin-claude/issues)
- **Logs**: Check `.ai-dr/agent-runs/` for details

---

**Ready to experience the magic?** Start with something real:

```bash
bun run agent "Add input validation to my contact form with email and phone verification"
```

**Maximum dopamine. Minimum setup. Pure joy.** 💚✨