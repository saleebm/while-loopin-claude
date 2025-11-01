# Implementation Prompt: Multi-Phase Agent Context Framework

## Original User Request
See `ORIGINAL-PROMPT.txt` for exact user requirements.

## Your Mission
Implement a context tracking framework for the While Loopin' Claude agent system that:

1. **Enforces context file maintenance** across agent iterations
2. **Tracks progress, findings, achievements, and validation** in structured files
3. **Supports multi-phase execution** with phase-specific context
4. **Provides master agent orchestration** for complex multi-phase tasks
5. **Builds on existing infrastructure** without causing regression

## Implementation Plan
Full detailed plan in `PLAN.md`. Follow the 3-phase approach:

### Phase 1: Single-Agent Context Tracking
**Deliverables**:
- `lib/context-tracking.sh` - Context file management functions
- Modifications to `lib/agent-runner.sh` (add hook at line ~386)
- Enhanced prompt in `generate_continuation_prompt()` function
- `CONTEXT.md` created per agent run with required sections

**Key Functions**:
```bash
ensure_context_tracking()  # Called after handoff generation
validate_context_file()    # Checks required sections present
append_achievement()       # Logs achievements with validation
```

**Context File Structure**:
```markdown
# Agent Context - Iteration N

## Phase Instructions
- Current phase requirements

## Progress
- Completed items
- In progress items

## Findings
- Key discoveries
- Blockers

## Achievements
- [Achievement]: Validated by [method]
- [Achievement]: Validated by [method]

## Next Steps
- Planned actions
```

**Testing**: Run simple test prompt, verify CONTEXT.md created and maintained.

---

### Phase 2: Phase Segmentation
**Deliverables**:
- `lib/phase-manager.sh` - Phase detection and management
- Modifications to `lib/handoff-functions.sh` (add phase fields)
- Enhanced `templates/handoff-system-prompt.md` (add phase section)
- Phase directory structure: `{run-dir}/phases/{phase-name}/`

**Key Functions**:
```bash
detect_phase_transition()  # Checks handoff for phase change
initialize_phase()         # Creates phase-specific context
summarize_phase()          # Archives phase when complete
get_current_phase()        # Returns active phase
```

**Directory Structure**:
```
.ai-dr/agent-runs/{feature}/{run-id}/
├── iteration_*.log
├── HANDOFF.md
├── MASTER-CONTEXT.md
└── phases/
    ├── phase-1-setup/
    │   ├── CONTEXT.md
    │   └── ACHIEVEMENTS.md
    └── phase-2-implementation/
        ├── CONTEXT.md
        └── ACHIEVEMENTS.md
```

**Testing**: Run multi-phase prompt, verify phase transitions and context isolation.

---

### Phase 3: Master Agent Orchestration
**Deliverables**:
- `lib/master-agent.sh` - Master coordination functions
- `lib/planning-agent.sh` - AI-driven phase planning
- Modifications to `lib/smart-agent.sh` (add multi-phase detection)
- `PHASE-PLAN.json` generated for complex prompts

**Key Functions**:
```bash
# planning-agent.sh
generate_phase_plan()      # AI breaks prompt into phases
create_phase_prompts()     # Creates per-phase prompts
validate_plan()            # Ensures plan is sound

# master-agent.sh
run_master_agent()         # Orchestrates sub-agents
spawn_sub_agent()          # Launches phase-specific agent
aggregate_contexts()       # Merges all phase contexts
check_phase_completion()   # Validates success criteria
```

**Testing**: Run complex prompt requiring multiple coordinated phases.

---

## Critical Implementation Rules

### DO:
✅ Follow existing code style and patterns  
✅ Use existing helper functions (`run_claude()`, `generate_structured_output()`)  
✅ Add comprehensive comments explaining new functionality  
✅ Make all additions opt-in via feature flags initially  
✅ Test each phase before moving to next  
✅ Document all new functions with usage examples  
✅ Preserve exact handoff format for compatibility  

### DON'T:
❌ Modify core agent loop logic (lines 304-393 in agent-runner.sh)  
❌ Change existing function signatures  
❌ Break existing test cases  
❌ Add complexity to existing files - create new files instead  
❌ Skip testing - validate at each phase  
❌ Introduce new dependencies (use bash, jq, claude CLI only)  

---

## Step-by-Step Execution Instructions

### Before Starting
1. Read all existing library files thoroughly
2. Review `PLAN.md` for full context
3. Understand existing handoff mechanism
4. Identify exact hook points for new code

### Phase 1 Implementation
1. Create `lib/context-tracking.sh` with all functions
2. Add hook to `lib/agent-runner.sh` (line ~386)
3. Enhance `generate_continuation_prompt()` in agent-runner.sh
4. Test with simple prompt: "Create test file"
5. Verify CONTEXT.md exists and is populated
6. Verify existing functionality unchanged

