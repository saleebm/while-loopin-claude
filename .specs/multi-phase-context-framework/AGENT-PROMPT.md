# Multi-Phase Context Framework Implementation

## Mission
Implement a comprehensive context management framework that enforces agents to maintain context files tracking their work, and add a master agent system for coordinating multi-phase agent execution.

## Current State Analysis
The codebase already includes:
- `context-functions.sh` with full context file management utilities
- Functions for creating, updating, and validating context files
- Template structures for instructions, progress, findings, and achievements
- Path sanitization and security measures

## Implementation Tasks

### Phase 1: Context File Integration (Already Partially Complete)
- Context file functions already exist in `lib/context-functions.sh`
- Need to integrate context file updates into the main agent loop in `agent-runner.sh`
- Add instruction to agent prompts to use context files
- Ensure context files are created/updated each iteration

### Phase 2: Master Agent Framework
- Create master agent orchestrator script
- Implement phase detection and switching logic
- Create planning agent interface
- Add phase coordination utilities

### Phase 3: Integration
- Integrate context updates into existing agent loop
- Add master agent mode detection
- Update feature directory patterns
- Ensure backward compatibility

### Phase 4: Prompt Engineering
- Update agent prompt templates to include context instructions
- Create specialized prompts for master and phase agents
- Add context awareness to existing prompts

## Critical Constraints
1. **PRESERVE ALL EXISTING FUNCTIONALITY** - Zero regressions allowed
2. **BUILD ON EXISTING PATTERNS** - Use existing functions like `run_claude()`, `ensure_context_files()`
3. **MINIMAL MODIFICATIONS** - Only add code, don't change core logic unnecessarily
4. **MAINTAIN SIMPLICITY** - Avoid over-engineering
5. **ENSURE COMPOSABILITY** - Functions must be reusable

## Context File Requirements
- Location: `.specs/{feature-name}/context/`
- Files: instructions.md, progress.md, findings.md, achievements.md
- Must be updated every iteration
- Must include validation proof in achievements

## Master Agent Requirements
- Coordinate multi-phase execution
- Operate alongside main agent
- Control sub-agents based on planning output
- Planning agent separate from main agent

## First Actions
1. Verify existing context functions work correctly
2. Add context file update instruction to agent loop
3. Test with simple agent run
4. Begin master agent framework design

## Success Validation
- Context files automatically created and populated
- Agent loop continues to function normally
- Master agent can coordinate phases
- All existing tests pass
- Pattern reusable across feature directories
