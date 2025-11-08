# Prompt Analysis Configuration System

## Task
Implement or validate a JSON configuration generator that analyzes user prompts and returns structured configurations for autonomous agent execution.

## System Context
This is part of the 'While Loopin' Claude' project - a shell script orchestration system for AI-driven development tasks. The system uses:
- `claude-functions.sh`: Shared utilities for running Claude and generating structured output
- `agent-runner.sh`: Core execution engine managing agent loops and code review cycles
- `smart-agent.sh`: AI orchestrator that analyzes prompts and determines configuration dynamically

## Analysis Requirements
1. **Task Type**: Identify the specific nature of the work (not generic categories)
2. **Feature Naming**: Generate descriptive kebab-case folder names for organization
3. **File Discovery**: Identify relevant codebase files based on task context
4. **Complexity Estimation**: Determine iteration count and overall difficulty (low|medium|high|very-high)
5. **Code Review Decision**: Determine if review cycle should be enabled
6. **Prompt Enhancement**: Expand user prompt with full contextual information
7. **Initial Handoff**: Create starting handoff document with status tracking

## Configuration Output
Return valid JSON with all required fields, following the specified structure. Reasoning should explain each configuration choice based on task analysis.

## Master Agent Trigger
Use master agent (true) only for multi-phase, multi-subsystem work with very-high complexity. Use standard agent (false) for single-focused, linear tasks.
