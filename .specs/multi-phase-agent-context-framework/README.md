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

### Phase 1: Single-Agent Context Tracking
- **Goal**: Add context file enforcement to existing single-agent loops
- **Deliverables**: CONTEXT.md per run with progress/achievements/validation
- **Effort**: 2-3 hours agent work

### Phase 2: Phase Segmentation
- **Goal**: Support multiple phases within single agent run
- **Deliverables**: Phase-specific contexts, master aggregation
- **Effort**: 3-4 hours agent work

### Phase 3: Master Agent Orchestration
- **Goal**: Master agent coordinates multiple sub-agents across phases
- **Deliverables**: Planning agent, master coordination, sub-agent spawning
- **Effort**: 5-6 hours agent work

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
   - Enforces context file updates
   - Validates required sections
   - Logs achievements with validation

2. **Phase Manager** (`lib/phase-manager.sh`)
   - Detects phase transitions
   - Manages phase-specific contexts
   - Aggregates to master context

3. **Planning Agent** (`lib/planning-agent.sh`)
   - Breaks prompts into phases
   - Generates phase-specific prompts
   - Creates success criteria

4. **Master Agent** (`lib/master-agent.sh`)
   - Orchestrates sub-agents
   - Spawns phase-specific agents
   - Aggregates all contexts
   - Validates completion

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

## Meta Note

This is a unique project: we're using the While Loopin' Claude agent system to extend itself. The agent will read its own codebase, understand its architecture, and add new capabilities while preserving existing functionality.

This demonstrates the power of AI-orchestrated development: the system becomes a platform for building itself.
