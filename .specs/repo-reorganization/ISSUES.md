# Issues Tracker - Repository Reorganization

## Issue #1: Context Directory in Wrong Location

### Problem
Context files are being created at project root `/context/` instead of feature-specific `.specs/{feature-name}/context/`

### Root Cause
Line 369 in lib/agent-runner.sh uses PROJECT_DIR instead of FEATURE_DIR:
```bash
local CONTEXT_DIR="$PROJECT_DIR/context"  # WRONG
```

### Impact
- ❌ Multiple features would share same context (collision)
- ❌ Violates feature isolation principle
- ❌ Context not portable with feature spec
- ❌ Breaks the intended pattern

### Fix
```bash
# lib/agent-runner.sh line 369
local CONTEXT_DIR="$FEATURE_DIR/context"  # CORRECT
```

### Verification
```bash
# After fix, run:
bun run agent "Test task"
# Check context created in:
ls .specs/*/context/
# Should NOT be in:
ls /context/
```

### Status
🔴 **UNFIXED** - Needs immediate attention

---

## Issue #2: FEATURE_DIR Variable Not Set

### Problem
FEATURE_DIR variable might not be properly set in agent-runner.sh

### Investigation Needed
Check if FEATURE_DIR is:
1. Declared and set properly
2. Derived from OUTPUT_DIR or PROMPT_FILE
3. Available in context where used

### Potential Fix
```bash
# Ensure FEATURE_DIR is set, perhaps:
FEATURE_DIR=$(dirname $(dirname "$OUTPUT_DIR"))
# Or derive from prompt file location
```

### Status
🟡 **NEEDS INVESTIGATION**

---

## Issue #3: Orphaned Context Files in Root

### Problem
Test context files exist in `/context/` directory at project root

### Files to Remove
- /context/achievements.md
- /context/findings.md
- /context/instructions.md
- /context/progress.md

### Fix
```bash
rm -rf ./context/  # Remove from project root
```

### Status
🟡 **CLEANUP NEEDED**

---

## Issue #4: Agent Stopped Early

### Problem
The context framework agent only ran 1 iteration despite MAX_ITERATIONS=15

### Possible Causes
- Agent thought it was complete
- Error occurred
- Manual interruption

### Investigation
Check .ai-dr/agent-runs/ for the last run to understand why it stopped

### Fix
Use RESUME_AGENT=true to continue where it left off

### Status
🟢 **RECOVERABLE** - Can resume

---

## Issue #5: Master Agent Not Started

### Problem
Phase 2 (master agent framework) was not started - no files created:
- lib/master-agent.sh
- lib/phase-agent.sh
- lib/planning-agent.sh

### Impact
Multi-phase orchestration not available

### Fix
Resume agent with clear instructions to implement Phase 2

### Status
🟡 **TODO** - Pending after context fix

---

## Fixed Issues

### ✅ Issue #0: Documentation Scattered
**Fixed**: Created ARCHITECTURE.md, API-SPEC.md, consolidated QUICK-START.md
**Date**: Nov 7, 2024

---

## Priority Order

1. 🔴 Fix context directory path (Issue #1)
2. 🟡 Verify FEATURE_DIR variable (Issue #2)
3. 🟡 Clean up orphaned files (Issue #3)
4. 🟢 Resume agent for Phase 2 (Issue #4, #5)