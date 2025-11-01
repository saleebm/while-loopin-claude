# Build a Mind-Blowing Generative Art Playground

You are working on a web-based generative art playground (`index.html`) that creates stunning visual art using HSLA color theory and canvas animations.

## 🎯 Vision: The 21st.dev of Generative Art

Inspired by 21st.dev MCP's ability to instantly generate beautiful UI components, you're building a creative coding playground that generates mesmerizing, unique visual art through code. Think: procedural generation meets color theory meets hypnotic animation.

## 🎨 Current State

`index.html` has:
- A simple rotating rainbow circle pattern
- Basic HSLA color generation
- Click interaction that spawns particle bursts
- Animation loop with trail effects

## 🚀 Your Mission: Go Wild with Creativity

Transform this into a generative art masterpiece! Be **sporadic, experimental, and bold**. Draw inspiration from:

### Color Theory & Generation
- Implement **analogous, complementary, triadic** color harmony schemes
- Create **color palette generators** (cyberpunk, vaporwave, organic, cosmic)
- Add **HSL manipulation** (hue rotation, saturation waves, lightness pulses)
- Generate **unique hex codes** from HSLA and display them in the UI
- Create **gradient generators** (linear, radial, conic with multiple HSLA stops)

### Generative Art Patterns (Pick 3-5 to implement)
- **Flowing fields**: Perlin noise flow fields with particles following paths
- **Sacred geometry**: Spirals, fibonacci sequences, golden ratio patterns
- **Fractal trees**: Recursive branching structures with color variations
- **Particle systems**: Thousands of tiny particles forming emergent patterns
- **Wave interference**: Overlapping sine/cosine waves creating moiré effects
- **Cellular automata**: Conway's Game of Life with colorful cells
- **Voronoi diagrams**: Organic cell-like structures
- **Lissajous curves**: Mathematical parametric curves
- **Kaleidoscope effects**: Symmetrical mirrored patterns
- **Plasma effects**: Retro demoscene-style plasma animations

### Animation & Interactivity
- Multiple animation modes users can cycle through
- Mouse tracking with trails, attraction/repulsion forces
- Keyboard controls for live parameter manipulation
- Click to spawn new generative elements
- Real-time morphing between different patterns
- Speed controls, color scheme switchers
- Record/replay functionality to capture beautiful moments

### Visual Polish (Make it POP!)
- **Glow effects**: Layered semi-transparent shapes for bloom
- **Blend modes**: Experiment with `globalCompositeOperation` (lighter, screen, overlay)
- **Particle trails**: Leave beautiful fading paths
- **UI elements**: Display current color palette, FPS, pattern name
- **Export button**: Save current frame as PNG
- **Fullscreen mode**: Immersive experience

### Technical Excellence
- Clean, modular code with separate classes/functions
- Performance optimization (keep 60 FPS with thousands of elements)
- Responsive canvas (fills window, handles resize)
- Random seed system (reproducible art from seed codes)
- Color class/utilities for HSLA manipulation
- Parameter objects for easy tweaking

## 🎪 Specific Challenges to Tackle

1. **Build a "ColorPalette" class** that generates harmonious HSLA color schemes:
   ```javascript
   class ColorPalette {
     constructor(baseHue, scheme = 'analogous') {
       // Generate palette based on color theory
     }

     getColor(index, alpha = 1) {
       // Return HSLA string
     }

     toHex(hsla) {
       // Convert to hex for display
     }
   }
   ```

2. **Create at least 3 different generative art modes** users can switch between (e.g., "Cosmic Spirals", "Digital Rain", "Fractal Garden")

3. **Add a UI panel** showing:
   - Current pattern name
   - Generated color palette (show HSLA and HEX values)
   - Interactive controls (sliders, buttons)
   - FPS counter
   - Seed code for reproducibility

4. **Make it MOVE**: Everything should feel alive - pulsing, rotating, flowing, evolving

5. **Surprise factor**: Add 2-3 unexpected creative flourishes that make people say "whoa!"

## ✨ Guidelines

- **Be experimental**: Try crazy ideas, combine multiple techniques
- **Color first**: Use HSLA extensively, show off color theory
- **Smooth animations**: Aim for 60 FPS, optimize where needed
- **Instant gratification**: Every reload should look different and amazing
- **Document your colors**: Show the hex codes being generated
- **Mobile friendly**: Touch interactions should work too

## 🎓 Inspiration Sources

- **p5.js examples**: Nature of Code, generative design
- **Shadertoy**: Mathematical beauty, demoscene aesthetics
- **Processing**: Classic creative coding techniques
- **Bees & Bombs**: Perfect loops, satisfying motion
- **21st.dev Magic MCP**: Instant, beautiful, modern, polished

## 📊 Success Criteria

After your changes:
1. Opening `index.html` should be **visually stunning** immediately
2. At least **3 different generative patterns** implemented
3. **Live color palette display** with HSLA → HEX conversion
4. **Smooth 60 FPS animation** with thousands of elements
5. **Interactive controls** to explore different modes
6. Code is **clean and well-organized**
7. Someone watching should go "Whoa, how did it do that?!"

## 🔥 Extra Credit Ideas

- Physics simulation (gravity, attraction, springs)
- Audio visualization (Web Audio API reactive to sound)
- 3D effects using perspective transforms
- Shader-like effects (god rays, chromatic aberration)
- Generative typography (letters made of particles)
- Data-driven art (visualize real-time data beautifully)
- Multiple canvases layered with different blend modes
- Save as SVG for infinite resolution

## 🎯 Development Approach

Work iteratively:
1. Start with one amazing pattern
2. Add color palette system
3. Build UI controls
4. Add 2 more patterns
5. Polish interactions and animations
6. Add export/save features
7. Final creative flourishes

**Remember**: The goal is to create something people want to stare at for minutes, mesmerized by the beauty of generative code and color theory in action. Make it UNFORGETTABLE! 🌈✨
