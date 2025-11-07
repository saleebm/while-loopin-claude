# While Loopin' Claude - API Specification

[← Back to README](README.md) | [Architecture →](ARCHITECTURE.md) | [Quick Start →](QUICK-START.md) | [Dev Guide →](CLAUDE.md)

---

## Overview

This document defines the language-agnostic API contracts for implementing an autonomous agent orchestration system. These specifications can be implemented in any programming language with access to an LLM API.

## Core Interfaces

### 1. Agent Interface

The main agent execution contract:

```yaml
AgentExecutor:
  run:
    input:
      prompt:
        type: string | file_path
        description: Task description or path to prompt file
      config:
        max_iterations:
          type: integer
          default: 10
          range: [1, 100]
        enable_code_review:
          type: boolean
          default: false
        rate_limit_seconds:
          type: integer
          default: 15
          range: [0, 300]
        model:
          type: enum
          values: [sonnet, opus, haiku]
          default: sonnet
        feature_name:
          type: string
          pattern: "^[a-z0-9-]+$"
          description: Kebab-case feature identifier

    output:
      status:
        type: enum
        values: [running, complete, error, timeout]
      iterations_completed:
        type: integer
      final_handoff:
        type: Handoff
      outputs:
        type: array[IterationOutput]
      error:
        type: string | null

  stop:
    input:
      agent_id:
        type: string
    output:
      success:
        type: boolean
```

### 2. Handoff Schema

State management between iterations:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["session_end", "current_state", "next_steps"],
  "properties": {
    "session_end": {
      "type": "object",
      "required": ["status"],
      "properties": {
        "status": {
          "type": "string",
          "enum": ["starting", "in-progress", "complete", "error"]
        },
        "timestamp": {
          "type": "string",
          "format": "date-time"
        }
      }
    },
    "current_state": {
      "type": "string",
      "description": "Markdown description of current state"
    },
    "next_steps": {
      "type": "array",
      "items": {
        "type": "string"
      },
      "description": "Ordered list of next actions"
    },
    "findings": {
      "type": "string",
      "description": "Discoveries and insights"
    },
    "investigation_notes": {
      "type": "string",
      "description": "Technical details and diagnostics"
    },
    "achievements": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "description": {"type": "string"},
          "validation": {"type": "string"}
        }
      }
    }
  }
}
```

### 3. Context Management Interface

For maintaining persistent context across iterations:

```yaml
ContextManager:
  initialize:
    input:
      feature_path:
        type: string
        description: Path to feature directory
    output:
      context_dir:
        type: string
        description: Path to context directory

  update:
    input:
      context_type:
        type: enum
        values: [instructions, progress, findings, achievements]
      content:
        type: string
      append:
        type: boolean
        default: false
    output:
      success:
        type: boolean
      file_path:
        type: string

  read:
    input:
      context_type:
        type: enum
        values: [instructions, progress, findings, achievements, all]
    output:
      content:
        type: string | object
      last_updated:
        type: string
        format: date-time
```

### 4. Orchestrator Interface

For intelligent task analysis and configuration:

```yaml
Orchestrator:
  analyze:
    input:
      prompt:
        type: string
      context:
        type: object
        properties:
          previous_runs:
            type: array[string]
          project_files:
            type: array[string]

    output:
      configuration:
        type: object
        properties:
          task_type:
            type: enum
            values: [simple, complex, multi-phase]
          complexity_score:
            type: float
            range: [0, 1]
          feature_name:
            type: string
            pattern: "^[a-z0-9-]+$"
          suggested_iterations:
            type: integer
          needs_code_review:
            type: boolean
          relevant_files:
            type: array[string]
          phases:
            type: array[Phase] | null
```

### 5. Multi-Phase Execution Interface

For complex tasks requiring multiple phases:

```yaml
Phase:
  type: object
  properties:
    id:
      type: string
    name:
      type: string
    description:
      type: string
    dependencies:
      type: array[string]
      description: IDs of phases that must complete first
    max_iterations:
      type: integer
    prompt:
      type: string

MasterAgent:
  plan:
    input:
      prompt:
        type: string
      analysis:
        type: OrchestratorOutput
    output:
      phases:
        type: array[Phase]
      execution_order:
        type: array[string]
        description: Phase IDs in execution order

  execute:
    input:
      plan:
        type: PlanOutput
    output:
      phase_results:
        type: object
        additionalProperties:
          type: PhaseResult

