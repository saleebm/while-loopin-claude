#!/usr/bin/env node

/**
 * Color Art Generator - A simple ASCII art app
 * Watch this get better with each Claude iteration!
 */

// ANSI color codes
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
};

function printBanner(text) {
  console.log(colors.cyan + '═'.repeat(50) + colors.reset);
  console.log(colors.yellow + '  ' + text + colors.reset);
  console.log(colors.cyan + '═'.repeat(50) + colors.reset);
}

function drawHeart() {
  const heart = [
    '  ♥♥♥    ♥♥♥  ',
    ' ♥♥♥♥♥  ♥♥♥♥♥ ',
    '♥♥♥♥♥♥♥♥♥♥♥♥♥♥',
    '♥♥♥♥♥♥♥♥♥♥♥♥♥♥',
    ' ♥♥♥♥♥♥♥♥♥♥♥♥ ',
    '  ♥♥♥♥♥♥♥♥♥♥  ',
    '   ♥♥♥♥♥♥♥♥   ',
    '    ♥♥♥♥♥♥    ',
    '     ♥♥♥♥     ',
    '      ♥♥      ',
  ];

  heart.forEach(line => {
    console.log(colors.red + line + colors.reset);
  });
}

function main() {
  printBanner('🎨 Color Art Generator v1.0');
  console.log('\n');
  drawHeart();
  console.log('\n');
  console.log(colors.green + '✨ Made with love by autonomous agents!' + colors.reset);
}

main();
