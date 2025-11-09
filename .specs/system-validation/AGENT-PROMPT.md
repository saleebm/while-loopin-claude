# System Validation Agent Prompt

Test and validate the While Loopin' Claude autonomous agent system.

## Primary Goals

1. **Test Core Functionality**: Run 3-4 basic tests to ensure the system works
2. **Validate Context Framework**: Confirm context files are created in the right location
3. **Check Master Agent**: Verify it triggers appropriately for complex tasks
4. **Document Findings**: Record what works and what doesn't

## Quick Test Sequence

Run these tests in order and document results:

### Test 1: Simple File Creation
```bash
bun run agent "Create a test file at validation-test.txt with 'Agent validated!'"
```
- Should complete in 1-2 iterations
- Check: `.specs/create-test-file/context/` exists

### Test 2: Multi-Phase Detection
```bash
bun run agent "Build a complete authentication system with user registration, login, password reset, and session management"
```
- Should trigger master agent (look for "Starting Master Agent")
- Can cancel after phase detection

### Test 3: Resume Capability
```bash
MAX_ITERATIONS=1 bun run agent "Document all functions in lib/agent-runner.sh"
RESUME_AGENT=true bun run agent ".specs/document-all-functions/AGENT-PROMPT.md"
```
- First command stops after 1 iteration
- Second command resumes from iteration 2

## What to Check

For each test, verify:
1. Proper `.specs/{feature}/` directory structure created
2. Context files exist in `.specs/{feature}/context/` (NOT in root `/context/`)
3. Handoff document updates between iterations
4. Agent completes successfully or provides clear errors

## Output

Create a summary in `.specs/system-validation/VALIDATION-REPORT.md` with:
- Test results (pass/fail)
- Any errors encountered
- Confirmation that core features work
- List of any issues found

## Success Criteria

The system is validated if:
- Basic agent loop executes
- Context files are created correctly
- Master agent triggers for complex tasks
- Resume functionality works

Focus on core functionality testing, not edge cases.