# Multi-Phase Context Framework - Implementation

## Original User Prompt

Read `ORIGINAL-PROMPT.txt` for the exact user requirements.

## Your Mission

Implement a framework that enforces agents to maintain context files tracking their work, and adds a master agent system for coordinating multi-phase agent execution. Build this ON TOP of existing functionality without causing regressions.

## Current Codebase Analysis

You are working with:
- `lib/agent-runner.sh` - Main agent loop (`run_claude_agent()`)
- `lib/claude-functions.sh` - Core Claude execution utilities
- `lib/smart-agent.sh` - AI orchestrator that analyzes prompts
- `lib/handoff-functions.sh` - Handoff document management
- `.specs/{feature-name}/` - Feature directory structure

## Implementation Plan

Follow the detailed plan in `PLAN.md`. Key phases:

### Phase 1: Context File System
- Add instruction to agent loop to create/update context files
- Create context file template
- Add helper functions for context management

### Phase 2: Master Agent Framework  
- Create master agent orchestrator
- Create phase agent wrapper
- Create planning agent interface

### Phase 3: Integration
- Integrate context files into existing loop
- Add master agent mode detection
- Create feature directory pattern

### Phase 4: Prompt Engineering
- Update agent prompt templates
- Create master/phase agent prompts

## Critical Constraints

1. **Preserve Everything**: All existing functionality must remain intact
2. **Minimal Changes**: Only add code, don't modify core logic unnecessarily
3. **First Principles**: Build on existing patterns (use `run_claude()`, `generate_structured_output()`)
4. **Simplicity**: Avoid over-engineering
5. **Composability**: Functions should be reusable

## Context File Requirements

For each iteration, agents must maintain:
- `context/instructions.md` - Complete instructions for current phase
- `context/progress.md` - Progress tracking
- `context/findings.md` - Discoveries and thoughts  
- `context/achievements.md` - Recent achievements with validation proof

## Master Agent Requirements

- Master agent coordinates multi-phase execution
- Master agent operates alongside main agent
- Master agent controls sub-agents based on planning agent output
- Planning agent is separate from main agent

## Implementation Approach

1. Start with Phase 1 (context files) - simplest addition
2. Build Phase 2 (master agent) incrementally
3. Integrate in Phase 3 carefully
4. Enhance prompts in Phase 4

## Success Criteria

- ✅ Context files automatically created/updated
- ✅ Master agent can coordinate phases
- ✅ Zero regressions
- ✅ Pattern reusable across `.specs/` directories
- ✅ Minimal code changes

## First Task

Begin with Phase 1, Task 1.1: Add context file instruction to agent loop.

Read `PLAN.md` for complete task breakdown, then implement incrementally, testing after each change.
