# Autonomous Agent Configuration Analysis System

## Task Overview
Analyze a user-provided prompt (already read from file) and generate a comprehensive JSON configuration for running an autonomous Claude agent in the While Loopin' Claude system.

## Context: While Loopin' Claude Framework

This project is an AI-orchestrated autonomous agent system where:
- Claude runs in iterative loops until tasks complete
- Configuration is determined by AI analysis (not hard-coded)
- Feature specifications are stored in `.specs/{feature-name}/` directories
- Handoff documents track state between iterations
- Optional code review cycles ensure quality
- Rate limiting prevents API overload (15-second delays between iterations)

## Analysis Requirements

### 1. Task Type Classification
Describe the specific task type beyond generic categories. Examples:
- "Frontmatter corruption fix in MDX editor save workflow"
- "API endpoint discovery and documentation generation"
- "Component refactoring with accessibility compliance validation"

### 2. Feature Folder Naming
Generate a kebab-case slug that:
- Descriptively names the feature
- Is short but clear (2-4 words typically)
- Reflects the core purpose

### 3. Relevant Files Identification
Identify files likely needed based on:
- File types mentioned in the prompt
- Common patterns in the codebase
- Configuration or setup files
- Related modules and utilities

### 4. Complexity Assessment
- Scale: 1-10, where 1 is trivial, 10 is extremely complex
- Estimate based on:
  - Number of different file types to modify
  - Architectural changes required
  - Integration complexity
  - Unknown factors needing investigation
- max_iterations should be roughly 2x the complexity

### 5. Code Review Decision
- Enable (true) for: production code, refactoring, bug fixes, features touching critical paths
- Disable (false) for: documentation, simple scripts, exploration, one-off utilities
- max_reviews typically 3-5 if enabled

### 6. Enhanced Prompt Creation
Take the original prompt and add:
- Project context and architecture overview
- Relevant file references with full paths
- Expected output format
- Quality criteria and success metrics
- Integration points with existing systems
- Any constraints or considerations

### 7. Initial Handoff Document
Create a HANDOFF.md with:
- Session End status: "starting" (not complete)
- Current State: What's being worked on
- Next Steps: Initial action items
- Findings: Known information about the task
- Investigation Notes: Technical details to track

## JSON Output Structure

Must include:
- feature_name: kebab-case slug
- prompt_type: specific task description
- complexity: 1-10 integer
- max_iterations: 2x complexity
- enable_code_review: boolean
- max_reviews: 0 if review disabled, 3-5 if enabled
- relevant_files: array of file paths
- enhanced_prompt: detailed prompt with full context
- initial_handoff: handoff document as markdown string
- reasoning: explanation of all configuration decisions

## Key Considerations

- Use the CLAUDE.md file to understand project best practices
- Analyze git status to understand ongoing work
- Consider recent commits to understand project momentum
- Extract relevant files from existing .specs/ examples
- Make configuration decisions based on actual task complexity, not assumptions

## Output

Return ONLY valid JSON with no additional text or markdown wrapper.
