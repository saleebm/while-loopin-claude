# Multi-Phase Agent Context Framework - Implementation Plan

## Overview
Framework to enforce context tracking across multi-phase agent operations. Builds on existing agent-runner.sh infrastructure with minimal additions.

---

## Core Requirements (Extracted from Prompt)

### 1. Context File Framework
- **Enforce context file updates** during agent iterations
- Context files must contain:
  - Complete list of instructions for current phase
  - Progress tracking
  - Findings and thoughts
  - Recent achievements
  - **Validation methods for achievements** (critical)

### 2. Multi-Phase Orchestration
- **Master agent** tracks multiple sub-agents
- Each sub-agent works on a specific phase
- Master coordinates handoffs between phases
- Phases defined by planning agent (separate from execution agents)

### 3. Design Constraints
- **Zero regression** to existing code
- **Minimal changes** - build on top, don't modify core
- Focus on **simplicity**
- Follow **first principles** of existing architecture
- Use existing `.specs/` pattern

---

## Architecture Analysis

### Existing System Components
Based on codebase review:

1. **agent-runner.sh** (lines 225-437)
   - Main loop: `run_claude_agent()`
   - Iteration counter (1 to MAX_ITERATIONS)
   - Handoff generation via `ensure_handoff()` (line 346)
   - Completion detection via "Session End" marker (line 359)

2. **handoff-functions.sh** (lines 86-139)
   - `ensure_handoff()` - Auto-generates handoff after iteration
   - `generate_handoff_prompt()` - Creates handoff decision prompt
   - `decide_handoff()` - Uses Haiku to decide handoff content

3. **smart-agent.sh** (lines 1-235)
   - AI-driven configuration
   - Creates `.specs/{feature-name}/` structure
   - Invokes `run_claude_agent()`

### Extension Points Identified

#### A. Iteration Loop Hook (agent-runner.sh:304-393)
Between completion check and next iteration:
- **Line 387-392**: Rate limiting section
- **Add here**: Context file update enforcement

#### B. Handoff Enhancement (handoff-functions.sh:86-139)
`ensure_handoff()` already generates tracking:
- **Extend**: Add phase tracking fields
- **Extend**: Add achievement validation tracking

#### C. Prompt Enhancement
Current prompt in `generate_continuation_prompt()` (line 444-465):
- **Add**: Instructions for context file maintenance
- **Add**: Phase awareness

---

## Implementation Phases

### Phase 1: Single-Agent Context Tracking
**Goal**: Add context file enforcement to existing single-agent loop

**Changes Required**:

1. **New file**: `lib/context-tracking.sh`
   - `ensure_context_file()` - Creates/updates context
   - `validate_context_file()` - Checks required fields
   - `append_achievement()` - Logs validated achievements

2. **Modify**: `lib/agent-runner.sh` (line ~386)
   ```bash
   # After handoff, before rate limit:
   if [[ -f "$HANDOFF_FILE" ]]; then
     ensure_context_tracking "$RUN_OUTPUT_DIR" "$i" "$HANDOFF_FILE"
   fi
   ```

3. **Context File Structure**:
   ```markdown
   # Agent Context - Iteration N
   
   ## Phase Instructions
   - [List of current phase requirements]
   
   ## Progress
   - [Completed items]
   - [In progress items]
   
   ## Findings
   - [Key discoveries]
   
   ## Achievements
   - [Achievement]: Validated by [method]
   
   ## Next Steps
   - [Planned actions]
   ```

4. **Prompt Addition** (in `generate_continuation_prompt()`):
   ```markdown
   ## Context Tracking Requirements
   After each significant action:
   1. Update context file at `{run-dir}/CONTEXT.md`
   2. Document what was done
   3. Document validation performed
   4. Note any findings or blockers
   ```

**Testing**:
- Run existing test: `test_agent()` function
- Verify CONTEXT.md created alongside HANDOFF.md
- Verify no regression in completion detection

---

### Phase 2: Phase-Based Segmentation
**Goal**: Support multiple phases within a single agent run

