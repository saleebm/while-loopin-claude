# Multi-Phase Context Framework - Usage Guide

## Overview

The multi-phase context framework extends the agent system with two key capabilities:

1. **Automatic Context Management** - Agents maintain structured context files tracking their work
2. **Master Agent Orchestration** - Complex tasks are automatically broken into coordinated phases

## Context File Management (Automatic)

### What Gets Created

Every agent run automatically creates and maintains these context files:

```
.specs/{feature-name}/context/
├── instructions.md   # Current phase instructions and success criteria
├── progress.md       # Milestone tracking and current status
├── findings.md       # Discoveries, insights, and thought processes
└── achievements.md   # Completed work with validation proof
```

### How It Works

1. **Initialization**: Context files are created when agent starts
2. **Agent Awareness**: Instructions are appended to agent prompts
3. **Validation**: After each iteration, system checks if files are updated
4. **Summary**: Final report includes context file summary

### Example Context Files

**instructions.md**:
```markdown
## Current Phase
Implement user authentication

## Success Criteria
- Login endpoint returns JWT
- Signup creates user in database
- Protected routes require valid token
```

**progress.md**:
```markdown
## Milestones
- [x] Database schema created
- [x] Signup endpoint implemented
- [ ] Login endpoint in progress

## Next Steps
1. Add password hashing
2. Generate JWT tokens
3. Test with Postman
```

## Master Agent (Multi-Phase Execution)

### When to Use Master Agent

The AI automatically suggests master agent for tasks that:
- Require multiple distinct phases (e.g., "build complete auth system")
- Have complex dependencies between components
- Need coordinated work across different subsystems
- Have "very-high" estimated complexity

### How It Works

#### 1. Planning Phase

Master agent first runs a planning agent that:
- Analyzes your goal
- Breaks it into 2-5 logical phases
- Determines dependencies
- Estimates iterations per phase

Example planning output:
```json
{
  "goal": "Implement user authentication with JWT",
  "phases": [
    {
      "id": "phase-1",
      "name": "Database Schema",
      "description": "Create users table with auth fields",
      "success_criteria": ["Migration created", "Schema validated"],
      "max_iterations": 5
    },
    {
      "id": "phase-2",
      "name": "Auth Endpoints",
      "description": "Implement login and signup APIs",
      "success_criteria": ["POST /login works", "POST /signup works"],
      "max_iterations": 8,
      "depends_on": ["phase-1"]
    }
  ]
}
```

#### 2. Phase Execution

For each phase:
1. Creates dedicated phase directory with context files
2. Generates phase-specific prompt with previous phase context
3. Runs standard agent for that phase
4. Validates phase completion
5. Aggregates results to master context

#### 3. Context Aggregation

After each phase completes:
- Phase achievements and findings are extracted
- Master context file is updated
- Next phase receives aggregated context

### File Structure

```
.specs/feature-name/
├── master-context.md          # Aggregated cross-phase context
├── phases.json                # Generated phase breakdown
├── planning.log               # Planning agent output
├── context/                   # Master-level context
│   ├── instructions.md
│   ├── progress.md
│   ├── findings.md
│   └── achievements.md
├── phase-1/
│   ├── AGENT-PROMPT.md       # Phase 1 specific prompt
│   ├── HANDOFF.md            # Phase 1 status
│   ├── context/              # Phase 1 context files
│   └── runs/                 # Phase 1 agent outputs
├── phase-2/
│   ├── AGENT-PROMPT.md
│   ├── HANDOFF.md
│   ├── context/
│   └── runs/
└── phase-3/
    ├── AGENT-PROMPT.md
    ├── HANDOFF.md
    ├── context/
    └── runs/
```

## Usage Examples

### Standard Single-Phase Mode

Most tasks use standard mode automatically:

```bash
# Simple bug fix
bash lib/smart-agent.sh "Fix the authentication bug in login.ts"

# Single feature addition
bash lib/smart-agent.sh "Add password reset functionality"

# Refactoring task
bash lib/smart-agent.sh "Refactor user service to use async/await"
```

### Master Agent Multi-Phase Mode

AI determines when to use master agent, but you can force it:

```bash
# Let AI decide (recommended)
bash lib/smart-agent.sh "Build complete REST API for todo app"

# Force master agent mode
MASTER_AGENT=true bash lib/smart-agent.sh "Add user management features"

# With non-interactive mode
INTERACTIVE_MODE=false MASTER_AGENT=true bash lib/smart-agent.sh "Implement auth system"
```

### Direct Master Agent Call

For advanced use cases, call master agent directly:

```bash
source lib/master-agent.sh

run_master_agent \
  "Build REST API with auth, CRUD operations, and testing" \
  ".specs/todo-api" \
  10
```

## Interactive Configuration

When running smart-agent.sh, you can configure:

1. **Max Iterations**: Override AI suggestion
2. **Code Review**: Enable/disable automated review cycle
3. **Speech Summaries**: Hear progress updates (macOS only)
4. **Master Agent**: Override AI decision for multi-phase mode

