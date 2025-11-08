#!/usr/bin/env bash

# Master Agent Demo - Examples of both standard and master agent modes
# This script demonstrates how to use the multi-phase context framework

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Master Agent Framework Demo${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Example 1: Standard Single-Phase Mode
echo -e "${GREEN}Example 1: Standard Single-Phase Mode${NC}"
echo -e "${YELLOW}Use case:${NC} Simple, focused tasks that don't require multiple phases"
echo ""
echo "Command:"
echo "  bash lib/smart-agent.sh \"Fix bug in user login validation\""
echo ""
echo "What happens:"
echo "  • AI analyzes the prompt"
echo "  • Determines this is a single-phase task (low-medium complexity)"
echo "  • Creates .specs/fix-bug-user-login-validation/ directory"
echo "  • Runs standard agent-runner.sh"
echo "  • Automatically creates and maintains 4 context files:"
echo "    - instructions.md (what agent should do)"
echo "    - progress.md (milestone tracking)"
echo "    - findings.md (discoveries and insights)"
echo "    - achievements.md (completed work with proof)"
echo ""
echo "Try it:"
echo "  INTERACTIVE_MODE=false bash lib/smart-agent.sh \"Create test file in .ai-dr/demo-test.txt\""
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 2: AI-Determined Master Agent Mode
echo -e "${GREEN}Example 2: AI-Determined Master Agent Mode${NC}"
echo -e "${YELLOW}Use case:${NC} Complex tasks that AI identifies as multi-phase"
echo ""
echo "Command:"
echo "  bash lib/smart-agent.sh \"Build complete REST API with authentication and CRUD operations\""
echo ""
echo "What happens:"
echo "  • AI analyzes the prompt"
echo "  • Determines this requires multiple phases (very-high complexity)"
echo "  • Suggests using master agent (you can confirm or override)"
echo "  • Master agent runs planning phase:"
echo "    1. Analyzes your goal"
echo "    2. Breaks into logical phases (e.g., database, auth, API, testing)"
echo "    3. Determines dependencies between phases"
echo "    4. Estimates iterations per phase"
echo "  • Executes each phase sequentially:"
echo "    - Creates phase directory with context files"
echo "    - Runs standard agent for that phase"
echo "    - Validates phase completion"
echo "    - Aggregates results to master context"
echo "  • Each phase receives context from previous phases"
echo ""
echo "Directory structure:"
echo "  .specs/build-rest-api/"
echo "  ├── master-context.md          # Aggregated results"
echo "  ├── phases.json                # AI-generated phase breakdown"
echo "  ├── planning.log               # Planning agent output"
echo "  ├── context/                   # Master-level context files"
echo "  ├── phase-1/                   # Database phase"
echo "  │   ├── AGENT-PROMPT.md"
echo "  │   ├── HANDOFF.md"
echo "  │   └── context/"
echo "  ├── phase-2/                   # Auth phase"
echo "  │   ├── AGENT-PROMPT.md"
echo "  │   ├── HANDOFF.md"
echo "  │   └── context/"
echo "  └── phase-3/                   # API phase"
echo "      ├── AGENT-PROMPT.md"
echo "      ├── HANDOFF.md"
echo "      └── context/"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 3: Force Master Agent Mode
echo -e "${GREEN}Example 3: Force Master Agent Mode${NC}"
echo -e "${YELLOW}Use case:${NC} Override AI decision to use master agent"
echo ""
echo "Command:"
echo "  MASTER_AGENT=true bash lib/smart-agent.sh \"Add user profile features\""
echo ""
echo "What happens:"
echo "  • AI analysis is bypassed"
echo "  • Master agent is forced on"
echo "  • Planning phase runs (breaks task into phases)"
echo "  • Each phase executes with context aggregation"
echo ""
echo "When to use this:"
echo "  • You know the task needs multiple phases"
echo "  • AI underestimated complexity"
echo "  • You want structured phase breakdown for organization"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 4: Non-Interactive Mode
echo -e "${GREEN}Example 4: Non-Interactive Mode${NC}"
echo -e "${YELLOW}Use case:${NC} Automation, CI/CD, or scripted workflows"
echo ""
echo "Command:"
echo "  INTERACTIVE_MODE=false MASTER_AGENT=true bash lib/smart-agent.sh \"Implement feature X\""
echo ""
echo "What happens:"
echo "  • No interactive prompts"
echo "  • Uses AI-determined or environment-specified configuration"
echo "  • Runs completely automated"
echo ""
echo "Useful environment variables:"
echo "  INTERACTIVE_MODE=false     # Disable all prompts"
echo "  MASTER_AGENT=true          # Force master agent"
echo "  MAX_ITERATIONS=15          # Override iteration limit"
echo "  ENABLE_CODE_REVIEW=true    # Enable automated review cycle"
echo "  ENABLE_SPEECH=true         # Spoken progress updates (macOS)"
echo "  RATE_LIMIT_SECONDS=30      # Adjust API rate limiting"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 5: Direct Master Agent API
echo -e "${GREEN}Example 5: Direct Master Agent API${NC}"
echo -e "${YELLOW}Use case:${NC} Advanced integrations and custom workflows"
echo ""
echo "Script example:"
cat <<'SCRIPT'
#!/usr/bin/env bash
set -euo pipefail

# Source the master agent functions
source lib/master-agent.sh

# Run master agent directly
run_master_agent \
  "Build todo app with React frontend and Node.js backend" \
  ".specs/todo-app" \
  15

# Check results
if [[ -f ".specs/todo-app/master-context.md" ]]; then
  echo "✅ All phases completed"
  cat .specs/todo-app/master-context.md
fi
SCRIPT
echo ""
echo "Available functions:"
echo "  run_master_agent          # Main orchestrator"
echo "  run_claude_planning       # Run planning agent"
echo "  generate_phases_json      # Extract phase breakdown"
echo "  check_phase_complete      # Validate phase completion"
echo "  aggregate_phase_context   # Aggregate results"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 6: Monitoring Progress
echo -e "${GREEN}Example 6: Monitoring Progress${NC}"
echo -e "${YELLOW}Use case:${NC} Track agent progress during execution"
echo ""
echo "Check context files:"
echo "  cat .specs/feature-name/context/progress.md"
echo "  cat .specs/feature-name/context/achievements.md"
echo "  cat .specs/feature-name/context/findings.md"
echo ""
echo "For master agent:"
echo "  cat .specs/feature-name/master-context.md"
echo "  cat .specs/feature-name/phases.json | jq ."
echo "  cat .specs/feature-name/phase-1/HANDOFF.md"
echo ""
echo "Watch progress in real-time:"
echo "  watch -n 2 'tail -20 .specs/feature-name/context/progress.md'"
echo ""
read -p "Press Enter to continue..."
echo ""

# Example 7: Code Review Integration
echo -e "${GREEN}Example 7: Code Review Integration${NC}"
echo -e "${YELLOW}Use case:${NC} Automated code quality validation"
echo ""
echo "Command:"
echo "  ENABLE_CODE_REVIEW=true bash lib/smart-agent.sh \"Implement user signup\""
echo ""
echo "What happens after main agent completes:"
echo "  1. Reviews all code changes against original prompt"
echo "  2. Identifies critical fixes needed"
echo "  3. Applies each fix with separate Claude command"
echo "  4. Runs lint and typecheck"
echo "  5. Re-reviews until quality threshold met (score >= 8)"
echo ""
echo "Works with both standard and master agent modes"
echo ""
read -p "Press Enter to continue..."
echo ""

# Quick Test
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Quick Test${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Let's run a simple test to demonstrate context file creation:"
echo ""

TEST_PROMPT="Create a test file at .ai-dr/master-demo-test.txt with content 'Master Agent Demo Test - $(date)'"

echo -e "${YELLOW}Running:${NC}"
echo "  INTERACTIVE_MODE=false bash lib/smart-agent.sh \"$TEST_PROMPT\""
echo ""

read -p "Run this test? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cd "$PROJECT_DIR"
    INTERACTIVE_MODE=false bash lib/smart-agent.sh "$TEST_PROMPT"

    echo ""
    echo -e "${GREEN}✅ Test completed${NC}"
    echo ""
    echo "Check the results:"
    echo "  1. Test file: cat .ai-dr/master-demo-test.txt"
    echo "  2. Context files: ls .specs/*/context/"
    echo "  3. Agent output: ls -la .ai-dr/agent-runs/"
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Resources${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Documentation:"
echo "  • Usage Guide: .specs/multi-phase-context-framework/USAGE.md"
echo "  • Design Doc: .specs/multi-phase-context-framework/MASTER-AGENT-DESIGN.md"
echo "  • Main README: README.md"
echo ""
echo "Key files:"
echo "  • Master agent: lib/master-agent.sh"
echo "  • Standard agent: lib/agent-runner.sh"
echo "  • Smart orchestrator: lib/smart-agent.sh"
echo "  • Context functions: lib/context-functions.sh"
echo ""
echo -e "${GREEN}Happy building! 🚀${NC}"
echo ""
