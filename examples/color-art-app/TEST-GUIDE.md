# Test Guide - Color Art App Live Development

## Starting State

✅ **Clean slate ready for Claude to engineer!**

The app currently shows:
- Simple HSLA color wheel with 6 rotating circles
- Click interaction spawns particle bursts
- Smooth animations on black background

## Quick Test (Recommended)

**3 iterations, 5 second rate limit, no prompts:**

```bash
cd /Users/minasaleeb/workspaces/me/while-loopin-claude
bash examples/quick-test.sh
```

This will:
1. ✅ Start live server on port 3000
2. 🌐 Auto-open browser with the app
3. 📊 Show progress overlay in top-right
4. 🤖 Run Claude for 3 iterations
5. 🔄 Auto-reload browser as changes are made
6. 💚 Maximum dopamine!

## Interactive Test

**Full configuration with prompts:**

```bash
cd /Users/minasaleeb/workspaces/me/while-loopin-claude
bash examples/color-art-app/run-agent-live.sh
```

You'll hear alert sounds 🔔 and be prompted to configure:
1. Max iterations (choose 3 for quick demo)
2. Speech feedback (optional)
3. Code review (optional)
4. Rate limiting (5s recommended for fast demo)
5. Auto-open browser (yes recommended)

## Manual Test (Server Only)

**Just run the live server without agent:**

```bash
cd /Users/minasaleeb/workspaces/me/while-loopin-claude
npm run art:live
```

Then open http://localhost:3000 manually to see the current app.

## What to Watch For

### In the Browser
- 🎨 **Visual changes** - Pattern complexity, colors, effects
- 🖱️ **New interactions** - Mouse tracking, buttons, controls
- ✨ **Animation improvements** - Smoother motion, new modes
- 📊 **Progress overlay** - Shows current iteration and status

### In the Terminal
- 🔄 **Iteration progress** - "Iteration 1 of 3"
- ⏱️ **Rate limiting** - Wait between iterations
- ✅ **Completion status** - "Agent marked work as complete"
- 📝 **File changes** - What Claude modified

## Expected Results

After 3 iterations, you should see:
- ✨ More visually impressive animation than the starting point
- 🎨 Likely improvements:
  - More complex patterns (spirals, fractals, etc.)
  - Better color schemes
  - New interactive features
  - UI controls or mode switching
- 💾 All changes in `index.html` (self-contained)
- 📄 Updated `HANDOFF.md` with what Claude did

## Success Indicators

✅ **Working correctly if:**
- Browser opens automatically
- Progress overlay shows in top-right corner
- Page auto-reloads when Claude makes changes
- Iteration count updates in overlay
- Final result looks more impressive than starting point

❌ **Issues to watch for:**
- Port 3000 already in use → Try `PORT=8080 bash ...`
- WebSocket connection fails → Check browser console
- No auto-reload → Verify live server is running
- No progress updates → Check port 3001 is available

## Clean Up After Test

The live server keeps running after the agent completes. To stop:

```bash
# Press Ctrl+C in the terminal
```

To reset for another test:

```bash
cd /Users/minasaleeb/workspaces/me/while-loopin-claude/examples/color-art-app
git checkout index.html
rm HANDOFF.md
```

## Advanced: Custom Configuration

```bash
# Fast iteration with speech
MAX_ITERATIONS=5 \
RATE_LIMIT_SECONDS=5 \
ENABLE_SPEECH=true \
INTERACTIVE_MODE=false \
bash examples/color-art-app/run-agent-live.sh

# Extended run with code review
MAX_ITERATIONS=10 \
RATE_LIMIT_SECONDS=15 \
ENABLE_CODE_REVIEW=true \
INTERACTIVE_MODE=false \
bash examples/color-art-app/run-agent-live.sh
```

## Troubleshooting

### "Port 3000 already in use"
```bash
PORT=8080 bash examples/quick-test.sh
```

### "Module 'ws' not found"
```bash
npm install
```

### Browser doesn't open
```bash
# Open manually:
open http://localhost:3000  # macOS
```

### No progress updates in overlay
- Check terminal shows "Progress API listening on http://localhost:3001"
- Verify curl is installed: `which curl`
- Updates are optional, agent still works without them

## Files to Check After Test

```bash
# See what Claude changed
git diff examples/color-art-app/index.html

# Read what Claude said it did
cat examples/color-art-app/HANDOFF.md

# See full iteration logs
ls -la .ai-dr/agent-runs/color-art-app/
```

## Demo Recording Tips

For maximum wow factor when showing this to others:

1. **Split screen** - Terminal on left, browser on right
2. **Enable speech** - `ENABLE_SPEECH=true` for audio feedback
3. **Use quick test** - 3 iterations with 5s rate limit
4. **Watch the overlay** - Shows real-time progress
5. **Point out auto-reload** - Page refreshes instantly

---

Ready to watch Claude build! 🚀✨
