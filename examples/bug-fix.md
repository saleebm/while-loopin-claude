# Bug Fix Example

This example demonstrates using the agent to fix a bug with code review enabled.

## The Bug

A function that calculates totals is returning incorrect values when given negative numbers.

## Setup

First create the buggy code:

```bash
mkdir -p src
cat > src/calculator.ts << 'EOF'
export function calculateTotal(items: number[]): number {
  let total = 0;
  for (const item of items) {
    // BUG: Should handle negative numbers
    total += Math.abs(item);
  }
  return total;
}
EOF
```

## Run Agent with Code Review

```bash
# Enable code review to catch issues
ENABLE_CODE_REVIEW=true bun run agent "$(cat examples/bug-fix.md)"
```

## Task Details

Fix the `calculateTotal` function in `src/calculator.ts`:

**Current behavior:**
```typescript
calculateTotal([10, -5, 20]) // Returns 35 (wrong!)
```

**Expected behavior:**
```typescript
calculateTotal([10, -5, 20]) // Should return 25
```

**Bug:** The function uses `Math.abs()` which converts negative numbers to positive. Remove the `Math.abs()` call.

**Also create test:**
```typescript
import { test, expect } from "bun:test";
import { calculateTotal } from "./calculator";

test("calculateTotal handles negative numbers", () => {
  expect(calculateTotal([10, -5, 20])).toBe(25);
});

test("calculateTotal handles all positive", () => {
  expect(calculateTotal([10, 20, 30])).toBe(60);
});

test("calculateTotal handles all negative", () => {
  expect(calculateTotal([-10, -20, -30])).toBe(-60);
});
```

## Completion Criteria

1. Fix the bug in `src/calculator.ts`
2. Create test file `src/calculator.test.ts`
3. Run tests and verify they pass
4. Write handoff with:
   - Session End marker
   - Status: complete
   - What was fixed
   - Test results

## Expected Flow

With code review enabled:

1. **Main agent loop:** Fixes the bug, creates tests
2. **Code review:** Reviews the fix
3. **Quality checks:** Runs lint and typecheck
4. **Re-review:** Verifies fix meets quality standards

## Verification

```bash
# Run tests
bun test src/calculator.test.ts

# Check review output
cat .ai-dr/agent-runs/bug-fix/reviews/review_1.log
cat .ai-dr/agent-runs/bug-fix/reviews/review_1.json

# Review handoff
cat .specs/bug-fix/HANDOFF.md
```

## Expected Output Structure

```
.specs/bug-fix/
├── AGENT-PROMPT.md
├── HANDOFF.md
├── analysis.json
└── README.md

.ai-dr/agent-runs/bug-fix/
├── iteration_*.log
└── reviews/
    ├── review_1.log
    ├── review_1.json
    ├── lint_1.log
    └── typecheck_1.log

src/
├── calculator.ts      # Fixed
└── calculator.test.ts # New
```
