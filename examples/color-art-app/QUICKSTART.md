# 🚀 Quick Start - 2 Minutes to Your First Agent Run

## Step 1: Test the App (30 seconds)

```bash
cd examples/color-art-app
node color-art.js
```

You should see a beautiful red heart! ❤️

## Step 2: Run the Agent (1 minute)

```bash
bash run-agent.sh
```

Watch as Claude autonomously:
- Reads your code
- Makes improvements
- Creates a handoff document
- Runs for 3 iterations

## Step 3: See the Changes (30 seconds)

```bash
# Run the improved app
node color-art.js

# See what code changed
git diff color-art.js

# Read what Claude did
cat HANDOFF.md
```

## That's It! 🎉

Want to try again with different instructions?

1. Edit `AGENT-PROMPT.md` with new ideas
2. Reset the code: `git checkout color-art.js`
3. Run again: `bash run-agent.sh`

Check `PROMPTS.md` for fun ideas to try!

---

### Optional: Enable Extra Features

**Hear progress updates:**
```bash
ENABLE_SPEECH=true bash run-agent.sh
```

**Get code quality reviews:**
```bash
ENABLE_CODE_REVIEW=true bash run-agent.sh
```

**Both at once:**
```bash
ENABLE_SPEECH=true ENABLE_CODE_REVIEW=true bash run-agent.sh
```
