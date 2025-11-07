#!/usr/bin/env node

/**
 * Live Development Server for While Loopin' Claude
 *
 * Features:
 * - Serves HTML apps with live reload
 * - WebSocket-based file watching
 * - Real-time agent progress overlay
 * - Auto-opens browser
 */

import { watch } from 'fs';
import { readFile, readdir } from 'fs/promises';
import { createServer } from 'http';
import { WebSocketServer } from 'ws';
import { join, extname, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

// Configuration
const PORT = process.env.PORT || 3000;
const WATCH_DIR = process.env.WATCH_DIR || process.cwd();
const INDEX_FILE = process.env.INDEX_FILE || 'index.html';
const AGENT_OUTPUT_DIR = process.env.AGENT_OUTPUT_DIR || join(WATCH_DIR, '.ai-dr');

// MIME types
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

// Active WebSocket connections
const clients = new Set();

// Agent progress state
let agentState = {
  iteration: 0,
  maxIterations: 0,
  status: 'idle',
  lastUpdate: '',
  timestamp: Date.now()
};

/**
 * Inject live reload script and progress overlay into HTML
 */
function injectLiveReload(html) {
  const overlayStyles = `
<style id="live-reload-styles">
  #claude-progress-overlay {
    position: fixed;
    top: 10px;
    right: 10px;
    background: rgba(0, 0, 0, 0.85);
    color: #00ff00;
    padding: 12px 16px;
    border-radius: 8px;
    font-family: 'Courier New', monospace;
    font-size: 12px;
    z-index: 999999;
    box-shadow: 0 4px 12px rgba(0, 255, 0, 0.2);
    border: 1px solid rgba(0, 255, 0, 0.3);
    min-width: 250px;
    max-width: 400px;
    opacity: 0.9;
    transition: all 0.3s ease;
  }
  #claude-progress-overlay:hover {
    opacity: 1;
    transform: scale(1.02);
  }
  .overlay-header {
    font-weight: bold;
    color: #00ffff;
    margin-bottom: 8px;
    font-size: 14px;
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .status-idle { color: #888; }
  .status-running { color: #00ff00; animation: pulse 2s infinite; }
  .status-complete { color: #00ffff; }
  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }
  .progress-bar {
    width: 100%;
    height: 4px;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 2px;
    margin: 8px 0;
    overflow: hidden;
  }
  .progress-fill {
    height: 100%;
    background: linear-gradient(90deg, #00ff00, #00ffff);
    transition: width 0.5s ease;
  }
  .overlay-info {
    font-size: 11px;
    line-height: 1.6;
    color: #aaa;
  }
  .overlay-update {
    margin-top: 8px;
    padding-top: 8px;
    border-top: 1px solid rgba(255, 255, 255, 0.1);
    color: #fff;
    font-size: 11px;
    max-height: 100px;
    overflow-y: auto;
  }
</style>`;

  const overlayHTML = `
<div id="claude-progress-overlay">
  <div class="overlay-header">
    <span>🤖</span>
    <span id="status-text">Claude Agent: Idle</span>
  </div>
  <div class="progress-bar">
    <div class="progress-fill" id="progress-fill" style="width: 0%"></div>
  </div>
  <div class="overlay-info">
    <div>Iteration: <span id="iteration-num">0</span> / <span id="max-iterations">0</span></div>
    <div>Status: <span id="status-detail">Waiting...</span></div>
  </div>
  <div class="overlay-update" id="last-update"></div>
</div>`;

  const script = `
<script id="live-reload-script">
  (function() {
    const ws = new WebSocket('ws://' + location.host);

    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.type === 'reload') {
        console.log('🔄 Reloading page...');
        location.reload();
      } else if (data.type === 'progress') {
        updateProgress(data.state);
      }
    };

    ws.onclose = () => {
      console.log('WebSocket closed. Retrying in 2s...');
      setTimeout(() => location.reload(), 2000);
    };

    function updateProgress(state) {
      const statusText = document.getElementById('status-text');
      const progressFill = document.getElementById('progress-fill');
      const iterationNum = document.getElementById('iteration-num');
      const maxIterations = document.getElementById('max-iterations');
      const statusDetail = document.getElementById('status-detail');
      const lastUpdate = document.getElementById('last-update');

      if (!statusText) return;

      // Update iteration
      iterationNum.textContent = state.iteration || 0;
      maxIterations.textContent = state.maxIterations || 0;

      // Update progress bar
      const progress = state.maxIterations ?
        (state.iteration / state.maxIterations) * 100 : 0;
      progressFill.style.width = progress + '%';

      // Update status
      statusText.textContent = 'Claude Agent: ' +
        (state.status || 'idle').charAt(0).toUpperCase() +
        (state.status || 'idle').slice(1);
      statusText.className = 'status-' + (state.status || 'idle');

      statusDetail.textContent = state.statusDetail || 'Waiting...';

      // Update last message
      if (state.lastUpdate) {
        const time = new Date(state.timestamp).toLocaleTimeString();
        lastUpdate.innerHTML = \`<strong>[\${time}]</strong> \${state.lastUpdate}\`;
      }
    }

    console.log('🚀 Live reload enabled');
  })();
</script>`;

  // Inject before closing body tag
  return html
    .replace('</head>', overlayStyles + '</head>')
    .replace('</body>', overlayHTML + script + '</body>');
}

/**
 * Serve static files
 */
async function serveFile(filePath, res) {
  try {
    const content = await readFile(filePath);
    const ext = extname(filePath);
    const contentType = MIME_TYPES[ext] || 'text/plain';

    res.writeHead(200, { 'Content-Type': contentType });

    // Inject live reload for HTML files
    if (ext === '.html') {
      res.end(injectLiveReload(content.toString()));
    } else {
      res.end(content);
    }
  } catch (error) {
    res.writeHead(404);
    res.end('Not found');
  }
}

/**
 * HTTP server
 */
const server = createServer(async (req, res) => {
  let filePath = join(WATCH_DIR, req.url === '/' ? INDEX_FILE : req.url);

  // Serve agent state API
  if (req.url === '/api/agent-state') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(agentState));
    return;
  }

  await serveFile(filePath, res);
});

