# Structured JSON Extraction System

## Overview

Centralized system for extracting structured review data from Claude output using AI SDK's `generateObject`.

## Architecture

### Wrapper Function
**Location:** `lib/claude-functions.sh`
**Function:** `generate_structured_review_json()`

This is the ONLY place you need to modify to change the implementation.

```bash
generate_structured_review_json INPUT_FILE [ADDITIONAL_JSON] [PROJECT_DIR]
```

### Current Implementation
**Script:** `lib/extract-review-json.ts`
**Technology:** Bun + AI SDK (Anthropic) + Zod schema validation

## Output Schema

```json
{
  "speech": "Concise 1-sentence summary (max 15 words)",
  "score": 8,
  "critical_fixes": ["issue 1", "issue 2"],
  "suggestions": ["suggestion 1"],
  "summary": "2-3 sentence overview",
  ...additional_fields
}
```

## Changing Implementation

### Option 1: Switch to Python

Edit `lib/claude-functions.sh`, line ~191:

```bash
# OLD:
REVIEW_JSON=$(bun "$PROJECT_DIR/lib/extract-review-json.ts" "$INPUT_FILE" "$ADDITIONAL_JSON" 2>/dev/null)

# NEW:
REVIEW_JSON=$(python3 "$PROJECT_DIR/lib/extract-review-json.py" "$INPUT_FILE" "$ADDITIONAL_JSON" 2>/dev/null)
```

### Option 2: Switch to different AI provider

Edit `lib/extract-review-json.ts`, line ~39:

```typescript
// OLD:
model: anthropic("claude-3-5-haiku-20241022"),

// NEW:
model: openai("gpt-4o-mini"),
```

### Option 3: Use different model

Edit `lib/extract-review-json.ts`, line ~39:

```typescript
// Change to different Claude model:
model: anthropic("claude-3-5-sonnet-20241022"),
```

## Usage in Code

The wrapper is used in two places:
- `lib/code-review.sh` (code review cycle)
- `lib/agent-runner.sh` (main agent loop)

Both call it the same way:

```bash
local REVIEW_JSON=$(generate_structured_review_json "$REVIEW_OUTPUT" '{}' "$PROJECT_DIR")
```

## Benefits

1. **Single Point of Change** - Modify implementation in ONE function
2. **Error Handling** - Built-in validation and fallback
3. **Flexibility** - Easy to swap languages/providers/models
4. **Consistency** - All code uses same interface
5. **Type Safety** - Zod schema ensures correct structure

## Testing

```bash
# Source the functions
source lib/claude-functions.sh

# Create test review
echo "Score: 8/10. Fix security bug." > /tmp/review.txt

# Test with additional fields
generate_structured_review_json /tmp/review.txt '{"custom": "data"}' "$(pwd)" | jq '.'

# Verify custom field merged
generate_structured_review_json /tmp/review.txt '{"test": "value"}' "$(pwd)" | jq '.test'
```

## Dependencies

Current implementation requires:
- Bun runtime
- `ai` package (AI SDK)
- `@ai-sdk/anthropic` package
- `zod` package

Install:
```bash
bun add ai @ai-sdk/anthropic zod
```

## Future Considerations

If replacing with Python, your script should:
1. Accept same CLI args: `script.py INPUT_FILE [ADDITIONAL_JSON]`
2. Output valid JSON to stdout
3. Use stderr for warnings/errors
4. Exit code 0 on success
5. Match the output schema (or update validation in wrapper)



