# Implementation: Multi-Phase Agent Context Framework

## Original Request
See `ORIGINAL-PROMPT.txt`

## Mission
Add context tracking + multi-phase support to existing `bun run agent` command. Enabled by default. Zero regression.

## Full Plan
See `PLAN.md` for complete breakdown (40 complexity points across 3 phases).

---

## Phase 1: Context Tracking (7 points)

**Create** `lib/context-tracking.sh`:
```bash
ensure_context_tracking() {
  # Extract from HANDOFF.md → CONTEXT.md
  # Validate required sections
}
```

**Modify** `lib/agent-runner.sh`:
- Line 76: Add `ENABLE_CONTEXT_TRACKING="${ENABLE_CONTEXT_TRACKING:-true}"`
- Line 386: Add hook calling `ensure_context_tracking()`
- Line 444: Enhance `generate_continuation_prompt()` with context instructions

**Context structure:**
```markdown
# Context - Iteration N
## Phase Instructions
## Progress
## Findings  
## Achievements
- X: Validated by Y
## Next Steps
```

**Test:** Run simple prompt, verify CONTEXT.md created.

---

## Phase 2: Phase Support (15 points)

**Create** `lib/phase-manager.sh`:
```bash
detect_phase_transition()  # Parse handoff
initialize_phase()         # Create phases/{name}/
summarize_phase()          # Aggregate to MASTER-CONTEXT.md
```

**Modify** `lib/handoff-functions.sh`:
- Add phase fields to template

**Modify** `templates/handoff-system-prompt.md`:
- Add phase tracking section

**Integrate** into agent-runner.sh:
- Check phase transitions after handoff
- Initialize new phases
- Aggregate completed phases

**Test:** Multi-phase prompt, verify phase directories + master context.

---

## Phase 3: Master Orchestration (18 points)

**Create** `lib/planning-agent.sh`:
```bash
generate_phase_plan()      # AI → PHASE-PLAN.json
apply_phase_context()      # Inject phase into prompt
validate_phase_complete()  # Check criteria
```

**Modify** `lib/smart-agent.sh`:
- After analysis, before `run_claude_agent()`
- Detect multi-phase → generate plan
- Pass plan to runner

**Modify** `lib/agent-runner.sh`:
- Read PHASE-PLAN.json if exists
- Inject phase info into iterations
- Track completion per phase

**Flow:**
`bun run agent "complex prompt"` → analysis detects multi-phase → generates plan → single agent run uses plan for phase coordination.

**Test:** Complex prompt, verify PHASE-PLAN.json + phase-aware execution.

---

## Critical Rules

**DO:**
- Build on existing hooks (line 386, 444)
- Enable by default (`true`)
- Use existing patterns (`run_claude()`, `generate_structured_output()`)
- Test after each phase
- Preserve backward compatibility

**DON'T:**
- Create new CLI commands
- Modify core loop logic
- Break existing tests
- Add sub-agent spawning (single run only)

---

## Implementation Order

1. Read existing files: agent-runner.sh, handoff-functions.sh, smart-agent.sh
2. Implement Phase 1 (context tracking)
3. Test Phase 1
4. Implement Phase 2 (phase support)
5. Test Phase 2
6. Implement Phase 3 (master orchestration)
7. Test Phase 3
8. Update HANDOFF.md after each phase

---

## Success Criteria

**Phase 1:**
- CONTEXT.md exists per run
- All sections populated
- No regression

**Phase 2:**
- Phase transitions detected
- Phase-specific contexts
- Master aggregation works

**Phase 3:**
- Complex prompts auto-plan
- Phase-aware execution
- Completion validation

---

## Handoff Format

After each session:
```markdown
# Handoff - Multi-Phase Context Framework

Session End
Status: [in_progress|complete]

## Current Phase
Phase [1|2|3] - [name]

## Work Completed
- Files: [created/modified]
- Functions: [implemented]

## Testing
- Test: [result]

## Achievements
- X: Validated by Y

## Next Steps
1. [next action]

## Findings
[discoveries/blockers]
```

---

## Start

Read `PLAN.md`, implement Phase 1, test, document, proceed.
