# Master Agent Framework Design

## Overview
The master agent orchestrates multi-phase execution by coordinating planning, phase execution, and context management across complex tasks.

## Architecture

```
┌─────────────────────────────────────────┐
│         Master Agent                     │
│  (lib/master-agent.sh)                  │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Planning Agent                    │ │
│  │  - Analyze goal                    │ │
│  │  - Break into phases               │ │
│  │  - Generate phases.json            │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Phase Coordinator                 │ │
│  │  - Track current phase             │ │
│  │  - Handle phase transitions        │ │
│  │  - Aggregate context               │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Phase Executor                    │ │
│  │  - Launch agent-runner.sh          │ │
│  │  - Monitor progress                │ │
│  │  - Detect completion               │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
             │
             ↓
┌─────────────────────────────────────────┐
│    Agent Runner (lib/agent-runner.sh)   │
│    - Executes single phase              │
│    - Maintains context files            │
│    - Generates handoffs                 │
└─────────────────────────────────────────┘
```

## Data Flow

### 1. Planning Phase
```bash
# Input: High-level goal
GOAL="Implement user authentication with JWT"

# Planning Agent → Claude
run_claude_planning "$GOAL" ".specs/feature/planning.log"

# Output: phases.json
{
  "goal": "Implement user authentication with JWT",
  "phases": [
    {
      "id": "phase-1",
      "name": "Database Schema",
      "description": "Design and implement user table with auth fields",
      "success_criteria": ["Migration created", "Schema validated"],
      "max_iterations": 5
    },
    {
      "id": "phase-2",
      "name": "Auth Endpoints",
      "description": "Create login/signup API endpoints",
      "success_criteria": ["POST /login works", "POST /signup works"],
      "max_iterations": 8,
      "depends_on": ["phase-1"]
    },
    {
      "id": "phase-3",
      "name": "JWT Middleware",
      "description": "Add JWT verification middleware",
      "success_criteria": ["Protected routes work", "Tests pass"],
      "max_iterations": 5,
      "depends_on": ["phase-2"]
    }
  ]
}
```

### 2. Phase Execution
```bash
# For each phase in phases.json
for phase in $(jq -r '.phases[] | @base64' phases.json); do
  PHASE_DATA=$(echo "$phase" | base64 -d)
  PHASE_ID=$(echo "$PHASE_DATA" | jq -r '.id')

  # Create phase-specific directories
  PHASE_DIR=".specs/feature/$PHASE_ID"
  mkdir -p "$PHASE_DIR/context"

  # Generate phase prompt from planning output
  generate_phase_prompt "$PHASE_DATA" > "$PHASE_DIR/AGENT-PROMPT.md"

  # Run agent-runner for this phase
  run_claude_agent \
    "$PHASE_DIR/AGENT-PROMPT.md" \
    "$PHASE_DIR/HANDOFF.md" \
    "$PHASE_DIR/runs" \
    "$MAX_ITERATIONS"

  # Check phase completion
  if ! check_phase_complete "$PHASE_DIR/HANDOFF.md"; then
    echo "Phase $PHASE_ID failed"
    exit 1
  fi

  # Aggregate context for next phase
  aggregate_phase_context "$PHASE_DIR" ".specs/feature/master-context.md"
done
```

### 3. Context Management

**Master Context** (`.specs/feature/master-context.md`):
```markdown
# Master Agent Context

## Goal
[Original high-level goal]

## Completed Phases
### Phase 1: Database Schema
- Status: Complete
- Key Achievements: [...]
- Context: phase-1/context/

### Phase 2: Auth Endpoints
- Status: In Progress
- Current State: [...]
- Context: phase-2/context/

## Cross-Phase Insights
[Learnings that apply to multiple phases]
```

**Phase Context** (`.specs/feature/phase-N/context/`):
- `instructions.md` - Phase-specific instructions
- `progress.md` - Phase progress tracking
- `findings.md` - Phase discoveries
- `achievements.md` - Phase validation

## File Structure
```
.specs/feature-name/
├── master-context.md           # Master agent context
├── phases.json                 # Generated phase breakdown
├── planning.log                # Planning agent output
├── README.md                   # Navigation
├── context/                    # Master-level context
│   ├── instructions.md
│   ├── progress.md
│   ├── findings.md
│   └── achievements.md
├── phase-1/
│   ├── AGENT-PROMPT.md
│   ├── HANDOFF.md
│   ├── context/
│   │   ├── instructions.md
│   │   ├── progress.md
│   │   ├── findings.md
│   │   └── achievements.md
│   └── runs/
├── phase-2/
│   ├── AGENT-PROMPT.md
│   ├── HANDOFF.md
│   ├── context/
│   └── runs/
└── phase-3/
    ├── AGENT-PROMPT.md
    ├── HANDOFF.md
    ├── context/
    └── runs/
```

