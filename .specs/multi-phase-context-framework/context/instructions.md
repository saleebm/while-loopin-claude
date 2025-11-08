# Phase Instructions

## Current Phase
Phase 2: Master Agent Framework Implementation

## Complete Instructions
Implement a comprehensive master agent orchestrator that:
1. Coordinates multi-phase agent execution
2. Detects when to switch between phases
3. Interfaces with planning agent for phase breakdown
4. Maintains backward compatibility with existing agent-runner.sh

The master agent should:
- Accept high-level goals and break them into phases
- Launch phase-specific agents with appropriate context
- Track progress across phases
- Handle phase transitions and handoffs
- Support both master and standalone modes

## Constraints
1. PRESERVE ALL EXISTING FUNCTIONALITY - Zero regressions allowed
2. BUILD ON EXISTING PATTERNS - Use run_claude(), ensure_context_files()
3. MINIMAL MODIFICATIONS - Only add code, don't change core logic
4. MAINTAIN SIMPLICITY - Avoid over-engineering
5. ENSURE COMPOSABILITY - Functions must be reusable
6. Context files must be maintained in `.specs/{feature}/context/`

## Success Criteria
- Master agent can coordinate multi-phase execution
- Planning agent generates phase breakdown
- Context files automatically maintained
- Phase transitions work smoothly
- All existing agent-runner.sh functionality intact
- Backward compatibility maintained

## Last Updated
Last updated: 2025-11-07 20:43:00
