<!-- 8df4be60-86b0-427c-b3f2-eaf5b33a061b 0521c4eb-3bff-491b-8deb-27c358a7a0ed -->
# Modular Agent Runner Refactor + Auto-Handoff + Installer

## Objectives

- **Preserve flows**: agent loop, handoff-driven continuation, code review cycle.
- **Add auto-handoff** per iteration (Claude decides create/update, writes correct path).
- **Ensure JSON correctness** for structured steps; unique paths per run/iteration.
- **Modularize** into singular-purpose shell libs; DRY via shared helpers.
- **DX**: add TypeScript installer and simple validation tests.

## Key Files To Change/Add

- Change: `lib/agent-runner.sh` (delegate to helpers; wire new handoff step; keep signature)
- Change: `lib/claude-functions.sh` (add `run_claude_json`, keep `generate_structured_output`)
- Add: `lib/handoff-functions.sh` (handoff decision + write)
- Move/Extract: review helpers to `lib/code-review.sh` (re-export for back-compat)
- Add: `lib/speech.sh`, `lib/utils.sh` (optional, small helpers)
- Add: `templates/handoff-system-prompt.md` (prompt for decision/format)
- Add: `scripts/install.ts` (TS installer CLI)
- Add: `tests/test_loop.sh`, `tests/test_handoff.sh`, `tests/test_review.sh`

## Behavior To Preserve

- `run_claude_agent PROMPT HANDOFF OUTPUT_DIR MAX_ITERS [--enable-code-review --max-reviews N --enable-speech --rate-limit N]`
- Iteration outputs: `OUTPUT_DIR/iteration_N_<RUN_ID>.log`
- Review outputs: `OUTPUT_DIR/reviews/review_N.log|json`
- Continuation prompt generation unchanged.

## Improvements

- **All Claude calls central**: use `run_claude`/`run_claude_json` only.
- **RUN_ID** subdir: `OUTPUT_DIR/<RUN_ID>/...` for per-execution isolation.
- **Auto-handoff** step after each iteration: structured decision + write.
- **CLI correctness**: verify flags via `claude --help` during dev; structured steps use `--output-format json` and unwrap `.result`.

## Targeted Edits (concise)

- Replace direct CLI call in agent loop with `run_claude`:
```568:575:/Users/minasaleeb/workspaces/me/while-loopin-claude/lib/agent-runner.sh
    if ! claude \
      --print \
      --dangerously-skip-permissions \
      --output-format text \
      "$CURRENT_PROMPT" \
      2>&1 | tee "$OUTPUT_FILE"; then
```

- After iteration completes, call new `ensure_handoff` before stop/continue logic (keeps existing checks):
  - `ensure_handoff OUTPUT_FILE HANDOFF_FILE PROJECT_DIR ITERATION OUTPUT_DIR`
  - Produces `handoff_decision_ITERATION.json` and updates `HANDOFF.md` if `should_create`.

- Reuse structured extraction for review already present:
```96:105:/Users/minasaleeb/workspaces/me/while-loopin-claude/lib/claude-functions.sh
  local HAIKU_RAW=$(claude \
    --print \
    --model haiku \
    --output-format json \
    --dangerously-skip-permissions \
    "$PROMPT" || echo '{"type":"result","result":"{\"speech\": \"Processing complete\", \"error\": true}"}')
  local HAIKU_RESULT=$(echo "$HAIKU_RAW" | jq -r '.result')
```


## New Handoff Flow

- `generate_handoff_prompt(iter_output, prior_handoff?, template)` → text prompt
- `decide_handoff(prompt)` → JSON `{ should_create, end_session, status, handoff_markdown }` via Haiku JSON
- `write_handoff(handoff_path, markdown)` (append or overwrite, default overwrite)
- `ensure_handoff(...)` orchestrates the above and logs `handoff_decision_N.json`
- Stop conditions unchanged: stop when `Session End` and `Status.*complete` present.

## CLI Additions (back-compat)

- `--handoff [auto|manual|off]` (default `auto`)
- `--handoff-template PATH` (default `templates/handoff-system-prompt.md` if exists)
- `--output-dir PATH` still supported; internally append `<RUN_ID>`.

## TypeScript Installer (DX)

- `scripts/install.ts` (Node/TS):
  - Copies `lib/*.sh` + `templates/*` into target repo (default `.specs/_shared`)
  - Ensures idempotent updates (hash compare), creates `bin/` shim scripts.
  - Adds `"agent:run"` script to target `package.json` if present.
  - Usage: `bunx tsx scripts/install.ts --target /path/to/repo --shared-path .specs/_shared`

## Simple Tests

- `tests/test_loop.sh`: runs `test_agent` with 2 iterations; asserts output files exist.
- `tests/test_handoff.sh`: feed trivial prompt; ensure `HANDOFF.md` auto-created and contains `Session End` and `Status`.
- `tests/test_review.sh`: run with `--enable-code-review --max-reviews 1`; assert `reviews/review_1.json` exists and valid JSON.
- `tests/test_json.sh`: pipe small text into `generate_structured_output`; assert valid JSON and `speech` key.

## Rollout Steps

1. Add new libs/templates; export existing functions for back-compat via `agent-runner.sh`.
2. Refactor main loop to use `run_claude` and call `ensure_handoff`.
3. Introduce `run_claude_json` and wire structured steps.
4. Add flags parser for handoff options (defaults unchanged behavior except auto-handoff addition).
5. Add TS installer + docs, add tests, and run `bash -n`/`shellcheck` locally.

### To-dos

- [x] Add `lib/handoff-functions.sh` with ensure_handoff/decision/write APIs
- [x] Refactor `run_claude_agent` to use run_claude and call ensure_handoff
- [x] Move review helpers to `lib/code-review.sh` and re-export
- [x] Add run_claude_json helper in `lib/claude-functions.sh`
- [x] Introduce RUN_ID and nest outputs under OUTPUT_DIR/RUN_ID
- [x] Add flags: --handoff, --handoff-template, keep back-compat
- [x] Create `templates/handoff-system-prompt.md` for decision/format
- [x] Add tests: loop, handoff, review, json validation
- [x] Create `scripts/install.ts` (copy libs/templates, add package script)
- [x] Update README/QUICKREF with new flags, installer usage