/**
 * WebSocket server for live reload
 */
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
  clients.add(ws);
  console.log('📱 Client connected. Total clients:', clients.size);

  // Send current agent state
  ws.send(JSON.stringify({ type: 'progress', state: agentState }));

  ws.on('close', () => {
    clients.delete(ws);
    console.log('📱 Client disconnected. Total clients:', clients.size);
  });
});

/**
 * Broadcast message to all connected clients
 */
function broadcast(message) {
  const payload = JSON.stringify(message);
  clients.forEach(client => {
    if (client.readyState === 1) { // OPEN
      client.send(payload);
    }
  });
}

/**
 * Watch for file changes
 */
function setupFileWatcher() {
  const watchPaths = [
    join(WATCH_DIR, INDEX_FILE),
    join(WATCH_DIR, '*.js'),
    join(WATCH_DIR, '*.css')
  ];

  console.log('👀 Watching for changes in:', WATCH_DIR);

  watch(WATCH_DIR, { recursive: false }, (eventType, filename) => {
    if (filename && !filename.includes('.ai-dr')) {
      console.log('📝 File changed:', filename);
      broadcast({ type: 'reload' });
    }
  });
}

/**
 * Watch agent output directory for progress updates
 */
function setupAgentWatcher() {
  try {
    watch(AGENT_OUTPUT_DIR, { recursive: true }, async (eventType, filename) => {
      if (filename && filename.includes('HANDOFF.md')) {
        await updateAgentState();
      }
    });
    console.log('🤖 Watching agent output:', AGENT_OUTPUT_DIR);
  } catch (error) {
    console.log('⚠️  Agent output directory not found (will create when agent runs)');
  }
}

/**
 * Update agent state from HANDOFF.md
 */
async function updateAgentState() {
  try {
    const handoffPath = join(WATCH_DIR, 'HANDOFF.md');
    const content = await readFile(handoffPath, 'utf-8');

    // Parse handoff for status
    const statusMatch = content.match(/Status:\s*(\w+)/i);
    const iterationMatch = content.match(/iteration[:\s]+(\d+)/i);

    if (statusMatch) {
      agentState.status = statusMatch[1].toLowerCase();
      agentState.timestamp = Date.now();

      // Extract last meaningful line
      const lines = content.split('\n').filter(l => l.trim());
      agentState.lastUpdate = lines[lines.length - 1].substring(0, 100);

      if (iterationMatch) {
        agentState.iteration = parseInt(iterationMatch[1]);
      }

      broadcast({ type: 'progress', state: agentState });
      console.log('📊 Agent state updated:', agentState.status);
    }
  } catch (error) {
    // Handoff not yet created
  }
}

/**
 * API endpoint to update agent progress (called from shell scripts)
 */
function setupProgressAPI() {
  // Listen on a separate simple server for updates from shell
  const progressServer = createServer(async (req, res) => {
    if (req.method === 'POST' && req.url === '/update') {
      let body = '';
      req.on('data', chunk => { body += chunk; });
      req.on('end', () => {
        try {
          const update = JSON.parse(body);
          Object.assign(agentState, update);
          broadcast({ type: 'progress', state: agentState });
          res.writeHead(200);
          res.end('OK');
        } catch (error) {
          res.writeHead(400);
          res.end('Bad request');
        }
      });
    } else {
      res.writeHead(404);
      res.end();
    }
  });

  progressServer.listen(PORT + 1, () => {
    console.log(`📡 Progress API listening on http://localhost:${PORT + 1}/update`);
  });
}

/**
 * Start server
 */
server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log('');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🚀 While Loopin\' Claude - Live Server');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('');
  console.log(`📍 Serving: ${WATCH_DIR}`);
  console.log(`🌐 URL: ${url}`);
  console.log('');
  console.log('✨ Features enabled:');
  console.log('   • Live reload on file changes');
  console.log('   • Real-time agent progress overlay');
  console.log('   • Auto-refresh on code updates');
  console.log('');
  console.log('Press Ctrl+C to stop');
  console.log('');

  setupFileWatcher();
  setupAgentWatcher();
  setupProgressAPI();

  // Auto-open browser
  if (process.env.AUTO_OPEN !== 'false') {
    import('child_process').then(({ exec }) => {
      const openCmd = process.platform === 'darwin' ? 'open' :
        process.platform === 'win32' ? 'start' : 'xdg-open';
      exec(`${openCmd} ${url}`);
      console.log('🌐 Opening browser...');
    });
  }
});