PhaseResult:
  type: object
  properties:
    phase_id:
      type: string
    status:
      type: enum
      values: [pending, running, complete, error]
    iterations_run:
      type: integer
    outputs:
      type: array[string]
    handoff:
      type: Handoff
    error:
      type: string | null
```

### 6. Live Preview Interface

For real-time progress updates:

```yaml
LiveServer:
  start:
    input:
      port:
        type: integer
        default: 3000
      serve_directory:
        type: string
      watch_directories:
        type: array[string]
      auto_open:
        type: boolean
        default: true
    output:
      server_url:
        type: string
      websocket_url:
        type: string
      pid:
        type: integer

  update:
    input:
      progress:
        type: object
        properties:
          iteration:
            type: integer
          total_iterations:
            type: integer
          status:
            type: string
          message:
            type: string
          timestamp:
            type: string
            format: date-time
    output:
      broadcast_count:
        type: integer
        description: Number of clients that received update

  stop:
    input:
      pid:
        type: integer
    output:
      success:
        type: boolean
```

### 7. Code Review Interface

For automated quality assurance:

```yaml
CodeReviewer:
  review:
    input:
      original_prompt:
        type: string
      files_modified:
        type: array[string]
      iteration_outputs:
        type: array[string]

    output:
      score:
        type: integer
        range: [1, 10]
      critical_issues:
        type: array[Issue]
      suggestions:
        type: array[string]
      pass:
        type: boolean
        description: True if score >= 8 and no critical issues

Issue:
  type: object
  properties:
    severity:
      type: enum
      values: [critical, major, minor]
    file:
      type: string
    line:
      type: integer | null
    description:
      type: string
    suggested_fix:
      type: string
```

## Event System

For monitoring and integration:

```yaml
Events:
  AgentStarted:
    data:
      agent_id: string
      feature_name: string
      config: object
      timestamp: date-time

  IterationCompleted:
    data:
      agent_id: string
      iteration: integer
      output_size: integer
      files_modified: array[string]
      timestamp: date-time

  HandoffUpdated:
    data:
      agent_id: string
      status: string
      next_steps: array[string]
      timestamp: date-time

  AgentCompleted:
    data:
      agent_id: string
      status: string
      total_iterations: integer
      duration_seconds: float
      timestamp: date-time

  ReviewCompleted:
    data:
      agent_id: string
      score: integer
      issues_found: integer
      fixes_applied: integer
      timestamp: date-time

  FileModified:
    data:
      file_path: string
      change_type: enum[created, modified, deleted]
      timestamp: date-time
```

## Storage Specifications

### Directory Structure

```yaml
ProjectStructure:
  specs_directory:
    path: ".specs/{feature-name}/"
    contents:
      - AGENT-PROMPT.md
      - HANDOFF.md
      - analysis.json
      - README.md
      - context/
        - instructions.md
        - progress.md
        - findings.md
        - achievements.md
      - master-context/  # Only for multi-phase
        - phases.json
        - agents.json
        - coordination.log

  output_directory:
    path: ".ai-dr/"
    contents:
      - agent-runs/
        - {feature-name}/
          - {timestamp}/
            - iteration_{n}.log
            - config.json
            - summary.json
      - prompts/
        - {date}/
          - prompt_{timestamp}.md
      - HANDOFF.md  # Latest handoff
```

### File Formats

#### analysis.json
```json
{
  "prompt": "Original user prompt",
  "task_type": "complex",
  "complexity_score": 0.75,
  "feature_name": "user-authentication",
  "max_iterations": 15,
  "enable_code_review": true,
  "relevant_files": ["src/auth.js", "src/user.js"],
  "timestamp": "2024-01-15T10:30:00Z",
  "model": "sonnet"
}
```

#### iteration_output.log
```
=== Iteration 3 of 10 ===
Timestamp: 2024-01-15T10:32:45Z
Model: claude-3-sonnet

[Claude response content here...]

Files modified:
- src/auth.js
- src/user.js
- tests/auth.test.js

Output size: 2456 bytes
Duration: 12.3 seconds
```

## Implementation Guidelines

### 1. Error Handling

All implementations MUST:
- Return appropriate error states
- Log errors with context
- Provide recovery mechanisms
- Clean up resources on failure

```yaml
ErrorResponse:
  type: object
  required: [error, code, message]
  properties:
    error:
      type: boolean
      const: true
    code:
      type: string
      enum: [
        API_ERROR,
        RATE_LIMIT,
        INVALID_CONFIG,
        FILE_NOT_FOUND,
        TIMEOUT,
        PERMISSION_DENIED
      ]
    message:
      type: string
    details:
      type: object
    timestamp:
      type: string
      format: date-time
