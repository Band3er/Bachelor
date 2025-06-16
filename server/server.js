/*
  Server implementation to handle uniform message processing between ESP32 and Flutter
  - Commands are queued by clients via POST /command
  - ESP32 polls GET /commands to retrieve pending commands and acknowledges
  - ESP32 submits scan results via POST /results
  - Flutter polls GET /results to retrieve latest scan data
  - After Flutter reads results, server clears stored data
  - Simple in-memory queues; swap to Redis or database for production
*/

const express = require('express');
const bodyParser = require('body-parser');
const os = require('os');
const app = express();
const port = 3000;

app.use(bodyParser.json());

// In-memory storage (for production, use Redis or a database)
let commandQueue = [];
let scanResults = null;

// Helper to get local IP
function getLocalIP() {
  const interfaces = os.networkInterfaces();
  for (const name in interfaces) {
    for (const iface of interfaces[name]) {
      if (iface.family === 'IPv4' && !iface.internal) {
        return iface.address;
      }
    }
  }
  return '127.0.0.1';
}

/**
 * Client (admin or UI) pushes a new command
 * Body: { do_arp: 1|0, send_wol: 1|0, mac?: string }
 */
app.post('/commands', (req, res) => {
  const cmd = req.body;
  if (typeof cmd.do_arp !== 'number' || typeof cmd.send_wol !== 'number') {
    return res.status(400).json({ error: 'Invalid command format' });
  }
  commandQueue.push(cmd);
  console.log('[COMMAND] queued:', cmd);
  return res.json({ status: 'queued' });
});

/**
 * ESP32 polls for pending commands
 * Returns the oldest command or a no-op default
 * Once returned, that command is removed
 */
app.get('/commands', (req, res) => {
  const cmd = commandQueue.length ? commandQueue.shift() : { do_arp: 0, send_wol: 0 };
  console.log('[ESP GET] returning command:', cmd);
  res.json(cmd);
});

/**
 * ESP32 submits scan results after doing arpScan
 * Body: array of device objects
 */
app.post('/results', (req, res) => {
  scanResults = req.body;
  console.log('[ESP32 POST /results] stored:', JSON.stringify(scanResults, null, 2));

  // Dacă Flutter aștepta un răspuns, îl trimitem acum
  if (pendingFlutterRes) {
    pendingFlutterRes.json(scanResults);
    console.log('[FLUTTER GET] responded with new ESP32 data');
    scanResults = null;
    pendingFlutterRes = null;
  }

  res.json({ status: 'received' });
});


/**
 * Flutter client fetches latest scan results
 * After returning, clears stored results
 */
let pendingFlutterRes = null;

app.get('/results', (req, res) => {
  if (scanResults != null) {
    // Dacă deja avem date, le trimitem direct
    const data = scanResults;
    scanResults = null;
    console.log('[FLUTTER GET] returned immediately:', data);
    return res.json(data);
  }

  // Dacă nu avem date, stocăm răspunsul în așteptare
  console.log('[FLUTTER GET] waiting for ESP32 results...');
  pendingFlutterRes = res;

  // Set timeout de siguranță (evită blocarea infinită)
  setTimeout(() => {
    if (pendingFlutterRes === res) {
      console.log('[FLUTTER GET] timeout - no data received');
      pendingFlutterRes = null;
      res.status(204).end();  // No Content
    }
  }, 15000); // 15 secunde
});


// Start server
app.listen(port, '0.0.0.0', () => {
  const ip = getLocalIP();
  console.log(`Server running at http://${ip}:${port}`);
});
