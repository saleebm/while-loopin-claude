# System Validation and Testing - Agent Handoff

## Mission
Thoroughly test the While Loopin' Claude system and validate that all components work correctly after the recent multi-phase context framework implementation.

## Current System State
- Multi-phase context framework: Implemented
- Master agent orchestration: Implemented
- Resume capability: Implemented
- Smart agent with AI analysis: Fixed to use AI SDK generateObject
- Documentation: Recently updated

## Testing Tasks

### 1. Basic Functionality Tests

#### Test A: Simple Single-Phase Task
```bash
# Should use standard agent mode
bun run agent "Create a file called hello.txt with 'System test successful!'"
```
**Expected**:
- Creates `.specs/create-file-hello/` directory
- Uses standard single-phase agent
- Creates context files in `.specs/create-file-hello/context/`
- Actually creates hello.txt file
- Completes in 1-2 iterations

#### Test B: Code Review Integration
```bash
# Should trigger code review
ENABLE_CODE_REVIEW=true bun run agent "Create a simple JavaScript function to calculate fibonacci numbers"
```
**Expected**:
- Creates the function
- Runs code review after main loop
- Review score and feedback generated

### 2. Multi-Phase Master Agent Test

#### Test C: Complex Multi-Phase Task
```bash
# Should trigger master agent mode
bun run agent "Build a complete todo list application with: 1) HTML interface, 2) JavaScript functionality for add/remove/complete, 3) Local storage persistence, 4) CSS styling"
```
**Expected**:
- AI detects this needs multi-phase orchestration
- Creates phase directories under `.specs/{feature}/`
- Planning phase breaks it into logical phases
- Each phase runs with its own context
- Master context aggregates results

### 3. Resume Functionality Test

#### Test D: Interrupt and Resume
```bash
# Start a task with limited iterations
MAX_ITERATIONS=1 bun run agent "Write comprehensive documentation for the agent-runner.sh script"

# Then resume it
RESUME_AGENT=true bun run agent ".specs/write-comprehensive-documentation/AGENT-PROMPT.md"
```
**Expected**:
- First run stops after 1 iteration
- Resume continues from iteration 2
- Maintains context between runs

### 4. Context Framework Validation

#### Test E: Context File Updates
```bash
# Run any simple task
bun run agent "Add a comment to README.md explaining the purpose"

# Then check context files
ls -la .specs/*/context/
cat .specs/*/context/progress.md
cat .specs/*/context/achievements.md
```
**Expected**:
- All 4 context files exist (instructions, progress, findings, achievements)
- Files contain meaningful content from the agent's work
- Context directory is under `.specs/{feature}/context/` NOT in project root

### 5. Integration Tests

#### Test F: Examples Directory
```bash
# Test the demo examples still work
bash examples/quick-test.sh
bash examples/color-art-app/run-agent.sh
```
**Expected**: Examples run without errors

#### Test G: Direct Script Usage
```bash
# Test direct invocation bypassing smart-agent
bash lib/agent-runner.sh \
  <(echo "Create test2.txt with 'Direct test'") \
  /tmp/test-handoff.md \
  /tmp/test-output \
  2
```
**Expected**: Runs 2 iterations and creates the file

### 6. Error Handling Tests

#### Test H: Invalid Input
```bash
# Test with empty prompt
bun run agent ""

# Test with non-existent file
bun run agent "/definitely/not/a/real/file.txt"
```
**Expected**: Graceful error messages

### 7. Configuration Validation

#### Test I: Environment Variables
```bash
# Test various env var combinations
RATE_LIMIT_SECONDS=2 MAX_ITERATIONS=3 bun run agent "Quick test task"
MASTER_AGENT=true bun run agent "Simple task that shouldn't need master"
INTERACTIVE_MODE=false bun run agent "Non-interactive test"
```
**Expected**: Settings properly applied

## Validation Checklist

After running tests, verify:

- [ ] `.specs/` directories created with proper structure
- [ ] Context files in correct location (`.specs/{feature}/context/`)
- [ ] NO `/context/` directory in project root
- [ ] Handoff documents properly formatted
- [ ] Analysis.json contains valid configuration
- [ ] Master agent triggers for complex tasks
- [ ] Standard agent used for simple tasks
- [ ] Resume functionality maintains state
- [ ] Code review runs when enabled
- [ ] Rate limiting works (delays between iterations)
- [ ] Output logs in `.ai-dr/agent-runs/`
- [ ] No regression in smart-agent.sh JSON extraction

## Known Issues to Watch For

1. **API Credits**: Ensure Anthropic API has sufficient credits before testing
2. **JSON Extraction**: Verify smart-agent.sh uses `extract-analysis-json.ts` not `run_claude_json`
3. **Context Path**: Must be `FEATURE_DIR/context` not `PROJECT_DIR/context`
4. **Master Agent**: Should only trigger for truly complex multi-phase tasks

## Success Criteria

The system is working correctly if:
1. All basic tests pass
2. Complex tasks trigger master agent appropriately
3. Simple tasks use standard agent
4. Context files are created and updated
5. Resume functionality preserves state
6. No errors in typical usage patterns
7. Documentation examples work

## Investigation Areas

If issues are found, check:
- `lib/smart-agent.sh` - AI analysis and routing
- `lib/agent-runner.sh` - Core execution loop
- `lib/master-agent.sh` - Multi-phase orchestration
- `lib/context-functions.sh` - Context management
- `lib/extract-analysis-json.ts` - JSON structure generation

## Reporting

Document findings in:
- `.specs/system-validation/FINDINGS.md` - Test results and issues
- `.specs/system-validation/context/achievements.md` - What's working
- `.specs/system-validation/context/progress.md` - Test execution progress

Focus on ensuring the core loop works, context is properly managed, and the system correctly chooses between standard and master agent modes based on task complexity.