**Changes Required**:

1. **New file**: `lib/phase-manager.sh`
   - `detect_phase_transition()` - Checks handoff for phase change
   - `initialize_phase()` - Creates phase-specific context
   - `summarize_phase()` - Archives phase when complete

2. **Phase Context Structure**:
   ```
   .ai-dr/agent-runs/{feature}/
   ├── {run-id}/
   │   ├── iteration_*.log
   │   ├── HANDOFF.md
   │   ├── phases/
   │   │   ├── phase-1-setup/
   │   │   │   ├── CONTEXT.md
   │   │   │   └── ACHIEVEMENTS.md
   │   │   ├── phase-2-implementation/
   │   │   │   ├── CONTEXT.md
   │   │   │   └── ACHIEVEMENTS.md
   │   │   └── phase-3-validation/
   │   │       ├── CONTEXT.md
   │   │       └── ACHIEVEMENTS.md
   │   └── MASTER-CONTEXT.md
   ```

3. **Handoff Enhancement**:
   Add to handoff template:
   ```markdown
   ## Current Phase
   Phase: [phase-name]
   Status: [active|complete]
   
   ## Phase Transition
   Next Phase: [phase-name or "none"]
   Transition Ready: [yes|no]
   ```

4. **Master Context File**:
   Aggregates all phases:
   ```markdown
   # Master Agent Context
   
   ## All Phases
   1. Phase 1: Setup [complete]
      - Key achievements: ...
   2. Phase 2: Implementation [active]
      - Current progress: ...
   3. Phase 3: Validation [pending]
   
   ## Cross-Phase Findings
   - [Findings that span phases]
   ```

**Testing**:
- Create multi-phase test prompt
- Verify phase directories created on transition
- Verify master context aggregates correctly

---

### Phase 3: Multi-Agent Orchestration
**Goal**: Master agent coordinates multiple sub-agent runs

**Changes Required**:

1. **New file**: `lib/master-agent.sh`
   - `run_master_agent()` - Orchestrates sub-agents
   - `spawn_sub_agent()` - Launches phase-specific agent
   - `aggregate_contexts()` - Merges sub-agent contexts
   - `check_phase_completion()` - Validates phase done

2. **New file**: `lib/planning-agent.sh`
   - `generate_phase_plan()` - AI creates phase breakdown
   - `create_phase_prompts()` - Generates prompts per phase
   - `validate_plan()` - Ensures plan is achievable

3. **Master Agent Structure**:
   ```
   .ai-dr/agent-runs/{feature}/
   ├── master-{run-id}/
   │   ├── MASTER-PROMPT.md
   │   ├── MASTER-HANDOFF.md
   │   ├── MASTER-CONTEXT.md
   │   ├── PHASE-PLAN.json
   │   └── sub-agents/
   │       ├── phase-1-{run-id}/
   │       │   ├── iteration_*.log
   │       │   ├── HANDOFF.md
   │       │   └── CONTEXT.md
   │       ├── phase-2-{run-id}/
   │       │   └── ...
   │       └── phase-3-{run-id}/
   │           └── ...
   ```

4. **Planning Agent Integration**:
   ```bash
   # In smart-agent.sh, add multi-phase detection:
   if [[ "$IS_MULTI_PHASE" == "true" ]]; then
     run_master_agent "$FEATURE_DIR" "$OUTPUT_DIR" "$MAX_ITERATIONS"
   else
     run_claude_agent "${AGENT_ARGS[@]}"
   fi
   ```

5. **Phase Plan JSON**:
   ```json
   {
     "total_phases": 3,
     "phases": [
       {
         "id": "phase-1",
         "name": "setup",
         "description": "Setup infrastructure",
         "instructions": ["..."],
         "success_criteria": ["..."],
         "max_iterations": 5
       },
       {
         "id": "phase-2",
         "name": "implementation",
         "description": "Implement features",
         "instructions": ["..."],
         "success_criteria": ["..."],
         "max_iterations": 10
       }
     ],
     "dependencies": {
       "phase-2": ["phase-1"]
     }
   }
   ```

