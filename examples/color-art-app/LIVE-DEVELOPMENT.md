# 🚀 Live Development Mode

**Experience maximum dopamine while watching Claude build your app in real-time!**

## What Is This?

Live Development Mode adds a **live browser preview** with a **real-time progress overlay** that shows you exactly what Claude is doing as it happens. Watch your app evolve before your eyes!

## Features

### 🌐 Live Browser Preview
- **Auto-opens** your app in the browser when agent starts
- **Auto-reloads** instantly when files change
- **Zero configuration** required

### 📊 Real-Time Progress Overlay
A beautiful, non-obtrusive overlay in the top-right corner shows:
- ⚙️ Current iteration number (e.g., "3 / 5")
- 📈 Progress bar with gradient animation
- 💬 Live status updates from Claude
- ⏱️ Timestamp of last update
- 🎨 Smooth animations and transitions

### ✨ The Dopamine Effect
- **See changes immediately** - No manual refreshing
- **Visual progress** - Know exactly what's happening
- **Satisfying animations** - Smooth, professional UI
- **Zero interruption** - Overlay stays out of your way

### 🎮 Interactive Configuration
- **Sound alerts** - Plays a chime before each prompt
- **Speech prompts** - Hear questions if speech enabled
- **Smart defaults** - Quick demo (3 iterations) by default
- **Full control** - Override any setting with env vars

## Quick Start

### 1. Run with Live Mode (Interactive)

```bash
# From the repo root:
bash examples/color-art-app/run-agent-live.sh
```

**You'll be prompted to configure:**
1. 🔄 **Max iterations** - Choose 3 (quick), 5 (standard), 10 (extended), or 20 (deep work)
2. 🔊 **Speech feedback** - Hear progress updates spoken aloud
3. ✅ **Code review** - Run quality checks after completion
4. ⏱️ **Rate limiting** - Choose 5s (fast), 15s (standard), or 30s (conservative)
5. 🌐 **Auto-open browser** - Launch browser automatically

Each prompt plays an alert sound 🔔 and speaks the question (if speech enabled).

### 1b. Run Non-Interactive (Skip Prompts)

```bash
# Use environment variables to skip prompts:
INTERACTIVE_MODE=false MAX_ITERATIONS=3 bash examples/color-art-app/run-agent-live.sh

# Or set all options upfront:
MAX_ITERATIONS=5 \
ENABLE_SPEECH=true \
RATE_LIMIT_SECONDS=10 \
AUTO_OPEN=true \
bash examples/color-art-app/run-agent-live.sh
```

### 2. Watch the Magic

You'll see:
1. 🌐 Browser opens to `http://localhost:3000`
2. 🎨 Your art app loads with the progress overlay
3. 🤖 Claude starts working (shown in overlay)
4. ✨ App auto-reloads as Claude makes changes
5. 📊 Progress updates in real-time

### 3. Keep the Server Running

The live server stays running after the agent completes. This lets you:
- Continue seeing your app in the browser
- Make manual edits and see them instantly
- Experiment with the code

Press `Ctrl+C` when you're done.

## How It Works

### Architecture

```
┌─────────────────┐     WebSocket     ┌──────────────┐
│  Live Server    │ ◄────────────────►│   Browser    │
│  (Node.js)      │                   │              │
└────────┬────────┘                   └──────────────┘
         │                                     ▲
         │ Watches files                      │
         ▼                                     │
┌─────────────────┐                           │
│  Your App       │───────────────────────────┘
│  index.html     │    Serves files + overlay
└─────────────────┘

         │
         │ HTTP POST updates
         ▼
┌─────────────────┐
│  Agent Runner   │──► update_live_progress()
│  (Bash)         │
└─────────────────┘
```

### Components

1. **lib/live-server.js** - Node.js server with:
   - File serving
   - WebSocket for live reload
   - Progress API endpoint
   - Auto-injection of overlay HTML/CSS/JS

2. **lib/claude-functions.sh** - Reusable helper functions:
   - `update_live_progress()` - Send progress to browser
   - `prompt_select()` - Single-choice menu with alert sound
   - `prompt_multiselect()` - Multi-choice menu
   - `prompt_confirm()` - Yes/no confirmation
   - `prompt_text()` - Text input with default
   - `play_alert()` - Sound notification
   - `speak_prompt()` - Text-to-speech (if enabled)

3. **run-agent-live.sh** - Enhanced runner that:
   - Interactive configuration with alert sounds
   - Starts live server in background
   - Runs agent loop with progress updates
   - Cleans up on exit

## Customization

**All settings can be overridden via environment variables!**

### Skip Interactive Mode Entirely

```bash
INTERACTIVE_MODE=false bash examples/color-art-app/run-agent-live.sh
```

### Override Individual Settings

Any setting can be pre-configured to skip its prompt:

