# While Loopin' Claude - Development Guide

## Core Principles

**Keep It Simple**: This is a shell script orchestration system. Resist urge to over-engineer.

**AI Does the Thinking**: Never hard-code logic that AI can determine from context. Let Claude analyze and decide.

**Composability**: Each function should be reusable. Extract shared logic into `claude-functions.sh`.

**DRY Documentation**: Reference existing docs rather than repeating. Keep docs focused and minimal.

## Architecture

Four shell scripts work together:

1. **claude-functions.sh** - Shared utilities
   - `run_claude()` - Execute Claude and save output
   - `generate_structured_review_json()` - Extract structured review data using AI SDK generateObject
   - Reusable across all agent operations

2. **context-functions.sh** - Context file management
   - `ensure_context_files()` - Create/validate context files
   - `check_context_files_updated()` - Verify agent updates
   - Automatic context tracking for all agents

3. **agent-runner.sh** - Core execution engine
   - `run_claude_agent()` - Main agent loop
   - `run_code_review_cycle()` - Optional review process
   - `process_critical_fixes()` - Apply fixes from reviews
   - `run_lint_and_typecheck()` - Validate code quality
   - Integrates context file management automatically

4. **master-agent.sh** - Multi-phase orchestrator
   - `run_master_agent()` - Coordinate phase execution
   - `run_claude_planning()` - Break tasks into phases
   - `aggregate_phase_context()` - Cross-phase context
   - For complex, multi-phase tasks

5. **smart-agent.sh** - AI orchestrator
   - Analyzes prompts with Claude
   - Determines all configuration dynamically
   - Chooses standard vs master agent mode
   - Creates feature directories
   - Invokes appropriate agent with config

## Multi-Phase Context Framework

The system supports two execution modes, automatically selected based on task complexity:

### Standard Mode (Single-Phase)
Used for most tasks - focused work with single agent. **Automatically includes:**
- Context files tracking agent's work (`context/instructions.md`, `progress.md`, `findings.md`, `achievements.md`)
- Agent receives context requirements in every prompt
- System validates context files are updated after each iteration
- Final summary includes context file overview

### Master Agent Mode (Multi-Phase)
Used for complex tasks requiring coordinated phases. **Process:**

1. **Planning Phase**: AI breaks task into 2-5 logical phases with dependencies
2. **Phase Execution**: Each phase runs as standard agent with own context
3. **Context Aggregation**: Results flow between phases via master context
4. **Completion**: All phase results aggregated to feature root

**When to use Master Agent:**
- AI automatically suggests for "very-high" complexity tasks
- Force with `MASTER_AGENT=true` environment variable
- Good for: "Build complete X system", "Implement full Y with Z"
- Not needed for: "Fix bug", "Add single feature", "Refactor X"

**See comprehensive usage guide:** `.specs/multi-phase-context-framework/USAGE.md`

## Feature Spec Organization

All feature work MUST use `.specs/{feature-name}/` structure:

### Standard Mode Structure
**Required files:**
- `AGENT-PROMPT.md` - Enhanced prompt with full context
- `HANDOFF.md` - Session status and handoff (NOT in repo root)
- `analysis.json` - AI-determined configuration
- `README.md` - Navigation to all spec docs
- `context/` - Four context files (auto-created)
  - `instructions.md` - Current phase instructions
  - `progress.md` - Milestone tracking
  - `findings.md` - Discoveries and insights
  - `achievements.md` - Completed work with validation

**Optional files:**
- `PLAN.md` - Detailed implementation plan
- `FINDINGS.md` - Research and discoveries (legacy, prefer context/findings.md)
- `PROGRESS.md` - Implementation tracking (legacy, prefer context/progress.md)

### Master Agent Mode Structure
**Additional files for multi-phase:**
- `phases.json` - AI-generated phase breakdown
- `planning.log` - Planning agent output
- `master-context.md` - Aggregated cross-phase results
- `phase-1/`, `phase-2/`, etc. - Per-phase directories
  - Each phase has own `AGENT-PROMPT.md`, `HANDOFF.md`, `context/`

