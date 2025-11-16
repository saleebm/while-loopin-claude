# Multi-Phase Agent Context Framework - Implementation Plan

## Core Requirements (From Original Prompt)

1. **Context tracking** - agents update context files each iteration
   - Instructions for current phase
   - Progress, findings, thoughts
   - Achievements **with validation methods**

2. **Multi-phase support** - master tracks phases
   - Planning agent defines phases
   - Master orchestrates phase execution
   - Handoffs between phases

3. **Design constraints**
   - Zero regression
   - Minimal changes
   - Build ON TOP of existing
   - Enabled by default, can disable
   - Use existing `bun run agent` command

---

## Architecture Analysis (Current System)

**Existing components:**
- `agent-runner.sh` - main loop, handoff generation (line 346), completion check (line 359)
- `handoff-functions.sh` - auto-generates handoff each iteration
- `smart-agent.sh` - AI config, creates `.specs/`, invokes runner

**Extension points:**
- Line 386 agent-runner.sh (after handoff, before rate limit) - add context tracking
- Line 444 agent-runner.sh (`generate_continuation_prompt`) - add context instructions
- `ensure_handoff()` - extend with phase/validation fields

---

## Implementation Plan (3 Phases by Complexity)

### Phase 1: Context Tracking (Complexity: Low)
**Scope**: Add context file to existing loop

**Files:**
- NEW: `lib/context-tracking.sh`
- MODIFY: `lib/agent-runner.sh` (2 locations: line 386 hook, line 444 prompt)

**Functions:**
```bash
ensure_context_tracking()  # Called at line 386
validate_context_file()    # Checks required sections
```

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

**Changes:**
1. Line 386 agent-runner.sh - add hook after handoff
2. Line 444 agent-runner.sh - add context instructions to prompt
3. Enable by default, disable via `ENABLE_CONTEXT_TRACKING=false`

**Complexity breakdown:**
- Create context-tracking.sh: 3 points
- Add hook to agent-runner.sh: 1 point
- Enhance prompt: 2 points
- Test: 1 point
**Total: 7 complexity points**

---

### Phase 2: Phase Support (Complexity: Medium)
**Scope**: Detect phases, isolate contexts per phase

**Files:**
- NEW: `lib/phase-manager.sh`
- MODIFY: `lib/handoff-functions.sh` (add phase fields)
- MODIFY: `templates/handoff-system-prompt.md` (add phase section)

**Functions:**
```bash
detect_phase_transition()  # Check handoff for phase change
initialize_phase()         # Create phase dir
summarize_phase()          # Aggregate to master
```

**Structure:**
```
{run-id}/
├── phases/phase-1/CONTEXT.md
├── phases/phase-2/CONTEXT.md
└── MASTER-CONTEXT.md
```

**Handoff additions:**
```markdown
## Current Phase
Phase: setup
Status: active

## Next Phase  
Name: implementation
Ready: yes
```

**Complexity breakdown:**
- Create phase-manager.sh: 5 points
- Extend handoff template: 2 points
- Integrate phase detection: 3 points
- Master context aggregation: 3 points
- Test: 2 points
**Total: 15 complexity points**

---

### Phase 3: Master Orchestration (Complexity: High)
**Scope**: Planning agent + master coordination within existing command

**Files:**
- NEW: `lib/planning-agent.sh`  
- MODIFY: `lib/smart-agent.sh` (add phase plan step before run_claude_agent)

**Key point**: NOT a new command. `bun run agent` auto-detects multi-phase from prompt analysis, generates PHASE-PLAN.json, uses it to coordinate context/handoffs within single agent run.

**Functions:**
```bash
generate_phase_plan()      # AI analyzes prompt, creates plan
apply_phase_context()      # Injects phase info into iteration
validate_phase_complete()  # Check criteria met
```

**Flow:**
1. `bun run agent "complex prompt"`
2. smart-agent.sh analyzes → detects multi-phase
3. planning-agent generates PHASE-PLAN.json
4. agent-runner uses plan to coordinate phases
5. Each iteration knows current phase from plan
6. Context tracking uses phase info
7. Handoff tracks phase transitions
8. Master context aggregates all

