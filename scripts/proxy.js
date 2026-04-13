#!/usr/bin/env node
'use strict';

const http = require('http');

const INNER_PORT = parseInt(process.env.MCP_INNER_PORT || '8001', 10);
const OUTER_PORT = parseInt(process.env.MCP_PORT || '8000', 10);

// OAuth discovery endpoints that MCP clients probe before connecting.
// Returning a JSON 404 tells the SDK there is no OAuth on this server and
// it should proceed without authentication.
const OAUTH_PATHS = new Set([
  '/.well-known/oauth-authorization-server',
  '/.well-known/oauth-protected-resource',
  '/register',
]);

// --- Auth config -----------------------------------------------------------
// When MCP_AUTH_TOKEN is set, every non-exempt request must carry
//   Authorization: Bearer <token>
// Exempt: /healthz (OpenShift probes) and OPTIONS (CORS preflight).
const AUTH_TOKEN = (process.env.MCP_AUTH_TOKEN || '').trim();
const HEALTH_PATH = '/healthz';

function isExempt(req) {
  return req.method === 'OPTIONS' || req.url === HEALTH_PATH;
}

function checkAuth(req, res) {
  if (!AUTH_TOKEN) return true;
  if (isExempt(req)) return true;
  const header = req.headers['authorization'] || '';
  const match = /^Bearer\s+(\S+)$/i.exec(header);
  if (match && match[1] === AUTH_TOKEN) return true;
  res.writeHead(401, {
    'Content-Type': 'application/json',
    'WWW-Authenticate': 'Bearer realm="mcp"',
  });
  res.end('{"error":"unauthorized","error_description":"Valid Bearer token required"}');
  return false;
}
// ---------------------------------------------------------------------------

// When supergateway runs in SSE mode it listens on /sse, but most MCP clients
// (including Claude Code) default to /mcp.  Rewrite /mcp → /sse so both paths work.
const MCP_PATH = '/mcp';
const SSE_PATH = '/sse';

function rewritePath(url) {
  if (url === MCP_PATH || url.startsWith(MCP_PATH + '?')) {
    return SSE_PATH + url.slice(MCP_PATH.length);
  }
  return url;
}

const server = http.createServer((req, res) => {
  if (!checkAuth(req, res)) return;

  if (OAUTH_PATHS.has(req.url)) {
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end('{}');
    return;
  }

  const opts = {
    hostname: '127.0.0.1',
    port: INNER_PORT,
    path: rewritePath(req.url),
    method: req.method,
    headers: req.headers,
  };

  const proxy = http.request(opts, (proxyRes) => {
    res.writeHead(proxyRes.statusCode, proxyRes.headers);
    proxyRes.pipe(res, { end: true });
  });

  proxy.on('error', () => {
    if (!res.headersSent) res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end('{"error":"bad_gateway"}');
  });

  req.pipe(proxy, { end: true });
});

server.listen(OUTER_PORT, '0.0.0.0', () => {
  const authStatus = AUTH_TOKEN ? 'bearer-auth=enabled' : 'bearer-auth=disabled';
  process.stdout.write(`proxy: :${OUTER_PORT} → :${INNER_PORT} [${authStatus}]\n`);
});