### Phase 2 Implementation
1. Create `lib/phase-manager.sh` with all functions
2. Modify `lib/handoff-functions.sh` to add phase fields
3. Update `templates/handoff-system-prompt.md` with phase section
4. Integrate phase detection into agent loop
5. Test with multi-phase prompt
6. Verify phase isolation and aggregation

### Phase 3 Implementation
1. Create `lib/planning-agent.sh` with planning functions
2. Create `lib/master-agent.sh` with orchestration functions
3. Modify `lib/smart-agent.sh` to detect multi-phase prompts
4. Implement sub-agent spawning and coordination
5. Test with complex 3+ phase prompt
6. Verify all contexts aggregate correctly

---

## Testing Requirements

After **each phase**, run:

1. **Existing tests** (must all pass):
   ```bash
   bash tests/test_handoff.sh
   bash tests/test_loop.sh
   ```

2. **New functionality tests**:
   ```bash
   # Phase 1 test
   bun run agent "Create hello.txt with 'Hello World'"
   # Verify CONTEXT.md exists
   
   # Phase 2 test
   bun run agent "Phase 1: Create file. Phase 2: Modify file."
   # Verify phases/ directory and MASTER-CONTEXT.md
   
   # Phase 3 test
   bun run agent "Complex task requiring 3+ coordinated phases"
   # Verify PHASE-PLAN.json and sub-agent outputs
   ```

3. **Regression check**:
   - Compare output structure before/after
   - Ensure handoff format unchanged
   - Verify completion detection works
   - Check rate limiting preserved

---

## Success Criteria

### Phase 1 Complete When:
- ✅ CONTEXT.md generated per run
- ✅ All required sections present
- ✅ Agent updates context during iterations
- ✅ Existing tests pass
- ✅ No performance degradation

### Phase 2 Complete When:
- ✅ Phase transitions detected automatically
- ✅ Phase-specific contexts isolated
- ✅ MASTER-CONTEXT.md aggregates phases
- ✅ Phase handoff format established
- ✅ Backward compatible with single-phase

### Phase 3 Complete When:
- ✅ Complex prompts auto-split into phases
- ✅ Sub-agents spawn per phase
- ✅ Master tracks all sub-agent progress
- ✅ Dependencies enforced
- ✅ Final aggregated context complete

---

## Handoff Requirements

After each implementation session, update `HANDOFF.md` with:

1. **Work Completed**: Which files created/modified
2. **Testing Results**: What tests were run and results
3. **Issues Found**: Any blockers or problems
4. **Achievements**: Completed functionality with validation method
5. **Next Steps**: What to implement next
6. **Status**: Current phase completion status

Use format:
```markdown
# Agent Handoff - Multi-Phase Context Framework

## Session End
Status: [in_progress|complete]

## Current Phase
Phase [1|2|3] of 3 - [phase name]

## Work Completed
- Created: [files]
- Modified: [files]
- Implemented: [functions]

## Testing Results
- Test 1: [passed|failed] - [details]
- Test 2: [passed|failed] - [details]

## Achievements
- Achievement: Implemented X. Validated by: Running Y and verifying Z.
- Achievement: Added Z. Validated by: Test T passing.

## Findings
- [Key discoveries]
- [Blockers encountered]

## Next Steps
1. [Next immediate action]
2. [Following action]
3. [Alternative if blocked]

## Investigation Notes
[Technical details, error messages, etc.]
```

---

## Additional Context

### Existing System Behavior to Preserve
- Iteration loop (1 to MAX_ITERATIONS)
- Handoff generation via Haiku
- "Session End" completion detection
- Code review cycle (optional)
- Rate limiting (15s between iterations)
- Speech feedback (optional)

### Extension Points Available
- Line 386 in agent-runner.sh (after handoff, before rate limit)
- Handoff template (templates/handoff-system-prompt.md)
- Continuation prompt (generate_continuation_prompt function)
- Smart agent analysis (smart-agent.sh AI analysis section)

### Helper Functions You Can Use
- `run_claude()` - Execute Claude and save output
- `generate_structured_output()` - Extract JSON from Claude response
- `run_claude_json()` - Execute Claude expecting JSON
- `ensure_handoff()` - Generate/update handoff file
- All bash utilities (jq, sed, grep, etc.)

---

## References

- Full implementation plan: `PLAN.md`
- Original user request: `ORIGINAL-PROMPT.txt`
- System architecture: `/workspace/CLAUDE.md`
- Example integrations: `/workspace/examples/`
- Core agent loop: `/workspace/lib/agent-runner.sh`
- Handoff system: `/workspace/lib/handoff-functions.sh`

---

## Ready to Begin?

Read `PLAN.md` thoroughly, then proceed with **Phase 1** implementation.

Document everything as you go. Test frequently. Ask questions if requirements unclear.

**Start with Phase 1 only. Do not proceed to Phase 2 until Phase 1 is complete and tested.**