**Testing**:
- Create test that requires 3 distinct phases
- Verify master agent spawns sub-agents sequentially
- Verify contexts aggregate to master
- Verify phase dependencies enforced

---

## Detailed Implementation Steps

### Step 1: Context Tracking Foundation
**Scope**: Single agent, single phase

**Files to Create**:
1. `/workspace/lib/context-tracking.sh`

**Files to Modify**:
1. `/workspace/lib/agent-runner.sh` (line 386, add hook)
2. `/workspace/lib/agent-runner.sh` (line 444, enhance prompt)

**Functions to Implement**:
```bash
# lib/context-tracking.sh

ensure_context_tracking() {
  local RUN_OUTPUT_DIR="$1"
  local ITERATION="$2"
  local HANDOFF_FILE="$3"
  
  local CONTEXT_FILE="$RUN_OUTPUT_DIR/CONTEXT.md"
  
  # Extract info from handoff
  # Append to context file
  # Validate required fields present
}

validate_context_file() {
  local CONTEXT_FILE="$1"
  
  # Check for required sections:
  # - Phase Instructions
  # - Progress
  # - Findings
  # - Achievements (with validation)
}

append_achievement() {
  local CONTEXT_FILE="$1"
  local ACHIEVEMENT="$2"
  local VALIDATION_METHOD="$3"
  
  # Append formatted achievement with timestamp
}
```

**Prompt Enhancement**:
Add to `generate_continuation_prompt()`:
```markdown
## Context Documentation Requirements
You MUST maintain a context file documenting:

1. **Current Instructions**: What you're working on this phase
2. **Progress**: What's been completed, what's in progress
3. **Findings**: Discoveries, blockers, insights
4. **Achievements**: Completed items WITH validation proof
   Format: "Achievement: X. Validated by: Y."
5. **Next Steps**: What you'll do next

After each significant action, update the context.
The system will check for this documentation.
```

**Success Criteria**:
- CONTEXT.md created in run directory
- Contains all required sections
- Agent updates it during iterations
- No regression in existing behavior

---

### Step 2: Phase Segmentation
**Scope**: Single agent, multiple phases

**Files to Create**:
1. `/workspace/lib/phase-manager.sh`

**Files to Modify**:
1. `/workspace/lib/agent-runner.sh` (add phase detection)
2. `/workspace/lib/handoff-functions.sh` (add phase fields to handoff)
3. `/workspace/templates/handoff-system-prompt.md` (add phase section)

**Functions to Implement**:
```bash
# lib/phase-manager.sh

detect_phase_transition() {
  local HANDOFF_FILE="$1"
  
  # Check for "Next Phase: X" in handoff
  # Return new phase name or empty
}

initialize_phase() {
  local RUN_OUTPUT_DIR="$1"
  local PHASE_NAME="$2"
  local PHASE_NUM="$3"
  
  # Create phases/{phase-name}/ directory
  # Initialize CONTEXT.md for phase
  # Initialize ACHIEVEMENTS.md for phase
}

summarize_phase() {
  local PHASE_DIR="$1"
  local MASTER_CONTEXT="$2"
  
  # Read phase CONTEXT.md and ACHIEVEMENTS.md
  # Append summary to MASTER-CONTEXT.md
  # Mark phase complete
}

get_current_phase() {
  local RUN_OUTPUT_DIR="$1"
  
  # Find most recent active phase directory
  # Return phase name
}
```

**Handoff Template Addition**:
```markdown
## Phase Tracking

Current Phase: [phase-name]
Phase Status: [active|complete|blocked]

Phase Objectives:
- [ ] Objective 1
- [ ] Objective 2

Next Phase: [phase-name or "none"]
Transition Ready: [yes|no]
Transition Reason: [why ready or not ready]
```

**Success Criteria**:
- Agent can declare phase complete
- New phase directory created on transition
- Phase contexts isolated but linked
- Master context aggregates all phases

---

