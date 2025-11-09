# 🚀 Live Development Mode - Complete Summary

## What Was Built

A complete **live development system** that lets users watch Claude code in real-time with a browser-based progress overlay and interactive configuration system.

## Key Features

### 1. Live Browser Preview
- **Auto-opens browser** when agent starts
- **Real-time progress overlay** in top-right corner showing:
  - Current iteration (e.g., "3 / 5")
  - Animated progress bar
  - Live status messages
  - Timestamps
- **Auto-reloads** on file changes via WebSocket
- **Non-obtrusive UI** with hover effects

### 2. Interactive Configuration System
- **Sound alerts** 🔔 before each prompt (plays system sound)
- **Speech prompts** 🗣️ if enabled (macOS `say` command)
- **Modular prompt functions**:
  - `prompt_select()` - Single-choice menus
  - `prompt_multiselect()` - Multi-choice menus
  - `prompt_confirm()` - Yes/no questions
  - `prompt_text()` - Text input with defaults
- **Complete control** via environment variables

### 3. Reusable Architecture
All components are modular and reusable:
- `lib/live-server.js` - Standalone Node.js server
- `lib/claude-functions.sh` - Shell function library
- `run-agent-live.sh` - Example integration

## Files Created/Modified

### New Files
```
lib/live-server.js                              # Live server with WebSocket
examples/color-art-app/run-agent-live.sh        # Enhanced agent runner
examples/color-art-app/LIVE-DEVELOPMENT.md      # Complete documentation
examples/quick-test.sh                          # Quick demo script
LIVE-MODE-SUMMARY.md                            # This file
```

### Modified Files
```
package.json                                    # Added ws dependency & scripts
lib/claude-functions.sh                         # Added update_live_progress()
examples/README.md                              # Added live mode section
```

## Quick Start

### Interactive Mode (Default)
```bash
bash examples/color-art-app/run-agent-live.sh
```

You'll be prompted for:
- Max iterations (3/5/10/20)
- Speech feedback (y/n)
- Code review (y/n)
- Rate limiting (5s/15s/30s)
- Auto-open browser (y/n)

### Quick Test (Non-Interactive)
```bash
bash examples/quick-test.sh
```

Fast defaults: 3 iterations, 5s rate limit, no speech/review.

### Custom Configuration
```bash
# Full control
MAX_ITERATIONS=5 \
ENABLE_SPEECH=true \
RATE_LIMIT_SECONDS=10 \
INTERACTIVE_MODE=false \
bash examples/color-art-app/run-agent-live.sh
```