## Handoff Document Format

Handoffs enable continuity across iterations. Must include:

```markdown
# Agent Handoff

## Session End
Status: [starting|in-progress|complete]

## Current State
What's working, what's broken, what changed

## Next Steps
1. Specific action items
2. Alternative approaches if blocked
3. Testing requirements

## Findings
Critical discoveries and learnings

## Investigation Notes
Technical details, error messages, diagnostics
```

**Critical**: Include "Session End" marker. Status "complete" stops agent.

## Effective Prompts

**Be specific about intent:**
```bash
# Bad
bun run agent "Fix the bug"

# Good
bun run agent "Fix frontmatter corruption in MDX editor when saving files"
```

**Provide context when needed:**
```bash
# Create plan.txt with:
# - What's broken
# - Expected behavior
# - Relevant files
# - Constraints

bun run agent plan.txt
```

**Let AI determine complexity:**
- Don't specify iterations unless you have reason
- AI will analyze and set appropriate max
- Override only if needed: `MAX_ITERATIONS=20 bun run agent "prompt"`

## Code Review Integration

Review cycle runs AFTER main agent loop completes:

1. Reviews code against original prompt
2. Identifies critical fixes needed
3. Applies each fix with separate Claude command
4. Runs lint and typecheck
5. Re-reviews until quality threshold met (score >= 8, no critical issues)

Enable via environment variable:
```bash
ENABLE_CODE_REVIEW=true bun run agent "your prompt"
```

Or in calling script:
```bash
run_claude_agent "$PROMPT" "$HANDOFF" "$OUTPUT" 10 --enable-code-review
```

## Rate Limiting

Built-in 15-second delays between:
- Main loop iterations
- Code review iterations
- Individual fix applications (2 seconds)

Override if needed:
```bash
RATE_LIMIT_SECONDS=30 bun run agent "prompt"
```

## Speech Feedback (macOS)

Enable spoken summaries after each iteration:
```bash
ENABLE_SPEECH=true bun run agent "prompt"
```

Uses Claude Haiku to generate concise progress updates.

## Interactive Prompts

Interactive prompt system for user input during agent startup. All functions support:
- Alert sound (plays on prompt)
- Speech output (if ENABLE_SPEECH=true)
- Composable, modular design

**Available prompt types:**

```bash
# Text input with optional default
NAME=$(prompt_user text "Enter name:" "default-name")

# Single select menu (returns 1-based index)
CHOICE=$(prompt_user select "Choose option:" "opt1" "opt2" "opt3")

# Multi-select menu (returns space-separated indices)
CHOICES=$(prompt_user multiselect "Select features:" "feat1" "feat2" "feat3")

# Yes/no confirmation (returns 0 for yes, 1 for no)
if prompt_user confirm "Continue?" "y"; then
  echo "Confirmed"
fi
```

**Interactive mode in smart-agent:**

By default, smart-agent.sh prompts for configuration. Disable with:
```bash
INTERACTIVE_MODE=false bash lib/smart-agent.sh "prompt"
```

**Direct function usage:**

```bash
# Source the functions
source lib/claude-functions.sh

# Use individual prompt functions
prompt_select "Choose model:" "sonnet" "opus" "haiku"
prompt_confirm "Enable review?" "n"
prompt_text "Project name:" "my-project"
```

See `examples/test-interactive-prompts.sh` for complete test suite.

## Testing and Validation

**Before committing changes:**

1. Test with simple prompt:
```bash
bun run agent "Create test file with 'Hello World' in .ai-dr/test.txt"
```

2. Verify outputs in `.ai-dr/agent-runs/`

3. Check handoff format and completion detection

4. Test code review if enabled

**When modifying scripts:**

1. Validate bash syntax: `bash -n lib/agent-runner.sh`
2. Test with minimal iterations first
3. Verify JSON output structure
4. Check error handling

## Extension Guidelines

**Adding new features:**

