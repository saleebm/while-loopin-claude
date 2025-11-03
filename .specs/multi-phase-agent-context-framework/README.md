# Multi-Phase Agent Context Framework

## Purpose
Framework for enforcing context tracking and multi-phase orchestration in While Loopin' Claude agent system.

## Status
**Planning Complete** - Awaiting user approval to begin implementation.

## Files in This Directory

### Planning Documents
- **ORIGINAL-PROMPT.txt** - Exact user request (word-for-word)
- **PLAN.md** - Detailed 3-phase implementation plan
- **AGENT-PROMPT.md** - Initialization prompt for Claude agent to implement
- **README.md** - This file

### Implementation Files (To Be Created)
After approval, implementation will create:
- `lib/context-tracking.sh` (Phase 1)
- `lib/phase-manager.sh` (Phase 2)
- `lib/planning-agent.sh` (Phase 3)
- `lib/master-agent.sh` (Phase 3)

## Quick Navigation

### For Review
1. Start with `ORIGINAL-PROMPT.txt` to see exact user request
2. Read `PLAN.md` for full implementation strategy
3. Review `AGENT-PROMPT.md` for execution instructions

### For Implementation
Once approved, run:
```bash
bun run agent .specs/multi-phase-agent-context-framework/AGENT-PROMPT.md
```

This will use the agent system to build itself (meta-programming).

## Implementation Overview

### Phase 1: Context Tracking
- **Goal**: Add context file to existing loop
- **Deliverables**: CONTEXT.md per run with progress/achievements/validation
- **Complexity**: 7 points

### Phase 2: Phase Support
- **Goal**: Detect phases, isolate contexts
- **Deliverables**: Phase dirs, master aggregation
- **Complexity**: 15 points

### Phase 3: Master Orchestration
- **Goal**: Planning agent + phase-aware execution within single run
- **Deliverables**: PHASE-PLAN.json, phase coordination (no sub-agents)
- **Complexity**: 18 points

**Total**: 40 complexity points

## Key Principles

✅ **Zero Regression** - Build on top, don't modify core  
✅ **Minimal Changes** - New files over modifying existing  
✅ **Simplicity First** - Start simple, add complexity only when needed  
✅ **Follow Patterns** - Use existing architecture patterns  
✅ **Test Continuously** - Validate at each phase  

## Design Constraints

From user requirements:
- Must NOT break existing functionality
- Must use existing `.specs/` pattern
- Must build on existing agent-runner.sh infrastructure
- Must follow "first principles" of the system
- Must be minimal and simple

## Architecture Summary

### Extension Points
1. **Agent Loop Hook** (agent-runner.sh:386)
   - After handoff generation
   - Before rate limiting
   - Add context tracking call

2. **Handoff Enhancement** (handoff-functions.sh)
   - Add phase tracking fields
   - Add achievement validation tracking

3. **Prompt Enhancement** (generate_continuation_prompt)
   - Add context maintenance instructions
   - Add phase awareness

### New Components
1. **Context Tracking** (`lib/context-tracking.sh`)
   - Enforces CONTEXT.md updates
   - Validates sections
   - Logs achievements with validation

2. **Phase Manager** (`lib/phase-manager.sh`)
   - Detects phase transitions
   - Phase-specific contexts
   - Master aggregation

3. **Planning Agent** (`lib/planning-agent.sh`)
   - AI breaks prompts into phases
   - Generates PHASE-PLAN.json
   - Injects phase info into iterations

**No new commands** - extends existing `bun run agent`  
**No sub-agents** - single run with phase awareness  
**Default enabled** - disable via `ENABLE_CONTEXT_TRACKING=false`

## Testing Strategy

### Phase 1 Tests
- Simple single-action test
- Verify CONTEXT.md created
- Verify sections populated
- Verify no regression

### Phase 2 Tests
- Multi-phase single-agent test
- Verify phase transitions
- Verify context isolation
- Verify master aggregation

### Phase 3 Tests
- Complex multi-phase coordination
- Verify planning agent
- Verify sub-agent spawning
- Verify master orchestration
- Verify dependency handling

## Risk Mitigation

1. **Context File Bloat**: Cap at 10KB, summarize/archive when hit
2. **Phase Detection Ambiguity**: Use explicit markers, validate with AI
3. **Master Agent Complexity**: Start sequential only, linear dependencies
4. **Performance Overhead**: Async operations, non-blocking

## Next Actions

**Waiting on user approval for**:
1. Overall plan structure and approach
2. Context file format adequacy
3. Whether to implement all 3 phases or start with Phase 1 only
4. Any additional requirements or modifications

Once approved, will execute:
```bash
bun run agent .specs/multi-phase-agent-context-framework/AGENT-PROMPT.md
```

---

## Master Agent (User POV)

**Purpose:** Breaks complex tasks into sequential phases, maintains context, validates completion.

**Best for:**
- Multi-step workflows with dependencies
- Tasks requiring different approaches per phase  
- Projects needing validation gates
- Long tasks needing progress tracking

**Key qualities:**
- Autonomous phase planning
- Context preservation
- Achievement validation enforcement
- Per-phase failure recovery
- Progress visibility

---

## Meta Note

Using While Loopin' Claude to extend itself - reading own codebase, adding capabilities while preserving functionality. System builds itself.