## How It Works

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Browser (http://localhost:3000)                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Your App (index.html)                              │   │
│  │  + Injected Progress Overlay                        │   │
│  │  + WebSocket Client                                 │   │
│  └─────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │ WebSocket (reload & progress updates)
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Live Server (Node.js - lib/live-server.js)                 │
│  • Serves files with injected overlay HTML/CSS/JS           │
│  • WebSocket server for live updates                        │
│  • File watcher (auto-reload on changes)                    │
│  • Progress API endpoint (HTTP POST on port 3001)           │
└──────────────────────┬───────────────────────────────────────┘
                       │ HTTP POST progress updates
                       ▼
┌──────────────────────────────────────────────────────────────┐
│  Agent Runner (Bash - run-agent-live.sh)                    │
│  1. Interactive configuration prompts (if enabled)          │
│  2. Starts live server in background                        │
│  3. Runs agent loop with Claude                             │
│  4. Sends progress updates via update_live_progress()       │
│  5. Cleans up on exit                                       │
└──────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Startup**
   - Script prompts user for configuration (if interactive)
   - Starts Node.js live server
   - Server opens browser to http://localhost:3000
   - Server injects overlay into HTML

2. **During Agent Loop**
   - Agent calls `update_live_progress()` with status
   - Function POSTs JSON to http://localhost:3001/update
   - Server broadcasts update via WebSocket
   - Browser receives update and refreshes overlay UI

3. **On File Changes**
   - Server's file watcher detects changes
   - Server broadcasts reload message via WebSocket
   - Browser reloads page automatically

4. **Cleanup**
   - Trap on EXIT kills live server process
   - Graceful shutdown

## Interactive Prompt System

### Function Reference

All functions in `lib/claude-functions.sh`:

```bash
# Sound and speech
play_alert()                    # Play system alert sound
speak_prompt TEXT               # Speak text if ENABLE_SPEECH=true

# Input prompts
prompt_text QUESTION [DEFAULT]              # Text input
prompt_select QUESTION OPT1 OPT2 ...        # Single choice (returns 1-based index)
prompt_multiselect QUESTION OPT1 OPT2 ...   # Multi choice (returns space-sep indices)
prompt_confirm QUESTION [DEFAULT]           # Yes/no (returns 0 for yes, 1 for no)

# Convenience dispatcher
prompt_user TYPE QUESTION [OPTIONS...]      # Auto-dispatches to correct function

# Progress updates
update_live_progress ITER MAX STATUS [MSG]  # Send progress to live server
```

### Usage Examples

```bash
# Single select
MODEL=$(prompt_select "Choose model:" "sonnet" "opus" "haiku")
case $MODEL in
  1) echo "Selected sonnet" ;;
  2) echo "Selected opus" ;;
  3) echo "Selected haiku" ;;
esac

# Confirm
if prompt_confirm "Enable feature?" "y"; then
  echo "Feature enabled"
fi

# Text input
NAME=$(prompt_text "Enter name:" "default-name")

# Multi select
FEATURES=$(prompt_multiselect "Select features:" "auth" "db" "api")
# User enters: 1 3
# $FEATURES contains: "1 3"
```

## Configuration Options

All settings support environment variable override:

| Variable | Description | Values | Default |
|----------|-------------|--------|---------|
| `INTERACTIVE_MODE` | Enable interactive prompts | true/false | true |
| `MAX_ITERATIONS` | Number of agent iterations | 1-100 | 3 |
| `ENABLE_SPEECH` | Enable text-to-speech | true/false | false |
| `ENABLE_CODE_REVIEW` | Run code review after | true/false | false |
| `RATE_LIMIT_SECONDS` | Delay between iterations | 1-300 | 15 |
| `AUTO_OPEN` | Auto-open browser | true/false | true |
| `PORT` | Live server port | 1024-65535 | 3000 |
| `WATCH_DIR` | Directory to serve/watch | path | (script dir) |

## Reusability

### Use in Your Own Projects

#### 1. Use the Live Server

```bash
# Start server for any HTML app
WATCH_DIR=/path/to/your/app node lib/live-server.js
```

The overlay will be auto-injected into any HTML files.

#### 2. Use Interactive Prompts

```bash
# Source the functions
source /path/to/while-loopin-claude/lib/claude-functions.sh

# Use in your scripts
play_alert
CHOICE=$(prompt_select "What to do?" "Option 1" "Option 2" "Option 3")
```

#### 3. Send Progress Updates

```bash
# From your agent scripts
source /path/to/while-loopin-claude/lib/claude-functions.sh

update_live_progress 1 5 "running" "Starting task 1..."
update_live_progress 2 5 "running" "Processing data..."
update_live_progress 5 5 "complete" "All done!"
```

#### 4. Full Integration Example

```bash
#!/usr/bin/env bash
source /path/to/while-loopin-claude/lib/claude-functions.sh

# Interactive config
if [[ "${INTERACTIVE_MODE:-true}" == "true" ]]; then
  play_alert
  ITERATIONS=$(prompt_select "Iterations?" "3" "5" "10")

  if prompt_confirm "Enable logging?" "y"; then
    LOGGING=true
  fi
fi

# Start live server (if available)
WATCH_DIR=$(pwd) node /path/to/while-loopin-claude/lib/live-server.js &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null" EXIT

# Your agent loop
for ((i=1; i<=$ITERATIONS; i++)); do
  update_live_progress $i $ITERATIONS "running" "Iteration $i..."

  # Your work here

done

update_live_progress $ITERATIONS $ITERATIONS "complete" "Done!"
```

## Customization Ideas

### Overlay Styling
Edit `lib/live-server.js` in the `injectLiveReload()` function:
- Change colors (default: Matrix green theme)
- Reposition overlay (default: top-right)
- Adjust animations
- Add more UI elements

### Additional Prompt Types
Add to `lib/claude-functions.sh`:
- Slider inputs
- Date/time pickers
- File selection
- Multi-step wizards

### Server Features
Extend `lib/live-server.js`:
- Add authentication
- Multiple concurrent sessions
- Save/replay progress history
- Screenshot each iteration
- Record video

## Testing

### Quick Syntax Check
```bash
# Validate bash syntax
bash -n examples/color-art-app/run-agent-live.sh
bash -n lib/claude-functions.sh

# Test JavaScript
node -c lib/live-server.js
```

### Manual Testing
```bash
# Test interactive prompts only
bash examples/test-interactive-prompts.sh

# Test live server only
npm run art:live

# Test full integration
bash examples/quick-test.sh
```

## Troubleshooting

### Port Already in Use
```bash
PORT=8080 bash examples/color-art-app/run-agent-live.sh
```

### WebSocket Not Connecting
- Check browser console for errors
- Verify live server is running
- Try refreshing the page

### Prompts Not Working
- Ensure running in interactive terminal (not piped)
- Check `INTERACTIVE_MODE` not set to false
- Verify functions sourced correctly

### Alert Sound Not Playing (macOS)
- Check system sound is enabled
- Verify `/System/Library/Sounds/Glass.aiff` exists
- Try different sound file in `play_alert()`

### Speech Not Working (macOS)
- Set `ENABLE_SPEECH=true`
- Verify `say` command works: `say "test"`
- Check system TTS settings

## Performance Considerations

- **Rate limiting** prevents API overload (default 15s)
- **WebSocket** more efficient than polling
- **File watching** uses native OS events (fs.watch)
- **Progress updates** are non-blocking (silent fail if server not running)
- **Minimal injection** (~5KB overhead per HTML file)

## Future Enhancements

Ideas for expansion:
- [ ] Multiple agent support (split-screen view)
- [ ] Mobile-responsive overlay
- [ ] Replay mode (re-run from saved state)
- [ ] Collaborative mode (multiple viewers)
- [ ] Plugin system for custom overlays
- [ ] Integration with VS Code
- [ ] Desktop notifications
- [ ] Slack/Discord webhooks
- [ ] Metrics dashboard
- [ ] Time-lapse video generation

## Contributing

All code follows the project's core principles:
- **Keep it simple** - Shell script orchestration
- **AI does thinking** - No hard-coded logic
- **Composability** - Reusable functions
- **DRY documentation** - Reference, don't repeat

See `CLAUDE.md` for full development guidelines.

## Summary

This live development system delivers **maximum dopamine** by making AI development visual, interactive, and engaging. Watch Claude build your app in real-time, configure everything with sound-enabled prompts, and enjoy the satisfaction of seeing code evolve before your eyes.

**Core value:** Transforms passive "wait and check" into active "watch and enjoy."

---

Built with 🤖 + 💚 for the While Loopin' Claude project.
