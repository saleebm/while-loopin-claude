# Task Breakdown - Achievable Measurements & Direct Instructions

## Boundary 1: Context File Enforcement

### Requirement
Agents must update context files containing complete instructions for their phase, plus track progress, findings, thoughts, achievements, and validation.

### Measurable Tasks

**Task 1.1.1**: Add context file instruction to iteration prompt
- **Measurement**: Instruction appears in every agent prompt after iteration N
- **Location**: `lib/agent-runner.sh`, line ~320 (in `run_claude_agent()` loop)
- **Action**: Modify `generate_continuation_prompt()` or add context instruction block
- **Direct Instruction**: 
  ```
  After line 374 in agent-runner.sh, add:
  CURRENT_PROMPT+="\n\n## Context File Requirements\nYou MUST update:\n- context/instructions.md\n- context/progress.md\n- context/findings.md\n- context/achievements.md"
  ```

**Task 1.1.2**: Create context directory structure
- **Measurement**: Directory `.specs/{feature-name}/context/` exists after first iteration
- **Location**: `lib/agent-runner.sh`, before iteration loop (line ~284)
- **Action**: Create directory structure function
- **Direct Instruction**:
  ```
  Create function ensure_context_structure() in lib/context-functions.sh:
  - Takes FEATURE_DIR as parameter
  - Creates context/ subdirectory
  - Creates 4 markdown files if missing
  - Returns 0 on success
  ```

**Task 1.1.3**: Call context structure creation
- **Measurement**: Context files exist before first iteration
- **Location**: `lib/agent-runner.sh`, after line 286 (after RUN_OUTPUT_DIR creation)
- **Action**: Call `ensure_context_structure()` 
- **Direct Instruction**:
  ```
  After line 286, add:
  FEATURE_DIR=$(dirname "$HANDOFF_FILE")
  ensure_context_structure "$FEATURE_DIR"
  ```

### Validation Criteria
- ✅ Context files created automatically
- ✅ Files updated each iteration
- ✅ No breaking changes to existing handoff system

---

## Boundary 2: Master Agent System

### Requirement
Master agent tracks multi-phase agents, operates outside main agent, controls sub-agents based on planning agent phases.

### Measurable Tasks

**Task 2.1.1**: Detect multi-phase requirement
- **Measurement**: `smart-agent.sh` identifies if prompt needs multi-phase execution
- **Location**: `lib/smart-agent.sh`, after analysis JSON extraction (line ~149)
- **Action**: Add phase detection logic
- **Direct Instruction**:
  ```
  After line 149, add:
  IS_MULTI_PHASE=$(echo "$ANALYSIS_JSON" | jq -r '.requires_multi_phase // false')
  ```

**Task 2.1.2**: Create master agent initialization
- **Measurement**: Master agent context directory created when multi-phase detected
- **Location**: `lib/master-agent.sh` (new file)
- **Action**: Create `init_master_agent()` function
- **Direct Instruction**:
  ```
  Create lib/master-agent.sh with:
  init_master_agent() {
    local FEATURE_DIR="$1"
    local PLAN_JSON="$2"
    mkdir -p "$FEATURE_DIR/master-context"
    echo "$PLAN_JSON" > "$FEATURE_DIR/master-context/phases.json"
    echo '{"agents": [], "active_phase": null}' > "$FEATURE_DIR/master-context/agents.json"
    return 0
  }
  ```

**Task 2.1.3**: Create planning agent call
- **Measurement**: Planning agent generates phase plan JSON
- **Location**: `lib/planning-agent.sh` (new file)
- **Action**: Create `generate_phase_plan()` function
- **Direct Instruction**:
  ```
  Create lib/planning-agent.sh with:
  generate_phase_plan() {
    local PROMPT="$1"
    local OUTPUT_FILE="$2"
    local PROMPT_TEXT="Analyze this task and create a multi-phase execution plan...
    $(cat prompt file)
    Return JSON: {\"phases\": [{\"name\": \"...\", \"instructions\": \"...\", \"depends_on\": []}]}"
    run_claude "$PROMPT_TEXT" "$OUTPUT_FILE" "sonnet"
    # Extract JSON and return
  }
  ```

