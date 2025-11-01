#!/usr/bin/env -S node --no-warnings

/**
 * Installer for Claude agent runner libs and templates
 *
 * Usage:
 *   node scripts/install.ts --target /path/to/repo [--shared-path .specs/_shared]
 *
 * After install, you'll have:
 *   <target>/<shared-path>/{agent-runner.sh,claude-functions.sh,code-review.sh,handoff-functions.sh,smart-agent.sh}
 *   <target>/templates/handoff-system-prompt.md (if not present)
 *   package.json script: "agent:smart": "bash .specs/_shared/smart-agent.sh"
 */

import fs from 'fs';
import path from 'path';

type Args = { target: string; sharedPath: string };

function parseArgs(): Args {
  const argv = process.argv.slice(2);
  let target = '';
  let sharedPath = '.specs/_shared';
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--target' && i + 1 < argv.length) {
      target = argv[++i];
    } else if (a === '--shared-path' && i + 1 < argv.length) {
      sharedPath = argv[++i];
    }
  }
  if (!target) {
    console.error('Missing --target <path>');
    process.exit(1);
  }
  return { target: path.resolve(target), sharedPath };
}

function ensureDir(dir: string) {
  fs.mkdirSync(dir, { recursive: true });
}

function copyIfChanged(src: string, dest: string) {
  const srcBuf = fs.readFileSync(src);
  if (fs.existsSync(dest)) {
    const dstBuf = fs.readFileSync(dest);
    if (Buffer.compare(srcBuf, dstBuf) === 0) return false;
  }
  ensureDir(path.dirname(dest));
  fs.writeFileSync(dest, srcBuf);
  return true;
}

function main() {
  const { target, sharedPath } = parseArgs();

  const here = path.resolve(__dirname, '..');
  const lib = path.join(here, 'lib');
  const templates = path.join(here, 'templates');

  const targetShared = path.join(target, sharedPath);
  const targetTemplates = path.join(target, 'templates');

  const files = [
    'agent-runner.sh',
    'claude-functions.sh',
    'code-review.sh',
    'handoff-functions.sh',
    'smart-agent.sh',
  ];

  let changed = 0;
  for (const f of files) {
    const src = path.join(lib, f);
    if (!fs.existsSync(src)) continue;
    const dst = path.join(targetShared, f);
    if (copyIfChanged(src, dst)) changed++;
  }

  // Template: handoff-system-prompt.md
  const tmpl = 'handoff-system-prompt.md';
  const tmplSrc = path.join(templates, tmpl);
  const tmplDst = path.join(targetTemplates, tmpl);
  if (fs.existsSync(tmplSrc)) {
    if (!fs.existsSync(tmplDst)) {
      copyIfChanged(tmplSrc, tmplDst);
      changed++;
    }
  }

  // Add npm script if package.json exists
  const pkgPath = path.join(target, 'package.json');
  if (fs.existsSync(pkgPath)) {
    const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
    pkg.scripts = pkg.scripts || {};
    if (!pkg.scripts['agent:smart']) {
      pkg.scripts['agent:smart'] = `bash ${sharedPath}/smart-agent.sh`;
      fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
      changed++;
    }
  }

  console.log(`Installed to ${target} (${changed} file(s) changed)`);
  console.log(`Shared libs: ${targetShared}`);
}

main();


