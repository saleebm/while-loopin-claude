# Multi-Phase Context Framework - Implementation Plan

## Overview

This plan breaks down the user's requirements into achievable, measurable tasks that build upon the existing agent framework without causing regressions.

## Core Requirements (Parsed from Original Prompt)

### 1. Context File Enforcement
**Requirement**: Agents must update context files containing:
- Complete list of instructions for their current phase
- Progress tracking
- Findings and thoughts
- Recent achievements
- Validation methods for achievements

**Implementation**: Add instruction to agent loop to create/update shared context files

### 2. Master Agent Coordination
**Requirement**: 
- Master agent tracks multi-phase agents
- Master agent operates outside/alongside main agent
- Master agent controls and coordinates sub-agents
- Sub-agents execute phases from planning agent output
- Planning agent is separate from main agent

**Implementation**: Create master agent orchestration layer

### 3. Minimal Changes Principle
**Requirement**:
- Keep all existing functionality intact
- Only add on top, no regressions
- Minimal changes
- Focus on simplicity
- Build on first principles

### 4. Pattern Creation
**Requirement**: Create reusable pattern for all `.specs/` subdirectories

## Task Breakdown

### Phase 1: Context File System (Foundation)

**Task 1.1**: Add context file creation instruction to agent loop
- **Location**: `lib/agent-runner.sh` in `run_claude_agent()` function
- **Change**: Add instruction to prompt that requires agents to update context files
- **File Structure**: `.specs/{feature-name}/context/`
  - `instructions.md` - Complete instructions for current phase
  - `progress.md` - Progress tracking
  - `findings.md` - Discoveries and thoughts
  - `achievements.md` - Recent achievements with validation
- **Minimal Change**: Append to existing prompt generation, don't modify core loop logic

**Task 1.2**: Create context file template
- **Location**: `templates/context-template.md`
- **Purpose**: Standard format for context files
- **Structure**: Markdown format with sections for each context type

**Task 1.3**: Add context file helper functions
- **Location**: `lib/context-functions.sh` (new file)
- **Functions**:
  - `ensure_context_files()` - Creates/updates context files
  - `read_context()` - Reads context from files
  - `update_context()` - Updates specific context section
- **Integration**: Source in `agent-runner.sh`, call from main loop

### Phase 2: Master Agent Framework

**Task 2.1**: Create master agent orchestrator
- **Location**: `lib/master-agent.sh` (new file)
- **Purpose**: Coordinates multi-phase agents
- **Key Functions**:
  - `init_master_agent()` - Sets up master agent context
  - `register_phase_agent()` - Registers sub-agent for phase
  - `coordinate_phases()` - Orchestrates phase execution
  - `track_phase_progress()` - Monitors sub-agent progress

**Task 2.2**: Create phase agent wrapper
- **Location**: `lib/phase-agent.sh` (new file)
- **Purpose**: Wraps existing `run_claude_agent()` for phase execution
- **Key Functions**:
  - `run_phase_agent()` - Runs agent for specific phase
  - `report_to_master()` - Sends status to master agent

**Task 2.3**: Create planning agent interface
- **Location**: `lib/planning-agent.sh` (new file)
- **Purpose**: Separates planning from execution
- **Key Functions**:
  - `generate_phase_plan()` - Creates multi-phase plan
  - `validate_plan()` - Ensures plan is executable

**Task 2.4**: Master agent context tracking
- **Location**: `.specs/{feature-name}/master-context/`
- **Files**:
  - `phases.json` - Phase definitions and status
  - `agents.json` - Active agent registry
  - `coordination.log` - Master agent decisions

### Phase 3: Integration Points

**Task 3.1**: Integrate context files into existing loop
- **Location**: `lib/agent-runner.sh`
- **Change**: After each iteration, call `ensure_context_files()`
- **Preserve**: All existing handoff functionality
- **Add**: Context file updates alongside handoff updates

**Task 3.2**: Add master agent mode to smart-agent.sh
- **Location**: `lib/smart-agent.sh`
- **Change**: Detect if prompt requires multi-phase execution
- **Action**: If yes, initialize master agent instead of single agent
- **Fallback**: Default to single agent mode (existing behavior)

