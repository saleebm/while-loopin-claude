# Context File Template

This template provides a standard structure for the context files that agents must maintain during their execution.

## File: context/instructions.md

```markdown
# Phase Instructions

## Current Phase
[Name or number of the current phase]

## Complete Instructions
[Full, detailed instructions for this phase - everything the agent needs to know]

## Constraints
[Any limitations, requirements, or rules that must be followed]

## Success Criteria
[How to know when this phase is complete]

## Last Updated
[Timestamp of last update]
```

## File: context/progress.md

```markdown
# Progress Tracking

## Milestones
- [ ] Milestone 1: [Description]
- [ ] Milestone 2: [Description]
- [x] Milestone 3: [Description] - Completed at [timestamp]

## Current Status
[What is currently being worked on]

## Completed Actions
1. [Action 1] - [Timestamp]
2. [Action 2] - [Timestamp]

## Next Steps
1. [Next action 1]
2. [Next action 2]

## Blockers
[Any current blockers or issues]

## Last Updated
[Timestamp of last update]
```

## File: context/findings.md

```markdown
# Findings and Insights

## Key Discoveries
### [Discovery 1]
- **Date**: [Timestamp]
- **Context**: [What led to this discovery]
- **Details**: [Full description]
- **Implications**: [How this affects the work]

### [Discovery 2]
- **Date**: [Timestamp]
- **Context**: [What led to this discovery]
- **Details**: [Full description]
- **Implications**: [How this affects the work]

## Thought Process
[Stream of consciousness notes, debugging thoughts, hypotheses tested]

## Questions and Answers
- **Q**: [Question that came up]
- **A**: [Answer found, or "Still investigating"]

## Learnings
[What has been learned during this phase]

## Last Updated
[Timestamp of last update]
```

## File: context/achievements.md

```markdown
# Achievements and Validation

## Recent Achievements

### Achievement 1: [Title]
- **Completed**: [Timestamp]
- **Description**: [What was accomplished]
- **Validation Method**: [How it was verified - tests, manual checks, etc.]
- **Validation Result**: [Proof that it works - test output, screenshots, etc.]
- **Files Changed**:
  - [file1.ext]
  - [file2.ext]

### Achievement 2: [Title]
- **Completed**: [Timestamp]
- **Description**: [What was accomplished]
- **Validation Method**: [How it was verified - tests, manual checks, etc.]
- **Validation Result**: [Proof that it works - test output, screenshots, etc.]
- **Files Changed**:
  - [file1.ext]
  - [file2.ext]

## Quality Metrics
[Any relevant quality metrics - test coverage, performance improvements, etc.]

## Last Updated
[Timestamp of last update]
```

## Usage Notes

1. **Frequency**: Update context files after each significant action or discovery
2. **Completeness**: Keep instructions.md complete - it should contain ALL information needed
3. **Measurability**: Progress.md should have concrete, measurable milestones
4. **Validation**: Always include validation proof in achievements.md
5. **Timestamps**: Include timestamps for traceability