```bash
# Set iterations without prompt
MAX_ITERATIONS=10 bash examples/color-art-app/run-agent-live.sh

# Enable speech without prompt
ENABLE_SPEECH=true bash examples/color-art-app/run-agent-live.sh

# Enable code review without prompt
ENABLE_CODE_REVIEW=true bash examples/color-art-app/run-agent-live.sh

# Set rate limit without prompt
RATE_LIMIT_SECONDS=5 bash examples/color-art-app/run-agent-live.sh

# Disable auto-open without prompt
AUTO_OPEN=false bash examples/color-art-app/run-agent-live.sh
```

### Combine Multiple Settings

```bash
# Full configuration, no prompts:
MAX_ITERATIONS=5 \
ENABLE_SPEECH=true \
ENABLE_CODE_REVIEW=true \
RATE_LIMIT_SECONDS=10 \
AUTO_OPEN=true \
bash examples/color-art-app/run-agent-live.sh
```

### Change Server Port

```bash
PORT=8080 bash examples/color-art-app/run-agent-live.sh
```

## Manual Server Usage

You can also run the live server independently:

```bash
# From repo root
npm run art:live

# Or with custom directory
WATCH_DIR=/path/to/your/app node lib/live-server.js
```

Then run your agent separately and it will automatically send progress updates.

## Overlay Customization

The overlay is injected automatically into any HTML file served. It includes:

- **Minimal footprint** - Only ~5KB of injected HTML/CSS/JS
- **No dependencies** - Pure vanilla JavaScript
- **Non-obtrusive** - Positioned in top-right, semi-transparent
- **Hover effects** - Becomes more visible when you hover
- **Auto-scrolling** - Long messages scroll automatically

### Styling

Edit the styles in `lib/live-server.js` at the `injectLiveReload()` function to customize:
- Colors (default: Matrix green theme)
- Position (default: top-right)
- Size
- Animations
- Fonts

## Troubleshooting

### Port Already in Use

If port 3000 is taken:
```bash
PORT=8080 bash examples/color-art-app/run-agent-live.sh
```

### Browser Doesn't Open

Open manually: http://localhost:3000

Or check if auto-open is disabled in your environment.

### Progress Not Updating

Make sure:
1. Live server is running (check terminal output)
2. Port 3001 is available (progress API port)
3. `curl` command is installed

### WebSocket Connection Lost

If you see "WebSocket closed" in browser console:
- Server may have stopped
- Refresh the page
- Server will auto-retry connection

## Advanced: Using in Your Own Projects

### 1. Add to Your HTML App

Just use the live server:

```bash
cd your-project
WATCH_DIR=$(pwd) node path/to/while-loopin-claude/lib/live-server.js
```

### 2. Send Progress Updates

From your scripts:

```bash
# Source the functions
source path/to/while-loopin-claude/lib/claude-functions.sh

# Send updates
update_live_progress 1 5 "running" "Starting task..."
update_live_progress 2 5 "running" "Processing data..."
update_live_progress 5 5 "complete" "All done!"
```

### 3. Integrate with Any Agent

The live server works with ANY HTML app and ANY agent runner. Just:
1. Start the server pointing to your app directory
2. Send progress updates using the helper function
3. Enjoy the dopamine!

## Why This Is Awesome

Traditional development workflow:
1. Run agent → 2. Wait → 3. Check files → 4. Open browser → 5. See changes

Live development workflow:
1. Run agent → **SEE EVERYTHING HAPPEN IN REAL-TIME!** 🚀

**Benefits:**
- ⚡ **Instant feedback** - Know immediately if something works
- 🎯 **Stay engaged** - Visual progress keeps you involved
- 🐛 **Catch issues faster** - See bugs as they appear
- 😊 **Maximum dopamine** - Watching things build is satisfying!
- 🚀 **Learn faster** - See cause and effect in real-time

## Tips for Maximum Dopamine

1. **Use dual monitors** - Terminal on one, browser on the other
2. **Enable speech** - Hear AND see progress:
   ```bash
   ENABLE_SPEECH=true bash examples/color-art-app/run-agent-live.sh
   ```
3. **Start simple** - Watch it evolve from basic to amazing
4. **Try specific prompts** - Guide Claude to add fun features
5. **Share your screen** - Show others the magic in real-time!

## What's Next?

Ideas for future enhancements:
- 📸 Screenshot each iteration
- 📹 Record video of the evolution
- 📊 Visualize metrics over time
- 🎮 Interactive controls (pause, skip, retry)
- 💬 Chat interface in the overlay
- 🎨 Theme customization UI
- 📱 Mobile-friendly overlay

## Contributing

Got ideas to make this even more dopamine-inducing?

1. Edit `lib/live-server.js` for server features
2. Edit overlay styles/behavior in the `injectLiveReload()` function
3. Add progress updates in `run-agent-live.sh`

---

**Enjoy the show!** 🎬✨

Watch Claude build amazing things while you sit back and enjoy the dopamine rush of real-time progress. This is the future of AI-assisted development!
