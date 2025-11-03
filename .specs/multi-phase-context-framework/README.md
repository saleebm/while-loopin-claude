# Multi-Phase Context Framework

## Overview

This feature adds:
1. **Context File Enforcement**: Agents automatically maintain context files tracking their work
2. **Master Agent Coordination**: Multi-phase agent orchestration system
3. **Pattern Template**: Reusable structure for all `.specs/` directories

## Files

- [ORIGINAL-PROMPT.txt](./ORIGINAL-PROMPT.txt) - Exact user requirements (word-for-word)
- [PLAN.md](./PLAN.md) - Detailed implementation plan with task breakdown
- [TASK-BREAKDOWN.md](./TASK-BREAKDOWN.md) - Measurable tasks with direct instructions
- [AGENT-PROMPT.md](./AGENT-PROMPT.md) - Initialization prompt for Claude agent loop
- [INIT-PROMPT.txt](./INIT-PROMPT.txt) - Simple initialization prompt file
- [README.md](./README.md) - This file

## Implementation Status

**Status**: Planning phase - awaiting approval

## Next Steps

1. Review `PLAN.md` 
2. Approve implementation approach
3. Run agent with `AGENT-PROMPT.md` to begin implementation

## Usage (After Implementation)

```bash
# Single agent with context files (existing + new)
bash lib/smart-agent.sh "Your prompt here"

# Multi-phase agent (new capability)
# Master agent will automatically detect if multi-phase needed
bash lib/smart-agent.sh "Multi-phase prompt here"
```

## Architecture

- **Context Files**: `context/` directory in each `.specs/{feature-name}/`
- **Master Agent**: `lib/master-agent.sh` coordinates phases
- **Phase Agents**: Wrapped `run_claude_agent()` calls per phase
- **Planning Agent**: `lib/planning-agent.sh` generates phase plans

## Design Principles

- Minimal changes to existing code
- Build on top, don't break existing
- Follow first principles from codebase
- Simple, composable functions