**Task 2.1.4**: Create phase agent wrapper
- **Measurement**: Phase agent executes using existing `run_claude_agent()`
- **Location**: `lib/phase-agent.sh` (new file)
- **Action**: Wrap `run_claude_agent()` for phase execution
- **Direct Instruction**:
  ```
  Create lib/phase-agent.sh with:
  run_phase_agent() {
    local PHASE_NAME="$1"
    local PHASE_INSTRUCTIONS="$2"
    local FEATURE_DIR="$3"
    local PHASE_DIR="$FEATURE_DIR/phases/$PHASE_NAME"
    mkdir -p "$PHASE_DIR"
    echo "$PHASE_INSTRUCTIONS" > "$PHASE_DIR/AGENT-PROMPT.md"
    run_claude_agent "$PHASE_DIR/AGENT-PROMPT.md" "$PHASE_DIR/HANDOFF.md" "$OUTPUT_DIR/$PHASE_NAME" 10
    return $?
  }
  ```

**Task 2.1.5**: Create master coordination loop
- **Measurement**: Master agent executes phases in order
- **Location**: `lib/master-agent.sh`
- **Action**: Create `coordinate_phases()` function
- **Direct Instruction**:
  ```
  Add to lib/master-agent.sh:
  coordinate_phases() {
    local FEATURE_DIR="$1"
    local PHASES_JSON=$(cat "$FEATURE_DIR/master-context/phases.json")
    local PHASE_COUNT=$(echo "$PHASES_JSON" | jq '.phases | length')
    for i in $(seq 0 $((PHASE_COUNT - 1))); do
      local PHASE_NAME=$(echo "$PHASES_JSON" | jq -r ".phases[$i].name")
      local PHASE_INSTRUCTIONS=$(echo "$PHASES_JSON" | jq -r ".phases[$i].instructions")
      run_phase_agent "$PHASE_NAME" "$PHASE_INSTRUCTIONS" "$FEATURE_DIR"
      # Update master context
    done
  }
  ```

### Validation Criteria
- ✅ Master agent detects multi-phase need
- ✅ Planning agent generates phase plan
- ✅ Master agent coordinates phase execution
- ✅ Each phase maintains own context files
- ✅ Master agent tracks overall progress

---

## Boundary 3: Minimal Changes Principle

### Requirement
Keep existing functionality intact, only add on top, no regressions.

### Measurable Tasks

**Task 3.1.1**: Preserve single-agent flow
- **Measurement**: Existing single-agent execution unchanged
- **Location**: `lib/smart-agent.sh`, default behavior
- **Action**: Make multi-phase opt-in, not default
- **Direct Instruction**:
  ```
  After multi-phase detection (line ~149), add:
  if [[ "$IS_MULTI_PHASE" == "true" ]]; then
    # Multi-phase execution
    source "$SCRIPT_DIR/master-agent.sh"
    # ... master agent setup
  else
    # Existing single-agent flow (lines 211-229)
    run_claude_agent "${AGENT_ARGS[@]}"
  fi
  ```

**Task 3.1.2**: Preserve handoff system
- **Measurement**: Handoff files still created/updated as before
- **Location**: `lib/agent-runner.sh`, handoff calls unchanged
- **Action**: Add context files alongside handoffs, don't replace
- **Direct Instruction**:
  ```
  Keep ensure_handoff() call at line 346-353 unchanged
  Add context file update after handoff:
  ensure_context_files "$OUTPUT_FILE" "$FEATURE_DIR" "$i"
  ```

**Task 3.1.3**: No breaking changes to core functions
- **Measurement**: `run_claude()`, `generate_structured_output()` signatures unchanged
- **Location**: `lib/claude-functions.sh`
- **Action**: Don't modify these files
- **Direct Instruction**:
  ```
  DO NOT modify:
  - lib/claude-functions.sh
  - lib/handoff-functions.sh  
  - lib/code-review.sh
  Only add new files or minimal additions to agent-runner.sh
  ```

### Validation Criteria
- ✅ All existing tests pass
- ✅ Single-agent mode works identically
- ✅ Handoff system unchanged
- ✅ Core functions unchanged

---

## Boundary 4: Pattern Template

### Requirement
Create reusable pattern for all `.specs/` subdirectories.

### Measurable Tasks

**Task 4.1.1**: Document pattern structure
- **Measurement**: Pattern documented in template file
- **Location**: `templates/feature-spec-pattern.md` (new file)
- **Action**: Create pattern documentation
- **Direct Instruction**:
  ```
  Create templates/feature-spec-pattern.md with:
  # Feature Spec Pattern
  
  ## Required Structure
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
  [Master agent files if multi-phase]
  ```

