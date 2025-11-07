# 🚀 Quick Start - Live Development Mode

## The Dopamine Experience

Watch Claude code in real-time with live browser preview and progress overlay!

## One-Line Start

```bash
bash examples/color-art-app/run-agent-live.sh
```

Follow the interactive prompts (with sound alerts 🔔).

## Skip Prompts

```bash
bash examples/quick-test.sh
```

Fast demo: 3 iterations, 5s rate limit, auto-opens browser.

## Custom Configuration

```bash
# Set any options via environment variables:
MAX_ITERATIONS=5 \
ENABLE_SPEECH=true \
RATE_LIMIT_SECONDS=10 \
INTERACTIVE_MODE=false \
bash examples/color-art-app/run-agent-live.sh
```

## What You Get

✨ **Browser opens automatically** → See your app
📊 **Progress overlay** → Know what Claude is doing
🔄 **Auto-reload** → Changes appear instantly
🎮 **Interactive config** → Control everything
🔔 **Sound alerts** → Hear when input needed
🗣️ **Speech feedback** → Optional audio updates

## All Options

| Variable | Values | Default |
|----------|--------|---------|
| `MAX_ITERATIONS` | 1-100 | 3 |
| `ENABLE_SPEECH` | true/false | false |
| `ENABLE_CODE_REVIEW` | true/false | false |
| `RATE_LIMIT_SECONDS` | 1-300 | 15 |
| `AUTO_OPEN` | true/false | true |
| `INTERACTIVE_MODE` | true/false | true |
| `PORT` | 1024-65535 | 3000 |

## More Info

- Full docs: `examples/color-art-app/LIVE-DEVELOPMENT.md`
- Complete summary: `LIVE-MODE-SUMMARY.md`
- Interactive prompts: `examples/test-interactive-prompts.sh`

---

**Maximum dopamine. Minimum setup. Pure joy.** 💚
