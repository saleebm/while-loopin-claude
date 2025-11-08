# Important Things to Remember

## Correct Agent Syntax

✅ **CORRECT** - Pass the path to AGENT-PROMPT.md:
```bash
bun run agent ".specs/multi-phase-context-framework/AGENT-PROMPT.md"
```

❌ **WRONG** - Don't cd into the directory:
```bash
cd .specs/multi-phase-context-framework
bun run agent "prompt"
```

## The Plan We're Following

### Phase 1: Context Framework ✅ DONE
- Created lib/context-functions.sh
- Integrated into agent-runner.sh
- Fixed directory bug (now uses FEATURE_DIR/context)

### Phase 2: Master Agent Framework ⏳ IN PROGRESS
- Need to create lib/master-agent.sh
- Need to create lib/phase-agent.sh
- Need to create lib/planning-agent.sh
- Add multi-phase detection to smart-agent.sh

### Phase 3: Testing & Validation
- Test with simple tasks (should use single agent)
- Test with complex tasks (should trigger multi-phase)
- Verify context isolation between features

## Resume Command

To resume the agent where it left off:
```bash
RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=10 \
  bun run agent ".specs/multi-phase-context-framework/AGENT-PROMPT.md"
```

## Stay Focused

Don't get distracted by:
- Minor improvements
- Unrelated features
- Over-engineering

Focus on:
- Completing Phase 2 (Master Agent)
- Testing the implementation
- Keeping it simple and composable