## Functions to Implement

### lib/master-agent.sh

```bash
# Main entry point
run_master_agent() {
  local GOAL="$1"
  local FEATURE_DIR="$2"
  local MAX_ITERATIONS_PER_PHASE="${3:-10}"
}

# Planning agent interface
run_claude_planning() {
  local GOAL="$1"
  local OUTPUT_FILE="$2"
  local FEATURE_DIR="$3"
}

# Generate phase breakdown from planning output
generate_phases_json() {
  local PLANNING_OUTPUT="$1"
  local OUTPUT_JSON="$2"
}

# Generate phase-specific prompt
generate_phase_prompt() {
  local PHASE_DATA="$1"
  local MASTER_CONTEXT="$2"
}

# Check phase completion
check_phase_complete() {
  local HANDOFF_FILE="$1"
}

# Aggregate phase context to master
aggregate_phase_context() {
  local PHASE_DIR="$1"
  local MASTER_CONTEXT="$2"
}

# Detect phase dependencies and ordering
resolve_phase_order() {
  local PHASES_JSON="$1"
}
```

## Usage Examples

### Standard Mode (Single Phase)
```bash
# Existing behavior unchanged
bash lib/smart-agent.sh "Fix the bug in auth"
# → Runs agent-runner.sh directly
```

### Master Agent Mode (Multi-Phase)
```bash
# Enable master agent
MASTER_AGENT=true bash lib/smart-agent.sh "Implement complete auth system with JWT"
# → Runs master-agent.sh
# → Planning agent breaks into phases
# → Executes each phase via agent-runner.sh
# → Aggregates results
```

### Direct Master Agent Call
```bash
source lib/master-agent.sh

run_master_agent \
  "Build REST API for todo app" \
  ".specs/todo-api" \
  10
```

## Integration with smart-agent.sh

Add master agent detection:

```bash
# In smart-agent.sh after analysis
if [[ "${MASTER_AGENT:-false}" == "true" ]] || [[ "$ESTIMATED_COMPLEXITY" == "very-high" ]]; then
  echo "🎯 Using master agent for multi-phase execution"

  source "$SCRIPT_DIR/master-agent.sh"
  run_master_agent "$PROMPT" "$FEATURE_DIR" "$MAX_ITERATIONS"
else
  # Existing single-phase path
  source "$SCRIPT_DIR/agent-runner.sh"
  run_claude_agent "$AGENT_PROMPT_FILE" "$HANDOFF" "$OUTPUT_DIR" "$MAX_ITERATIONS" # ...
fi
```

## Planning Agent Prompt Template

```markdown
# Planning Agent

## Goal
Analyze this goal and break it into sequential phases for implementation.

## User's Goal
{USER_GOAL}

## Project Context
{PROJECT_STRUCTURE}
{TECH_STACK}

## Your Task
Break this goal into 2-5 logical phases. Each phase should:
1. Be completable in 5-10 agent iterations
2. Have clear success criteria
3. Build on previous phases
4. Produce testable outcomes

Output ONLY a JSON structure:
{
  "goal": "the user's goal",
  "phases": [
    {
      "id": "phase-1",
      "name": "Short phase name",
      "description": "Detailed phase description",
      "success_criteria": ["criterion 1", "criterion 2"],
      "max_iterations": 5-10,
      "depends_on": ["phase-id"] or []
    }
  ]
}
```

## Benefits

1. **Handles Complex Tasks**: Breaks large goals into manageable phases
2. **Better Context Management**: Each phase has focused context
3. **Incremental Progress**: Phases can be completed and validated independently
4. **Backward Compatible**: Single-phase tasks use existing agent-runner.sh
5. **Composable**: Master agent reuses all existing functions
6. **Transparent**: User can inspect each phase's work separately

## Implementation Order

1. Create `lib/master-agent.sh` with basic structure
2. Implement planning agent interface
3. Add phase prompt generation
4. Add phase execution loop
5. Implement context aggregation
6. Integrate with smart-agent.sh
7. Test with multi-phase scenario
8. Document usage patterns