**No sub-agent spawning** - single agent run with phase awareness.

**Complexity breakdown:**
- Create planning-agent.sh: 5 points
- Integrate into smart-agent analysis: 3 points
- Phase-aware prompting: 4 points
- Phase completion validation: 3 points
- Test complex multi-phase: 3 points
**Total: 18 complexity points**

---

## Simplified Implementation Steps

### Step 1: Context Tracking (7 complexity points)

**Create** `lib/context-tracking.sh`:
```bash
ensure_context_tracking() {
  local RUN_OUTPUT_DIR="$1"
  local ITERATION="$2"
  local HANDOFF_FILE="$3"
  # Extract from handoff, append to CONTEXT.md
}

validate_context_file() {
  # Check required sections present
}
```

**Modify** `lib/agent-runner.sh`:
- Line 386: Add `ensure_context_tracking "$RUN_OUTPUT_DIR" "$i" "$HANDOFF_FILE"`
- Line 444: Add context instructions to continuation prompt
- Add env var: `ENABLE_CONTEXT_TRACKING="${ENABLE_CONTEXT_TRACKING:-true}"`

**Prompt addition:**
```markdown
## Context Tracking
Update CONTEXT.md each iteration:
- Instructions for phase
- Progress/findings
- Achievements with validation
```

---

### Step 2: Phase Support (15 complexity points)

**Create** `lib/phase-manager.sh`:
```bash
detect_phase_transition()  # Check handoff for phase change
initialize_phase()         # Create phases/{name}/
summarize_phase()          # Aggregate to MASTER-CONTEXT.md
```

**Modify** `lib/handoff-functions.sh`:
- Add phase fields to handoff template

**Modify** `templates/handoff-system-prompt.md`:
```markdown
## Phase Tracking
Current Phase: [name]
Status: [active|complete]
Next Phase: [name or none]
Ready: [yes|no]
```

**Integrate** into agent-runner.sh:
- After handoff, check `detect_phase_transition()`
- If new phase, call `initialize_phase()`
- Summarize completed phase to master

---

### Step 3: Master Orchestration (18 complexity points)

**Create** `lib/planning-agent.sh`:
```bash
generate_phase_plan() {
  # AI analyzes prompt → PHASE-PLAN.json
}

apply_phase_context() {
  # Inject phase info into iteration prompt
}

validate_phase_complete() {
  # Check criteria met
}
```

**Modify** `lib/smart-agent.sh`:
- After AI analysis, before `run_claude_agent()`
- If multi-phase detected, generate PHASE-PLAN.json
- Pass plan to agent-runner

**Modify** `lib/agent-runner.sh`:
- Read PHASE-PLAN.json if exists
- Inject current phase into continuation prompt
- Track phase completion in handoff

**Flow:**
1. `bun run agent "complex prompt"` (same command)
2. smart-agent analyzes → detects multi-phase
3. planning-agent creates PHASE-PLAN.json
4. agent-runner reads plan
5. Each iteration knows current phase
6. Context tracking uses phase info
7. Master context aggregates

**No new command, no sub-agents** - single run with phase awareness.

---

## Total Complexity: 40 points
- Phase 1: 7 points
- Phase 2: 15 points  
- Phase 3: 18 points

---

## Config Defaults

```bash
# lib/agent-runner.sh additions
ENABLE_CONTEXT_TRACKING="${ENABLE_CONTEXT_TRACKING:-true}"  # Default ON
ENABLE_PHASE_DETECTION="${ENABLE_PHASE_DETECTION:-true}"   # Default ON
```

Disable if needed:
```bash
ENABLE_CONTEXT_TRACKING=false bun run agent "prompt"
```

---

## Master Agent Purpose (User POV)

**What it does:**
Orchestrates complex tasks by breaking into sequential phases, maintaining context across transitions, validating completion at each stage.

**Most effective for:**
- Multi-step workflows with dependencies
- Tasks requiring different skills/approaches per phase
- Projects needing validation gates between stages
- Long-running tasks where progress tracking critical

**Key qualities:**
- Autonomous phase planning
- Context preservation across phases
- Achievement validation enforcement
- Failure recovery per phase
- Progress visibility throughout