1. Extract reusable functions to `claude-functions.sh`
2. Keep agent-runner.sh focused on orchestration
3. Use environment variables for configuration
4. Document in comments with ✅ markers
5. Update requirements checklist at top of file

**Adding new review types:**

1. Create new review template in caller's `.claude/agents/`
2. Reference template in `generate_review_prompt()`
3. Follow existing structured output pattern
4. Add to code review cycle configuration

**Custom integrations:**

1. Source `lib/agent-runner.sh`
2. Call `run_claude_agent()` with your config
3. Create your own prompt/handoff generation
4. Reuse `run_claude()` and `generate_structured_review_json()`

## Common Patterns

**Running Claude:**
```bash
# Always use run_claude() helper
run_claude "$PROMPT_TEXT" "$OUTPUT_FILE" "sonnet"
```

**Generating structured output:**
```bash
# Extract JSON from Claude response
RESULT_JSON=$(generate_structured_review_json "$OUTPUT_FILE" "$ADDITIONAL_JSON" "$PROJECT_DIR")
```

**Working with context files:**
```bash
# Context files are automatic in agent-runner.sh, but you can use directly:
source lib/context-functions.sh

# Initialize context files for a feature
ensure_context_files "$CONTEXT_DIR"

# Check if agent updated context files
if check_context_files_updated "$CONTEXT_DIR"; then
  echo "✅ Context files updated"
fi
```

**Using master agent:**
```bash
# Let AI decide (recommended)
bash lib/smart-agent.sh "your complex task"

# Force master agent mode
MASTER_AGENT=true bash lib/smart-agent.sh "your task"

# Direct API call
source lib/master-agent.sh
run_master_agent "goal" ".specs/feature-name" 10
```

**Working directory:**
```bash
# Always cd to project root before Claude commands
cd "$PROJECT_DIR" || return 1
run_claude "$PROMPT" "$OUTPUT" "sonnet"
```

**Error handling:**
```bash
# Check return codes
if ! run_claude "$PROMPT" "$OUTPUT" "sonnet"; then
  echo "❌ Failed"
  return 1
fi
```

## File Locations

**In user's project:**
- `.specs/_shared/` - Agent system scripts (if needed)
- `.specs/{feature-name}/` - Feature-specific files
  - `context/` - Four context files (auto-created)
  - `phase-N/` - Phase directories (master agent mode)
- `.ai-dr/agent-runs/` - Agent outputs
- `.ai-dr/prompts/` - Saved prompts

**In this repo:**
- `lib/` - Reusable shell scripts
  - `claude-functions.sh` - Core Claude utilities
  - `context-functions.sh` - Context file management
  - `agent-runner.sh` - Standard agent engine
  - `master-agent.sh` - Multi-phase orchestrator
  - `smart-agent.sh` - AI-powered orchestrator
- `templates/` - Agent prompt templates
  - `planning-agent-prompt.md` - Master agent planning
- `examples/` - Usage demonstrations
- `.ai-dr/` - Output directory structure

## Best Practices

DO write bash functions that compose well
DO validate all inputs before processing
DO use meaningful variable names in UPPERCASE
DO add descriptive echo statements for user feedback
DO handle errors explicitly with return codes

DON'T hard-code logic AI can determine
DON'T nest logic more than 3 levels deep
DON'T use global variables without clear naming
DON'T skip input validation
DON'T forget to update documentation

## Resources

**Documentation:**
- `README.md` - Main usage guide and quick start
- `.specs/multi-phase-context-framework/USAGE.md` - Comprehensive multi-phase guide
- `.specs/multi-phase-context-framework/MASTER-AGENT-DESIGN.md` - Architecture details
- `examples/` - Integration patterns and demos
- Script comments - Detailed inline requirements

**Key Implementation Files:**
- `lib/agent-runner.sh` requirements header (lines 9-66)
- `lib/master-agent.sh` full implementation (426 lines)
- `lib/context-functions.sh` context management (500+ lines)
- `templates/planning-agent-prompt.md` - Planning template