**Task 4.1.2**: Auto-create pattern in smart-agent.sh
- **Measurement**: Context directory created automatically for all features
- **Location**: `lib/smart-agent.sh`, after FEATURE_DIR creation (line ~172)
- **Action**: Call `ensure_context_structure()` for all features
- **Direct Instruction**:
  ```
  After line 172, add:
  source "$SCRIPT_DIR/context-functions.sh"
  ensure_context_structure "$FEATURE_DIR"
  ```

**Task 4.1.3**: Update README pattern
- **Measurement**: README.md includes context file references
- **Location**: `lib/smart-agent.sh`, README generation (line ~188)
- **Action**: Add context files section to README template
- **Direct Instruction**:
  ```
  Update README template (line 188) to include:
  ## Context Files
  - [instructions.md](./context/instructions.md) - Phase instructions
  - [progress.md](./context/progress.md) - Progress tracking
  - [findings.md](./context/findings.md) - Discoveries
  - [achievements.md](./context/achievements.md) - Validated achievements
  ```

### Validation Criteria
- ✅ Pattern documented
- ✅ Pattern auto-created for all features
- ✅ Pattern consistent across directories

---

## Boundary 5: Simple Iteration Instruction

### Requirement
Add simple instruction to run iterations to create shared context files.

### Measurable Tasks

**Task 5.1.1**: Add context instruction to prompt
- **Measurement**: Every agent prompt includes context file instruction
- **Location**: `lib/agent-runner.sh`, prompt generation
- **Action**: Append context instruction block
- **Direct Instruction**:
  ```
  In generate_continuation_prompt() (line 440), add:
  
  ## Context File Maintenance (REQUIRED)
  
  After each iteration, you MUST update these files in context/:
  
  1. instructions.md: Write your complete instructions for this phase
  2. progress.md: Document what you've accomplished
  3. findings.md: Record discoveries, insights, issues found
  4. achievements.md: List validated achievements with proof/validation method
  
  Update these files BEFORE writing the handoff.
  ```

**Task 5.1.2**: Create context update helper
- **Measurement**: Function exists to update context files
- **Location**: `lib/context-functions.sh` (new file)
- **Action**: Create `update_context_from_output()` function
- **Direct Instruction**:
  ```
  Create lib/context-functions.sh:
  update_context_from_output() {
    local OUTPUT_FILE="$1"
    local FEATURE_DIR="$2"
    local ITERATION="$3"
    # Use Claude to extract context updates from output
    # Write to appropriate context files
  }
  ```

### Validation Criteria
- ✅ Instruction appears in every prompt
- ✅ Agents update context files
- ✅ Context files contain required information

---

## Implementation Checklist

### Phase 1: Context Files (Foundation)
- [ ] Task 1.1.1: Add context instruction to prompt
- [ ] Task 1.1.2: Create context directory structure function
- [ ] Task 1.1.3: Call structure creation in agent loop
- [ ] Task 5.1.1: Add detailed context instruction
- [ ] Task 5.1.2: Create context update helper

### Phase 2: Master Agent (Orchestration)
- [ ] Task 2.1.1: Detect multi-phase requirement
- [ ] Task 2.1.2: Create master agent initialization
- [ ] Task 2.1.3: Create planning agent
- [ ] Task 2.1.4: Create phase agent wrapper
- [ ] Task 2.1.5: Create master coordination loop

### Phase 3: Integration (Preservation)
- [ ] Task 3.1.1: Preserve single-agent flow
- [ ] Task 3.1.2: Preserve handoff system
- [ ] Task 3.1.3: Verify no breaking changes

### Phase 4: Pattern (Reusability)
- [ ] Task 4.1.1: Document pattern structure
- [ ] Task 4.1.2: Auto-create pattern in smart-agent
- [ ] Task 4.1.3: Update README pattern

## Testing Plan

1. **Unit Tests**: Test each function independently
2. **Integration Tests**: Test context files + handoff together
3. **Regression Tests**: Verify existing functionality unchanged
4. **Multi-Phase Tests**: Test master agent coordination
5. **Pattern Tests**: Verify pattern created correctly

## Success Metrics

- ✅ Context files created/updated automatically
- ✅ Master agent coordinates phases successfully
- ✅ Zero test failures in existing functionality
- ✅ Pattern consistent across all features
- ✅ Code changes minimal (< 200 lines added)
