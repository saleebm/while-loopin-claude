# Fun Prompt Ideas for Color Art App

Copy any of these into `AGENT-PROMPT.md` to guide Claude in different directions!

## 🌈 Visual Effects

```markdown
Add a rainbow gradient effect to all the ASCII art. Make the heart cycle through
different colors from top to bottom.
```

```markdown
Create 5 different ASCII art shapes (star, diamond, tree, rocket, cat) and display
them all in a gallery format with different colors for each.
```

```markdown
Add a "sparkle" effect - randomly place small decorative characters (*, ·, ✦, ✧)
around the main art to make it shimmer.
```

## 🎮 Interactive Features

```markdown
Add command-line arguments so users can choose:
- Which art to display (--art star, --art heart, etc.)
- Which color scheme (--color rainbow, --color ocean, etc.)
- Random mode (--random) that picks a different art each time

Example: node color-art.js --art star --color blue
```

```markdown
Create an interactive menu that lets users select which art to view.
Show numbered options and let them type their choice.
```

## 🎪 Animations

```markdown
Create a simple animation by displaying multiple "frames" of ASCII art in sequence.
For example, make a heart pulse (small, medium, large, medium, small) or
a star twinkle. Use setTimeout to show each frame.
```

```markdown
Add a loading animation that plays before showing the main art.
Use classic ASCII spinners or progress bars.
```

## 🎨 Art Gallery

```markdown
Build a complete ASCII art gallery with at least 10 different pieces:
- Emoji-style faces (happy, sad, winking)
- Nature (tree, flower, sun, moon)
- Objects (house, car, gift box)
- Animals (cat, dog, bird, fish)

Display them in a grid or let users browse through them.
```

## 🎯 Themed Collections

```markdown
Create a "Space Theme" collection with ASCII art of:
- Rockets
- Planets
- Stars
- Astronauts
- UFOs

Use appropriate colors (white/yellow for stars, red/orange for rockets, etc.)
```

```markdown
Create a "Seasonal Theme" mode that shows different art based on the current month:
- Winter: snowflakes, snowman
- Spring: flowers, butterflies
- Summer: sun, beach
- Fall: leaves, pumpkins
```

## 🛠️ Technical Challenges

```markdown
Add a feature to save the colored ASCII art to an HTML file that preserves
the colors using CSS. Let users share their art!
```

```markdown
Make the art responsive to terminal width. Detect the terminal size and
scale/adjust the art to fit perfectly.
```

```markdown
Add a "custom art" mode where users can provide their own ASCII art in a
text file and the app will colorize it for them.
```

## 🎪 Just For Fun

```markdown
Add a "dad joke" that prints along with each piece of art.
Make the jokes color-themed or art-themed.
```

```markdown
Create an "ASCII art of the day" feature that shows a different piece
each day of the week, with fun facts or quotes.
```

```markdown
Add sound effects using the terminal bell (\x07) at strategic moments,
like when revealing art or completing animations.
```

## 🚀 Progressive Enhancement

Use these in sequence to build up the app step by step:

**Iteration 1:**
```markdown
Add 3 new ASCII art shapes (star, diamond, tree) with different colors.
Make them display in sequence.
```

**Iteration 2:**
```markdown
Add command-line argument support so users can choose which art to display.
Add a --help flag that shows all available options.
```

**Iteration 3:**
```markdown
Add a random mode that picks a random art, and add better borders/frames
around each piece with decorative elements.
```

## Pro Tips

- **Be specific** - The more details you provide, the better Claude can help
- **Start small** - Begin with simple changes, then iterate
- **Have fun** - This is a playground, experiment wildly!
- **Mix and match** - Combine multiple ideas in one prompt

Example combined prompt:
```markdown
1. Add ASCII art for: star (yellow), tree (green), rocket (red/orange)
2. Add command-line args to choose which one to display
3. Add a --random flag that shows a random art
4. Make each art piece have a decorative border
5. Add a fun tagline below each art piece
```
