# Repository Reorganization - Master Plan

## Current State (Nov 7, 2024)

### ✅ What We've Successfully Completed

1. **Documentation Reorganization**
   - Created ARCHITECTURE.md with system diagrams
   - Created API-SPEC.md with language-agnostic specifications
   - Consolidated QUICK-START.md for 5-minute onboarding
   - Updated README.md with navigation table
   - Added cross-linking between all docs

2. **Context Framework (Partial)**
   - ✅ Created lib/context-functions.sh (excellent quality)
   - ✅ Integrated into agent-runner.sh
   - ✅ Added prompt instructions for context
   - ✅ Created template files
   - ❌ **CRITICAL BUG**: Context files in wrong location

3. **Resume Functionality (Bonus)**
   - ✅ Added resume capability to agent-runner.sh
   - ✅ Created RESUME-IMPLEMENTATION.md
   - ✅ Created RESUME-QUICKSTART.md
   - ✅ Test suite in tests/test_resume.sh

### 🐛 Critical Bug to Fix

**Wrong Context Directory Location:**
- **Current (WRONG)**: `/context/` in project root
- **Should be**: `.specs/{feature-name}/context/`

**Fix Required in lib/agent-runner.sh line 369:**
```bash
# Current (WRONG):
local CONTEXT_DIR="$PROJECT_DIR/context"

# Should be:
local CONTEXT_DIR="$FEATURE_DIR/context"
```

### 📁 Files in Wrong Location

These files need to be moved:
- `/context/achievements.md` → Delete (test artifact)
- `/context/findings.md` → Delete (test artifact)
- `/context/instructions.md` → Delete (test artifact)
- `/context/progress.md` → Delete (test artifact)

### 🚧 What Still Needs Implementation

**Phase 2: Master Agent Framework** (0% Complete)
- [ ] Create lib/master-agent.sh
- [ ] Create lib/phase-agent.sh
- [ ] Create lib/planning-agent.sh
- [ ] Add multi-phase detection to smart-agent.sh
- [ ] Create master-context/ directory structure
- [ ] Implement phase coordination logic

## Action Plan

### Step 1: Fix Context Directory Bug (5 mins)

1. Fix path in lib/agent-runner.sh:
```bash
# Line 369 - Fix the path
local CONTEXT_DIR="$FEATURE_DIR/context"
```

2. Ensure FEATURE_DIR is properly set:
```bash
# Should already be set from OUTPUT_DIR or similar
# Verify it matches .specs/{feature-name}/ pattern
```

3. Clean up misplaced files:
```bash
rm -rf /context/  # Remove test artifacts from root
```

### Step 2: Test Context Framework (10 mins)

```bash
# Test 1: Simple task with context
bun run agent "Create a test file with Hello World"

# Verify context created in:
ls .specs/*/context/

# Test 2: Resume functionality
RESUME_AGENT=true bun run agent "Continue previous task"
```

### Step 3: Resume Context Framework Agent (15 mins)

Since the agent only ran 1 iteration and has resume functionality:

```bash
# Resume the context framework implementation
cd .specs/multi-phase-context-framework
RESUME_AGENT=true ENABLE_CODE_REVIEW=true MAX_ITERATIONS=10 \
  bun run agent "Continue implementing the multi-phase context framework.
  Focus on Phase 2: Create master-agent.sh, phase-agent.sh, and planning-agent.sh
  for multi-phase orchestration. The context framework is done but needs the
  context directory path fixed from PROJECT_DIR/context to FEATURE_DIR/context."
```

### Step 4: Validate Complete Implementation

After agent completes:

1. **Verify all components exist:**
   - lib/context-functions.sh ✅ (already done)
   - lib/master-agent.sh
   - lib/phase-agent.sh
   - lib/planning-agent.sh

2. **Test multi-phase execution:**
```bash
bun run agent "Build a complete todo app with authentication and database"
# Should trigger multi-phase orchestration
```

3. **Test single-agent fallback:**
```bash
bun run agent "Fix a typo in README"
# Should use regular single-agent mode
```

## File Organization

### Our Tracking (.specs/repo-reorganization/)
```
.specs/repo-reorganization/
├── PLAN.md                 # This file - master plan
├── HANDOFF.md              # Current state for handoff
├── PROGRESS.md             # What's been completed
├── ISSUES.md               # Issues found and fixes
└── context/                # Our own context tracking
    ├── instructions.md
    ├── progress.md
    ├── findings.md
    └── achievements.md
```

### Context Framework (.specs/multi-phase-context-framework/)
```
.specs/multi-phase-context-framework/
├── AGENT-PROMPT.md         # Original prompt
├── HANDOFF.md              # Agent's handoff
├── PLAN.md                 # Original plan
├── TASK-BREAKDOWN.md       # Detailed tasks
├── analysis.json           # Configuration
└── context/                # Framework's context
    ├── instructions.md
    ├── progress.md
    ├── findings.md
    └── achievements.md
```

## Success Criteria

✅ Context files created in `.specs/{feature}/context/` not root
✅ Master agent framework implemented
✅ Multi-phase orchestration working
✅ Resume functionality preserved
✅ No regression in existing features
✅ Clean repository structure
✅ All documentation accurate

## Key Principles to Remember

1. **Keep It Simple** - Don't over-engineer
2. **AI Does the Thinking** - Let Claude determine complexity
3. **Composability** - Each function should be reusable
4. **Minimal Changes** - Add features without breaking existing
5. **Feature Isolation** - Each feature gets its own spec folder

## Next Immediate Action

**YOU**: Fix the context directory bug in lib/agent-runner.sh line 369

**Then**: Test with a simple command to verify fix

**Finally**: Resume the context framework agent to complete Phase 2