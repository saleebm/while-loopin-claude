# Installation Guide

Quick guide to integrate While Loopin' Claude into your project.

## Prerequisites

- [Claude CLI](https://github.com/anthropics/claude-cli) installed and configured
- Bash 4.0+
- `jq` (JSON processor)
- Bun (optional, for `bun run agent` convenience)

## Install in Your Project

### Option 1: Copy Scripts (Recommended)

```bash
# From your project root
mkdir -p .specs/_shared
cp -r /path/to/while-loopin-claude/lib/* .specs/_shared/

# Create output directories
mkdir -p .ai-dr/{prompts,agent-runs}
```

### Option 2: Git Submodule

```bash
# From your project root
git submodule add https://github.com/YOUR_USERNAME/while-loopin-claude .specs/_shared
```

### Option 3: Symlink (Development)

```bash
# From your project root
mkdir -p .specs
ln -s /path/to/while-loopin-claude/lib .specs/_shared
```

## Add to package.json

```json
{
  "scripts": {
    "agent": "bash .specs/_shared/smart-agent.sh"
  }
}
```

## Verify Installation

```bash
# Test with simple prompt
bun run agent "Create a test file at test.txt with 'Hello World'"

# Check outputs
ls -la .specs/
ls -la .ai-dr/agent-runs/
```

## Optional: Add .gitignore

```gitignore
# Agent outputs
.ai-dr/agent-runs/
.ai-dr/prompts/
.specs/*/iteration_*.log
.specs/*/reviews/
.specs/*/HANDOFF.md.backup
```

## Optional: Code Review Setup

If using code review features, ensure your project has:

```json
{
  "scripts": {
    "lint": "your-linter",
    "typecheck": "your-type-checker"
  }
}
```

Create review template (optional):

```bash
mkdir -p .claude/agents
cp /path/to/while-loopin-claude/.claude/agents/code-quality-reviewer.md .claude/agents/
```

Or agent will use built-in template.

## Usage

```bash
# Basic
bun run agent "Your task description"

# From file
bun run agent path/to/plan.txt

# With code review
ENABLE_CODE_REVIEW=true bun run agent "Your task"

# With options
MAX_ITERATIONS=20 ENABLE_SPEECH=true bun run agent "Your task"
```

## Directory Structure

After installation:

```
your-project/
├── .specs/
│   └── _shared/          # Agent scripts
│       ├── agent-runner.sh
│       ├── claude-functions.sh
│       └── smart-agent.sh
├── .ai-dr/
│   ├── prompts/          # Created on first run
│   └── agent-runs/       # Created on first run
├── .claude/              # Optional
│   └── agents/
│       └── code-quality-reviewer.md
└── package.json          # With "agent" script
```

## Troubleshooting

**"Command not found: claude"**
- Install Claude CLI: `npm install -g @anthropic/claude-cli`
- Or follow: https://github.com/anthropics/claude-cli

**"Command not found: jq"**
- macOS: `brew install jq`
- Linux: `apt install jq` or `yum install jq`

**"Permission denied"**
```bash
chmod +x .specs/_shared/*.sh
```

**Scripts not working**
- Verify bash version: `bash --version` (need 4.0+)
- Check script syntax: `bash -n .specs/_shared/agent-runner.sh`

## Next Steps

See:
- `README.md` - Full usage guide
- `CLAUDE.md` - Development best practices
- `examples/` - Runnable examples