### Step 3: Master Agent Orchestration
**Scope**: Master coordinates sub-agents across phases

**Files to Create**:
1. `/workspace/lib/master-agent.sh`
2. `/workspace/lib/planning-agent.sh`

**Files to Modify**:
1. `/workspace/lib/smart-agent.sh` (add multi-phase detection)

**Functions to Implement**:
```bash
# lib/planning-agent.sh

generate_phase_plan() {
  local PROMPT_FILE="$1"
  local OUTPUT_JSON="$2"
  
  # Use Claude to analyze prompt
  # Break into phases with:
  #   - Phase name
  #   - Instructions
  #   - Success criteria
  #   - Dependencies
  # Output PHASE-PLAN.json
}

create_phase_prompts() {
  local PHASE_PLAN_JSON="$1"
  local OUTPUT_DIR="$2"
  
  # For each phase in plan:
  #   - Generate phase-specific AGENT-PROMPT.md
  #   - Include phase objectives
  #   - Include success criteria
  #   - Include context tracking requirements
}

validate_plan() {
  local PHASE_PLAN_JSON="$1"
  
  # Check plan is well-formed
  # Check dependencies are acyclic
  # Check success criteria are measurable
}

# lib/master-agent.sh

run_master_agent() {
  local FEATURE_DIR="$1"
  local OUTPUT_DIR="$2"
  local MAX_ITERATIONS="$3"
  
  # Generate phase plan
  # For each phase:
  #   - Create sub-agent prompt
  #   - Run sub-agent
  #   - Wait for completion
  #   - Validate success criteria met
  #   - If failed, retry or escalate
  # Aggregate all contexts
  # Generate final master handoff
}

spawn_sub_agent() {
  local PHASE_NAME="$1"
  local PHASE_PROMPT="$2"
  local PHASE_OUTPUT_DIR="$3"
  local MAX_ITERATIONS="$4"
  
  # Call run_claude_agent with phase-specific config
  # Monitor for completion
  # Return success/failure
}

aggregate_contexts() {
  local MASTER_OUTPUT_DIR="$1"
  
  # Read all sub-agent CONTEXT.md files
  # Read all sub-agent ACHIEVEMENTS.md files
  # Merge into MASTER-CONTEXT.md
  # Generate cross-phase summary
}

check_phase_completion() {
  local PHASE_DIR="$1"
  local SUCCESS_CRITERIA="$2"
  
  # Read phase HANDOFF.md
  # Check success criteria in JSON
  # Verify achievements match criteria
  # Return completion status
}
```

**Master Agent Flow**:
```
1. User provides complex prompt
2. smart-agent.sh detects multi-phase nature
3. planning-agent generates PHASE-PLAN.json
4. master-agent orchestrates:
   a. Create phase 1 prompt
   b. Spawn phase 1 sub-agent (run_claude_agent)
   c. Wait for phase 1 completion
   d. Validate phase 1 success criteria
   e. Create phase 2 prompt (includes phase 1 context)
   f. Spawn phase 2 sub-agent
   g. ... repeat for all phases
   h. Aggregate all contexts into master
   i. Generate final summary
5. User reviews master context and outputs
```

**Success Criteria**:
- Complex prompts auto-break into phases
- Each phase runs as isolated sub-agent
- Master tracks all sub-agent progress
- Cross-phase context preserved
- Dependencies enforced
- Failure handling (retry, escalate)

---

## File Structure After Implementation

```
/workspace/
├── lib/
│   ├── agent-runner.sh          [MODIFIED: add context tracking hook]
│   ├── claude-functions.sh       [NO CHANGE]
│   ├── code-review.sh           [NO CHANGE]
│   ├── handoff-functions.sh     [MODIFIED: add phase fields]
│   ├── smart-agent.sh           [MODIFIED: add multi-phase detection]
│   ├── context-tracking.sh      [NEW: Step 1]
│   ├── phase-manager.sh         [NEW: Step 2]
│   ├── planning-agent.sh        [NEW: Step 3]
│   └── master-agent.sh          [NEW: Step 3]
├── templates/
│   ├── handoff-system-prompt.md [MODIFIED: add phase section]
│   └── phase-context-template.md [NEW]
└── .specs/
    └── multi-phase-agent-context-framework/
        ├── ORIGINAL-PROMPT.txt
        ├── PLAN.md (this file)
        ├── AGENT-PROMPT.md (for implementation)
        └── README.md
```