```

### 2. Rate Limiting

Implementations MUST respect:
- API rate limits
- Configurable delays between iterations
- Exponential backoff on errors

```yaml
RateLimitConfig:
  iteration_delay_seconds:
    type: integer
    default: 15
  review_delay_seconds:
    type: integer
    default: 15
  fix_delay_seconds:
    type: integer
    default: 2
  max_retries:
    type: integer
    default: 3
  backoff_multiplier:
    type: float
    default: 1.5
```

### 3. Logging

Standard log levels and formats:

```yaml
LogEntry:
  level:
    type: enum
    values: [DEBUG, INFO, WARN, ERROR, FATAL]
  timestamp:
    type: string
    format: date-time
  component:
    type: string
  message:
    type: string
  context:
    type: object
```

## SDK Implementation Examples

### Python Implementation

```python
from typing import Optional, Dict, Any
from dataclasses import dataclass
from enum import Enum

class Status(Enum):
    STARTING = "starting"
    IN_PROGRESS = "in-progress"
    COMPLETE = "complete"
    ERROR = "error"

@dataclass
class AgentConfig:
    prompt: str
    max_iterations: int = 10
    enable_code_review: bool = False
    rate_limit_seconds: int = 15
    model: str = "sonnet"
    feature_name: Optional[str] = None

class AgentExecutor:
    def run(self, config: AgentConfig) -> Dict[str, Any]:
        """Execute agent with given configuration"""
        pass

    def stop(self, agent_id: str) -> bool:
        """Stop a running agent"""
        pass
```

### TypeScript Implementation

```typescript
interface AgentConfig {
  prompt: string;
  maxIterations?: number;
  enableCodeReview?: boolean;
  rateLimitSeconds?: number;
  model?: 'sonnet' | 'opus' | 'haiku';
  featureName?: string;
}

interface AgentResult {
  status: 'running' | 'complete' | 'error' | 'timeout';
  iterationsCompleted: number;
  finalHandoff: Handoff;
  outputs: IterationOutput[];
  error?: string;
}

class AgentExecutor {
  async run(config: AgentConfig): Promise<AgentResult> {
    // Implementation
  }

  async stop(agentId: string): Promise<boolean> {
    // Implementation
  }
}
```

### Go Implementation

```go
package agent

type Status string

const (
    StatusStarting   Status = "starting"
    StatusInProgress Status = "in-progress"
    StatusComplete   Status = "complete"
    StatusError      Status = "error"
)

type AgentConfig struct {
    Prompt           string `json:"prompt"`
    MaxIterations    int    `json:"max_iterations"`
    EnableCodeReview bool   `json:"enable_code_review"`
    RateLimitSeconds int    `json:"rate_limit_seconds"`
    Model            string `json:"model"`
    FeatureName      string `json:"feature_name,omitempty"`
}

type AgentExecutor interface {
    Run(config AgentConfig) (*AgentResult, error)
    Stop(agentID string) error
}
```

## Testing Requirements

### Unit Tests

Each implementation MUST test:
- Configuration validation
- Handoff parsing and generation
- Context file operations
- Error handling
- Rate limiting

### Integration Tests

- End-to-end execution with mock LLM
- Multi-phase orchestration
- Live server WebSocket updates
- Code review cycle
- File system operations

### Performance Tests

- Iteration timing
- Memory usage over long runs
- Concurrent agent execution
- File watching efficiency
- WebSocket connection limits

## Compliance Checklist

Implementations MUST:

- [ ] Support all required interfaces
- [ ] Handle errors gracefully
- [ ] Implement rate limiting
- [ ] Provide comprehensive logging
- [ ] Create proper directory structures
- [ ] Parse and generate valid handoffs
- [ ] Support context file management
- [ ] Emit standard events
- [ ] Pass all test requirements
- [ ] Document API usage

## Version Compatibility

Current specification version: **1.0.0**

Breaking changes will increment major version.
Additions will increment minor version.
Fixes will increment patch version.

Implementations SHOULD specify which specification version they support.

## License

This specification is provided under MIT license for maximum compatibility with various implementations.