**Task 3.3**: Create feature directory pattern
- **Location**: Template in `.specs/_shared/` or `templates/`
- **Pattern**: Standard structure for multi-phase features
  ```
  .specs/{feature-name}/
  ├── AGENT-PROMPT.md
  ├── HANDOFF.md
  ├── analysis.json
  ├── README.md
  ├── context/
  │   ├── instructions.md
  │   ├── progress.md
  │   ├── findings.md
  │   └── achievements.md
  ├── master-context/
  │   ├── phases.json
  │   ├── agents.json
  │   └── coordination.log
  └── phases/
      └── {phase-name}/
          ├── AGENT-PROMPT.md
          ├── HANDOFF.md
          └── context/
  ```

### Phase 4: Prompt Engineering

**Task 4.1**: Update agent prompt template
- **Location**: Modify prompt generation in `agent-runner.sh`
- **Addition**: Instruction block requiring context file updates
- **Format**: 
  ```
  ## Context File Requirements
  You MUST update the following context files after each iteration:
  - context/instructions.md: Your complete instructions for this phase
  - context/progress.md: What you've accomplished
  - context/findings.md: Discoveries and insights
  - context/achievements.md: Validated achievements with proof
  ```

**Task 4.2**: Create master agent prompt template
- **Location**: `templates/master-agent-prompt.md`
- **Purpose**: Template for master agent coordination prompts

**Task 4.3**: Create phase agent prompt template  
- **Location**: `templates/phase-agent-prompt.md`
- **Purpose**: Template for phase-specific agent prompts

## Implementation Order

1. **Phase 1** (Foundation): Context file system
   - Can be added independently
   - No changes to core loop logic
   - Adds capability without breaking existing behavior

2. **Phase 2** (Orchestration): Master agent framework
   - Builds on Phase 1
   - Adds new orchestration layer
   - Doesn't modify existing single-agent flow

3. **Phase 3** (Integration): Connect pieces
   - Minimal integration points
   - Preserves all existing functionality
   - Adds new capabilities alongside old

4. **Phase 4** (Prompts): Enhance instructions
   - Updates templates
   - Adds new prompt sections
   - No code changes required

## Files to Create

### New Files
- `lib/context-functions.sh` - Context file management
- `lib/master-agent.sh` - Master agent orchestrator
- `lib/phase-agent.sh` - Phase agent wrapper
- `lib/planning-agent.sh` - Planning agent interface
- `templates/context-template.md` - Context file template
- `templates/master-agent-prompt.md` - Master agent prompt template
- `templates/phase-agent-prompt.md` - Phase agent prompt template

### Files to Modify
- `lib/agent-runner.sh` - Add context file calls (minimal)
- `lib/smart-agent.sh` - Add master agent detection (optional, preserves existing)

## Files NOT to Modify
- `lib/claude-functions.sh` - Core utilities (preserve)
- `lib/handoff-functions.sh` - Handoff system (preserve)
- `lib/code-review.sh` - Code review (preserve)

## Validation Criteria

Each phase must:
1. ✅ Preserve existing functionality
2. ✅ Add new capability without breaking old
3. ✅ Follow first principles (simplicity, composability)
4. ✅ Use existing patterns (reuse `run_claude()`, `generate_structured_output()`)
5. ✅ Be testable independently

## Testing Strategy

1. Test Phase 1: Single agent with context files
   - Verify context files created/updated
   - Verify existing handoff still works
   - Verify no regressions

2. Test Phase 2: Master agent with single phase
   - Verify master agent can coordinate
   - Verify phase agent executes correctly
   - Verify context files maintained

3. Test Phase 3: Multi-phase execution
   - Verify master agent coordinates multiple phases
   - Verify context files per phase
   - Verify master context tracking

4. Integration Test: Full workflow
   - Verify existing single-agent flow unchanged
   - Verify new multi-phase flow works
   - Verify both can coexist

## Success Metrics

- ✅ Context files created and updated automatically
- ✅ Master agent can coordinate multiple phases
- ✅ Planning agent separates plan from execution
- ✅ Zero regressions in existing functionality
- ✅ Pattern reusable across all `.specs/` directories
- ✅ Minimal code changes (mostly additions)

## Next Steps (After Approval)

1. Review and approve this plan
2. Begin Phase 1 implementation
3. Test incrementally after each task
4. Document findings in context files
5. Iterate based on learnings
