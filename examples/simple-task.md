# Simple Task Example

This example shows the minimal setup to run an autonomous agent task.

## The Task

Create a simple greeting function and test file.

## How to Run

```bash
# From project root
bun run agent "$(cat examples/simple-task.md)"
```

## Expected Behavior

The AI will:
1. Analyze this prompt
2. Create `.specs/simple-task/` directory structure
3. Generate enhanced prompt with context
4. Run agent loop to complete the task
5. Create handoff with completion status

## Task Details

Create two files in the project:

1. **src/greeter.ts**
```typescript
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
```

2. **src/greeter.test.ts**
```typescript
import { test, expect } from "bun:test";
import { greet } from "./greeter";

test("greet returns greeting", () => {
  expect(greet("World")).toBe("Hello, World!");
});
```

## Completion Criteria

Write handoff to `.specs/simple-task/HANDOFF.md` with:
- Session End marker
- Status: complete
- Confirmation both files created
- Test results

## Expected Output Structure

```
.specs/simple-task/
├── AGENT-PROMPT.md    # Enhanced prompt
├── HANDOFF.md         # Final status
├── analysis.json      # AI configuration
└── README.md          # Navigation

.ai-dr/agent-runs/simple-task/
├── iteration_1_*.log
└── iteration_2_*.log  # (if needed)

src/
├── greeter.ts
└── greeter.test.ts
```

## Verification

After agent completes:

```bash
# Run the test
bun test src/greeter.test.ts

# Check handoff
cat .specs/simple-task/HANDOFF.md

# Review agent output
ls -la .ai-dr/agent-runs/simple-task/
```
