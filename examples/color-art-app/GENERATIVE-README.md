# 🌈 Generative Art Playground - HSLA Color Magic

An ambitious web-based generative art playground where Claude autonomously builds mesmerizing visual experiences using HSLA color theory, procedural generation, and canvas animations.

## 🎯 What's This?

Inspired by **21st.dev MCP's** instant UI generation, this is a generative art playground that:
- Creates **unique, never-repeating** visual patterns
- Uses **HSLA color theory** (analogous, complementary, triadic harmonies)
- Generates and displays **hex color codes** from HSLA values
- Animates smoothly at **60 FPS** with thousands of elements
- Lets you **interact and explore** different generative modes

## 🚀 Quick Start

### 1. See the starter version:
```bash
open index.html
# or serve it:
python3 -m http.server 8000
# Visit: http://localhost:8000
```

You'll see a simple rotating rainbow circle pattern. Nice, but about to get **mind-blowing**...

### 2. Let Claude transform it:
```bash
bash run-generative-agent.sh
```

Claude will work for **5 iterations**, adding:
- Multiple generative art patterns (spirals, particles, fractals, etc.)
- Advanced HSLA color palette generation
- Interactive controls and UI panels
- Smooth animations and effects
- Creative surprises that make you go "whoa!"

### 3. Experience the transformation:
```bash
open index.html
# Marvel at the beauty! 🎨✨
```

## 🎨 What Claude Will Build

Based on the ambitious prompt, expect:

### Color Theory Magic
- **ColorPalette class** generating harmonious HSLA schemes
- **HSLA → HEX conversion** displayed in real-time
- **Dynamic color harmonies**: analogous, complementary, triadic, split-complementary
- **Themed palettes**: cyberpunk, vaporwave, organic, cosmic, neon

### Generative Art Patterns
Pick 3-5 from this inspiring list:
- 🌀 **Flow fields** - Perlin noise particle streams
- 📐 **Sacred geometry** - Fibonacci spirals, golden ratio
- 🌳 **Fractal trees** - Recursive branching with color
- ✨ **Particle systems** - Emergent swarm behavior
- 🌊 **Wave interference** - Hypnotic moiré patterns
- 🔬 **Cellular automata** - Game of Life with colors
- 🔷 **Voronoi diagrams** - Organic cell structures
- ∞ **Lissajous curves** - Mathematical beauty
- 🔮 **Kaleidoscope** - Symmetrical mirrored art
- 🌌 **Plasma effects** - Retro demoscene vibes

### Interactivity
- **Mode switcher** - Cycle through different patterns
- **Mouse interaction** - Trails, forces, click spawning
- **Keyboard controls** - Live parameter tweaking
- **Speed controls** - Slow-mo or hyperspeed
- **Color scheme switcher** - Change palettes on the fly

### Visual Polish
- **Glow effects** - Layered bloom
- **Blend modes** - `globalCompositeOperation` magic
- **Trails** - Beautiful fading paths
- **UI panel** - Show palette, FPS, pattern name, seed
- **Export** - Save frames as PNG
- **Fullscreen** - Immersive mode

## 🎪 The Creative Prompt

The `AGENT-PROMPT-GENERATIVE.md` is designed to inspire Claude to:

1. **Think like a creative coder** - Experiment, be bold, try wild ideas
2. **Use color theory** - HSLA everywhere, show hex codes
3. **Build modular systems** - Clean classes, reusable functions
4. **Optimize for 60 FPS** - Smooth with thousands of elements
5. **Add surprise elements** - Unexpected flourishes that delight
6. **Make it reproducible** - Seed-based generation

## 📊 Success Criteria

After Claude's work, you should have:
- ✅ **3+ distinct generative patterns** (switchable)
- ✅ **ColorPalette system** with HSLA → HEX display
- ✅ **60 FPS animation** with visual complexity
- ✅ **Interactive UI** showing controls and info
- ✅ **Clean, modular code** that's easy to understand
- ✅ **"Whoa!" moments** that make you stare in awe

## 🎓 Inspiration

This prompt draws from:
- **21st.dev MCP** - Instant, beautiful, modern generation
- **p5.js / Processing** - Creative coding classics
- **Shadertoy** - Mathematical visual beauty
- **Bees & Bombs** - Perfect loop aesthetics
- **Nature of Code** - Generative systems

## 🔥 Extra Ideas for Future Iterations

If you want to push further, edit the prompt to add:
- **Physics simulations** (gravity, springs, attraction)
- **Audio reactivity** (Web Audio API visualization)
- **3D transforms** (perspective, depth)
- **Shader effects** (god rays, chromatic aberration)
- **Generative typography** (letters from particles)
- **Data visualization** (beautiful real-time data)
- **SVG export** (infinite resolution)

## 💡 Tips for Maximum Wow

1. **Run it multiple times** - Each agent run explores different creative directions
2. **Edit the prompt** - Guide Claude toward specific patterns you want
3. **Increase iterations** - Change `MAX_ITERATIONS=5` to `10` in the script
4. **Enable code review** - Get quality feedback on the generative code
5. **Watch the git diff** - See how the code evolves
6. **Share the results** - Post screenshots, show friends!

## 🎯 Command Quick Reference

```bash
# Run the generative agent (5 iterations)
bash run-generative-agent.sh

# With speech updates
ENABLE_SPEECH=true bash run-generative-agent.sh

# With code review
ENABLE_CODE_REVIEW=true bash run-generative-agent.sh

# Both!
ENABLE_SPEECH=true ENABLE_CODE_REVIEW=true bash run-generative-agent.sh

# View the result
open index.html

# Or serve it locally
python3 -m http.server 8000
# Visit http://localhost:8000

# Check what changed
git diff index.html

# Read the handoff
cat HANDOFF-GENERATIVE.md

# Reset and try again
git checkout index.html
rm -rf HANDOFF-GENERATIVE.md
```

## 🌟 Why This is Awesome

- **Immediate visual impact** - Open HTML, instant beauty
- **Pure creativity** - No constraints, just artistic code
- **Color theory in action** - Learn HSLA harmonies visually
- **Endless variety** - Each run creates something unique
- **Inspiring** - Makes you want to code your own art
- **Shareable** - Screenshots look amazing

## 🎨 The Goal

Create something so visually captivating that people:
1. Open `index.html`
2. Go "WHOA!"
3. Stare for minutes, mesmerized
4. Wonder "how does this even work?!"
5. Want to build their own generative art

Let Claude be your creative coding partner. Watch as AI transforms simple starter code into a hypnotic visual experience! 🌈✨

**Enjoy the generative magic!** 🚀