Example interaction:
```
🧠 AI Analysis Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Task Type: Complete authentication system implementation
📁 Feature Name: auth-system
📊 Complexity: very-high
🔄 Max Iterations: 12
🔍 Code Review: true
🎯 Master Agent: true

⚙️  Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Use AI-suggested max iterations (12)? [Y/n]: y
✅ Using 12 iterations

Enable code review? (AI suggested: true) [Y/n]: y
✅ Code review enabled

Use master agent for multi-phase execution? (AI suggested: true) [Y/n]: y
✅ Master agent enabled
```

## Environment Variables

Configure behavior via environment variables:

```bash
# Force master agent mode
MASTER_AGENT=true bash lib/smart-agent.sh "your prompt"

# Disable interactive prompts
INTERACTIVE_MODE=false bash lib/smart-agent.sh "your prompt"

# Enable speech summaries
ENABLE_SPEECH=true bash lib/smart-agent.sh "your prompt"

# Enable code review
ENABLE_CODE_REVIEW=true bash lib/smart-agent.sh "your prompt"

# Adjust rate limiting
RATE_LIMIT_SECONDS=30 bash lib/smart-agent.sh "your prompt"
```

## Monitoring Progress

### Context Files

Check context files during execution:

```bash
# View current progress
cat .specs/feature-name/context/progress.md

# Check achievements
cat .specs/feature-name/context/achievements.md

# See all findings
cat .specs/feature-name/context/findings.md
```

### Master Agent Progress

For multi-phase tasks:

```bash
# View master context (aggregated results)
cat .specs/feature-name/master-context.md

# Check phase breakdown
cat .specs/feature-name/phases.json | jq .

# View specific phase status
cat .specs/feature-name/phase-1/HANDOFF.md
```

### Agent Outputs

All agent iterations are saved:

```bash
# Standard mode outputs
ls -la .ai-dr/agent-runs/feature-name/*/iteration_*.log

# Master mode phase outputs
ls -la .specs/feature-name/phase-*/runs/*/iteration_*.log
```

## Validation

### Context File Validation

System automatically checks if context files are updated:

```
🔍 Validating context files...
   ✅ Context files updated
```

If files still have template placeholders:
```
🔍 Validating context files...
   ⚠️  progress.md still contains template placeholders
   ℹ️  1 context file(s) not yet updated by agent
```

### Phase Completion Validation

Master agent validates each phase:

```
🔍 Validating phase completion...
   ✅ Phase marked complete
```

If phase didn't complete:
```
🔍 Validating phase completion...
   ❌ Phase not marked complete
```

## Troubleshooting

### Context Files Not Updated

If agent doesn't update context files:
1. Check that files exist: `ls .specs/feature-name/context/`
2. Review agent output for errors
3. Ensure agent completed at least one iteration
4. Context requirements are in the prompt (automatic)

### Master Agent Not Activating

If master agent doesn't activate when expected:
1. Check AI analysis: Look for `use_master_agent: false`
2. Force it: Use `MASTER_AGENT=true` environment variable
3. Verify complexity: Should be "very-high" for auto-activation

### Phase Not Completing

If phase gets stuck:
1. Check phase handoff: `cat .specs/feature/phase-N/HANDOFF.md`
2. Review phase outputs: `.specs/feature/phase-N/runs/`
3. Check success criteria in phase prompt
4. Increase max iterations if needed

## Best Practices

### Writing Effective Prompts

**Good prompts for standard mode:**
- "Fix the authentication bug in login handler"
- "Add password reset with email verification"
- "Refactor database queries to use connection pool"

**Good prompts for master agent mode:**
- "Build complete user authentication system"
- "Implement REST API with CRUD operations and testing"
- "Add multi-tenant support to the application"

### Context File Maintenance

Agents automatically maintain context files, but you can:
- Review findings to understand agent's thought process
- Check achievements for validation proof
- Use progress tracking to estimate completion

### Master Agent Planning

For best results with master agent:
- Provide clear high-level goals
- Let AI break down into phases
- Review phases.json after planning
- Trust the phase breakdown (AI analyzes dependencies)

## Implementation Details

### Context Integration Points

Context file management is integrated at:
- `lib/agent-runner.sh:374-394` - Initialization
- `lib/agent-runner.sh:409-419` - Prompt enhancement
- `lib/agent-runner.sh:459-479` - Validation
- `lib/agent-runner.sh:566-567` - Summary

### Master Agent Components

Master agent implementation:
- `lib/master-agent.sh` - Main orchestrator
- `templates/planning-agent-prompt.md` - Planning template
- `lib/smart-agent.sh:300-314` - Integration point

### Function Reference

Key functions you can reuse:

```bash
# Context management
source lib/context-functions.sh
ensure_context_files "$CONTEXT_DIR"
check_context_files_updated "$CONTEXT_DIR"

# Master agent
source lib/master-agent.sh
run_master_agent "$GOAL" "$FEATURE_DIR" "$MAX_ITERATIONS"
run_claude_planning "$GOAL" "$OUTPUT" "$FEATURE_DIR"

# Standard agent
source lib/agent-runner.sh
run_claude_agent "$PROMPT" "$HANDOFF" "$OUTPUT_DIR" "$MAX_ITER"
```

## Future Enhancements

Potential improvements:
- Visual progress dashboard
- Phase dependency graph visualization
- Parallel phase execution (for independent phases)
- Resume partial completion (phase-level resume)
- Custom phase templates
- Phase-specific validation hooks