---

## Testing Strategy

### Test 1: Single Agent Context (after Step 1)
```bash
# Create simple test
bun run agent "Create hello.txt with 'Hello World' and verify contents"

# Verify:
# - .ai-dr/agent-runs/{feature}/{run-id}/CONTEXT.md exists
# - CONTEXT.md has all required sections
# - Agent documented achievement validation
```

### Test 2: Multi-Phase Single Agent (after Step 2)
```bash
# Create multi-phase test
bun run agent "Phase 1: Create file. Phase 2: Modify file. Phase 3: Validate file."

# Verify:
# - phases/ directory created
# - Each phase has CONTEXT.md
# - MASTER-CONTEXT.md aggregates all
# - Phase transitions detected
```

### Test 3: Master-Orchestrated Multi-Agent (after Step 3)
```bash
# Create complex test requiring coordination
bun run agent "Build a 3-file project: setup structure, implement features, add tests"

# Verify:
# - PHASE-PLAN.json generated
# - Sub-agent runs per phase
# - Master context aggregates all
# - Dependencies respected
# - Success criteria validated
```

---

## Minimal Changes Principle

**What We DON'T Change**:
- Core agent loop logic (agent-runner.sh:304-393)
- Handoff generation mechanism
- Claude execution functions
- Code review cycle
- Rate limiting
- Completion detection

**What We ADD**:
- New library files (context-tracking.sh, phase-manager.sh, etc.)
- Hook calls at strategic points
- Template extensions
- Context file generation

**How We Ensure No Regression**:
1. All additions are opt-in via feature flags
2. Existing tests continue to pass
3. New files don't modify existing files' core logic
4. Hooks are non-blocking (failures don't stop agent)
5. Backward compatible handoff format

---

## Risk Analysis

### Risk 1: Context File Bloat
**Mitigation**: 
- Cap context file size (e.g., 10KB)
- Summarize old entries when cap hit
- Archive to separate timestamped files

### Risk 2: Phase Detection Ambiguity
**Mitigation**:
- Use explicit markers ("PHASE_TRANSITION: phase-name")
- Validate with Haiku before transitioning
- Allow manual phase override

### Risk 3: Master Agent Complexity
**Mitigation**:
- Start with sequential phases (no parallelism)
- Simple dependency model (linear chain)
- Explicit error handling and rollback

### Risk 4: Performance Overhead
**Mitigation**:
- Context operations are async (don't block)
- Phase detection only on handoff update
- Master agent only for multi-phase prompts

---

## Next Steps for Approval

This plan will be implemented in 3 sequential steps:

**Step 1** (Minimal):
- Add context tracking to single-agent runs
- 2 files: lib/context-tracking.sh + modifications to agent-runner.sh
- Est: 2-3 hours of agent work

**Step 2** (Moderate):
- Add phase segmentation within single agent
- 2 files: lib/phase-manager.sh + template modifications
- Est: 3-4 hours of agent work

**Step 3** (Complex):
- Add master agent orchestration
- 3 files: lib/master-agent.sh, lib/planning-agent.sh + modifications
- Est: 5-6 hours of agent work

**Total Estimated Effort**: 10-13 hours of agent development time

---

## Questions for User Approval

Before proceeding:

1. ✅ Does the 3-phase approach align with your vision?
2. ✅ Is the context file format adequate for your needs?
3. ✅ Should we implement all 3 steps, or start with Step 1 only?
4. ✅ Any additional fields needed in context/phase tracking?
5. ✅ Should master agent support parallel phases, or sequential only?

**Awaiting your approval to proceed with implementation.**
