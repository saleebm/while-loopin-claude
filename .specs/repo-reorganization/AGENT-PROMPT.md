# Repository Cleanup & Validation Agent Task

You are an autonomous AI agent tasked with cleaning up and validating the while-loopin-claude repository. The system is fully implemented but needs validation and organization.

**Core Philosophy**: You make all the decisions. Don't ask for human input. Analyze, decide, execute. The human ran this agent because they want you to handle everything optimally without their involvement.

## Background

The repository contains a sophisticated agent system with:
- Standard single-phase agent execution
- Multi-phase master agent orchestration
- Context file management system
- Resume functionality
- Code review integration

All features are IMPLEMENTED and working. Your job is to validate, clean up, and ensure documentation accuracy.

## Your Tasks

### 1. Initial Cleanup (5 minutes)

First, commit the pending changes:
```bash
# There are 2 files with whitespace changes
git add lib/STRUCTURED-JSON-EXTRACTION.md lib/resume-agent.sh
git commit -m "chore: Clean up whitespace in documentation and scripts"

# Commit the new test suite
git add .specs/system-validation/
git commit -m "test: Add comprehensive system validation test suite"
```

Then remove stale development directories:
```bash
# These are old iterations no longer needed
rm -rf .specs/agent-configuration-analyzer
rm -rf .specs/prompt-analysis-agent-config
rm -rf .specs/prompt-analysis-configuration-system
rm -rf .specs/validation  # Old version, replaced by system-validation
```

### 2. Run System Validation (30 minutes)

Execute the comprehensive test suite that's already prepared:
1. Start with the quick tests in `.specs/system-validation/AGENT-PROMPT.md`
2. Then run the full test plan from `.specs/system-validation/TEST-HANDOFF.md`

Test categories to validate:
- **Basic Tasks**: Simple file creation and editing
- **Multi-Phase Tasks**: Complex tasks that trigger master agent
- **Resume Functionality**: State preservation across sessions
- **Context Framework**: Proper creation and updates of context files
- **Code Review**: Integration with review cycle
- **Examples**: All scripts in examples/ directory
- **Error Handling**: Graceful failure scenarios
- **Configuration**: Environment variable handling

Document results in `.specs/system-validation/VALIDATION-REPORT.md` with:
- Test name and description
- Pass/Fail status
- Any errors or issues found
- Performance observations
- Recommendations

### 3. Documentation Audit (15 minutes)

Review and organize documentation:

#### Check Core Docs Accuracy
- **CLAUDE.md**: Update to show features as COMPLETE not pending
- **ARCHITECTURE.md**: Ensure it reflects current implementation
- **README.md**: Verify examples and instructions are current
- **QUICK-START.md**: Test that quickstart steps work

#### Organize Supporting Docs
Consider creating a `docs/` directory for non-core documentation:
```bash
mkdir -p docs/features
# Move feature-specific docs
mv RESUME-IMPLEMENTATION.md docs/features/ 2>/dev/null || true
mv RESUME-QUICKSTART.md docs/features/ 2>/dev/null || true
mv LIVE-MODE-SUMMARY.md docs/features/ 2>/dev/null || true
```

#### Remove Redundant Files
- Check if SUMMARY.md duplicates README.md
- Verify INSTALL.md is still needed
- Evaluate QUICKREF.md purpose

### 4. Examples Testing (10 minutes)

Test all example scripts:
```bash
# Quick test should work immediately
bash examples/quick-test.sh

# Test interactive prompts
bash examples/test-interactive-prompts.sh

# Try master agent demo (may need to interrupt after confirming it starts)
timeout 30 bash examples/master-agent-demo.sh || true

# Document any broken examples
```

### 5. Shell Script Validation (5 minutes)

Validate syntax of all shell scripts:
```bash
for script in lib/*.sh examples/*.sh; do
  if bash -n "$script" 2>/dev/null; then
    echo "✅ $script - Valid syntax"
  else
    echo "❌ $script - SYNTAX ERROR"
    bash -n "$script"  # Show the actual error
  fi
done
```

### 6. Create Completion Report

Create `.specs/repo-reorganization/COMPLETION-REPORT.md` with:

```markdown
# Repository Cleanup Completion Report

## Executive Summary
- Original assumptions vs. reality
- What was actually done
- Current state of repository

## Actions Taken
- [ ] Committed pending changes
- [ ] Removed stale directories
- [ ] Ran validation tests
- [ ] Updated documentation
- [ ] Tested examples
- [ ] Validated scripts

## Test Results Summary
[Summary of validation suite results]

## Issues Found & Fixed
[Any problems discovered and how they were resolved]

## Documentation Updates
[What docs were updated/moved/removed]

## Current Repository State
- All features: OPERATIONAL
- Documentation: ACCURATE
- Examples: WORKING
- Tests: PASSING

## Recommendations
[Future improvements or maintenance tasks]
```

## Important Notes

1. **The system is COMPLETE** - Don't try to "fix" the context path bug or implement Phase 2, they're already done
2. **Focus on VALIDATION** - Test that everything works as designed
3. **Document REALITY** - Update docs to reflect what actually exists
4. **Use the SYSTEM** - Run tests using the agent's own capabilities
5. **Be THOROUGH** - Check everything but don't over-engineer
6. **BE AUTONOMOUS** - Make all decisions yourself. The human chose to run an AI agent specifically to avoid decision fatigue
7. **THINK AND EXECUTE** - Analyze situations, make optimal choices, adapt to what you find

## Context Files

Make sure to update your context files in `.specs/repo-reorganization/context/`:
- **instructions.md** - Track what phase of cleanup you're in
- **progress.md** - Mark milestones as you complete them
- **findings.md** - Document any issues or discoveries
- **achievements.md** - List what you've successfully validated/fixed

## Success Criteria

You are successful when:
- ✅ No uncommitted changes remain (except your report)
- ✅ No stale .specs directories exist
- ✅ Validation tests have been run and documented
- ✅ Documentation accurately reflects implementation
- ✅ Examples work (or issues are documented)
- ✅ Completion report is comprehensive

## Available Environment Variables

```bash
# You may need these during testing:
ENABLE_SPEECH=false       # Don't use speech output
ENABLE_CODE_REVIEW=true   # Test code review integration
MAX_ITERATIONS=5          # Limit iterations for testing
RATE_LIMIT_SECONDS=2      # Faster for testing
INTERACTIVE_MODE=false    # Skip interactive prompts
```

Remember: The goal is to validate and document the WORKING system, not to implement new features or fix imaginary bugs.

Good luck! The system you're validating is well-built and should pass most tests. Focus on being thorough and accurate in your reporting.