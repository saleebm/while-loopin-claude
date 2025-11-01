# 🎨 Color Art Generator - Claude Loop Example

A super simple, visual example app to test the autonomous Claude agent loop. Watch Claude make improvements in real-time!

## What's This?

This is a tiny Node.js app that prints colorful ASCII art. Perfect for testing because:
- ✨ Changes are **immediately visible** when you run the app
- 🎨 Colorful output = instant dopamine
- 📝 Small codebase = easy to understand what changed
- 🚀 Fast iterations = quick feedback loop

## Current Features

The starter app includes:
- A simple heart ASCII art
- Colorful terminal output
- Basic banner printing

## Quick Start

### 1. Test the app right now:
```bash
node color-art.js
```

You should see a beautiful red heart! ❤️

### 2. Run Claude to improve it:
```bash
# From the repo root:
bash examples/color-art-app/run-agent.sh
```

This will kick off an autonomous agent that will:
1. Read the code
2. Make improvements (add new art, features, colors, animations, etc.)
3. Create a handoff document showing what it did
4. Run for up to 3 iterations

### 3. Watch the changes:
```bash
# After each iteration, run the app again:
node color-art.js

# See what changed:
git diff color-art.js
```

## Fun Prompts to Try

Want to guide Claude in a specific direction? Edit `AGENT-PROMPT.md` with ideas like:

**Visual Enhancements:**
```
Add a rainbow gradient effect to the heart
Draw a star shape in blue
Add a rotating animation (frame by frame in terminal)
Create a whole gallery of different shapes (star, diamond, tree, cat)
```

**Features:**
```
Add command-line arguments to choose which art to display
Add a random art picker that shows a different shape each time
Make the colors cycle through rainbow colors
Add a "sparkle" effect with random characters around the shapes
```

**Polish:**
```
Add more elaborate borders and frames
Create ASCII art of your favorite emoji
Add a credits/about section
Make it display the time in artistic digits
```

## What to Expect

After running the agent loop, you'll see:

1. **New files created:**
   - `.ai-dr/agent-runs/<timestamp>/` - Full logs of each iteration
   - `HANDOFF.md` - Summary of what Claude did

2. **Code changes:**
   - Check `git diff` to see exactly what changed
   - Usually: new functions, more art, better colors, new features

3. **Visible results:**
   - Just run `node color-art.js` again to see the improvements!

## Example Agent Run Output

```
🤖 Starting Claude Autonomous Agent
📝 Prompt: examples/color-art-app/AGENT-PROMPT.md
🔄 Max iterations: 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Iteration 1 of 3
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Claude makes improvements...]

✅ Iteration 1 complete
📊 Output size: 1.2 KB

[Continues for more iterations...]
```

## Tips for Maximum Dopamine

1. **Run the app before and after** - Visual diff is satisfying!
2. **Use git diff** - See exactly what code changed
3. **Try specific prompts** - Guide Claude to add features you want
4. **Enable speech** - Hear progress updates:
   ```bash
   ENABLE_SPEECH=true bash examples/color-art-app/run-agent.sh
   ```
5. **Enable code review** - Get quality feedback:
   ```bash
   ENABLE_CODE_REVIEW=true bash examples/color-art-app/run-agent.sh
   ```

## Troubleshooting

**No changes happening?**
- Check `HANDOFF.md` to see what Claude is thinking
- Try a more specific prompt in `AGENT-PROMPT.md`
- Increase iterations: Edit `run-agent.sh` and change `MAX_ITERATIONS=3` to `5`

**Want to start fresh?**
```bash
git checkout color-art.js
rm -rf .ai-dr/agent-runs/*
rm HANDOFF.md
```

## What Makes This Fun

- **Immediate feedback** - Run the app, see the changes
- **Visual changes** - Colors and ASCII art are fun to watch evolve
- **Low stakes** - It's just a fun art generator, experiment freely!
- **Iterative improvement** - Each run makes it better
- **Transparency** - See exactly what the agent is doing

Enjoy watching Claude build something cool! 🚀
