#!/usr/bin/env node
// Plays the Hearthdelve cellar. A long-lived hearthsim play process holds the fight.

import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const pkg = path.join(root, 'Packages/HearthSimCLI');

const TOOLS = [
  {
    name: 'look',
    description: 'The cellar fight right now: hero, souls, Flask, Ward, potion, and the nearest foes.',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'act',
    description: 'Press one button. button is flask, ward, potion, pause, resume, x1, x2, or x4. The press lands on the next tick.',
    inputSchema: {
      type: 'object',
      properties: { button: { type: 'string' } },
      required: ['button'],
    },
  },
  {
    name: 'step',
    description: 'Let the tactics fight for this many ticks. 20 ticks is one second. Caps at 600.',
    inputSchema: {
      type: 'object',
      properties: { ticks: { type: 'number' } },
    },
  },
  {
    name: 'play',
    description: 'Let the tactics fight for a few seconds, then report the room. Caps at 30 seconds.',
    inputSchema: {
      type: 'object',
      properties: { seconds: { type: 'number' } },
    },
  },
  {
    name: 'restart',
    description: 'Start a new life. Pass seed to choose it; otherwise the seed increments.',
    inputSchema: {
      type: 'object',
      properties: { seed: { type: 'number' } },
    },
  },
];

function binary() {
  const candidates = [
    path.join(pkg, '.build/debug/HearthSimCLI'),
    path.join(pkg, '.build/out/Products/Debug/HearthSimCLI'),
  ];
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  const built = spawnSync('swift', ['build', '--package-path', pkg], { cwd: root, encoding: 'utf8' });
  if (built.status !== 0) {
    throw new Error((built.stderr || built.stdout || 'swift build failed').slice(-400));
  }
  for (const candidate of candidates) {
    if (existsSync(candidate)) return candidate;
  }
  throw new Error('HearthSimCLI binary was not found after swift build.');
}

let child = null;
let buffer = '';
let waiters = [];

function ensure() {
  if (child && child.exitCode === null && child.signalCode === null) return;
  buffer = '';
  child = spawn(binary(), ['play'], { cwd: root, stdio: ['pipe', 'pipe', 'pipe'] });
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', (chunk) => {
    buffer += chunk;
    let nl;
    while ((nl = buffer.indexOf('\n')) !== -1) {
      const line = buffer.slice(0, nl).trim();
      buffer = buffer.slice(nl + 1);
      if (!line) continue;
      const waiter = waiters.shift();
      if (!waiter) continue;
      try {
        waiter.resolve(JSON.parse(line));
      } catch (err) {
        waiter.reject(err);
      }
    }
  });
  child.on('exit', () => {
    const error = new Error('hearthsim play exited');
    for (const waiter of waiters) waiter.reject(error);
    waiters = [];
    child = null;
  });
}

function ask(op) {
  ensure();
  return new Promise((resolve, reject) => {
    waiters.push({ resolve, reject });
    child.stdin.write(`${JSON.stringify(op)}\n`);
  });
}

function write(msg) {
  const json = JSON.stringify(msg);
  process.stdout.write(`Content-Length: ${Buffer.byteLength(json)}\r\n\r\n${json}`);
}

function extractJson(s, from = 0) {
  const start = s.indexOf('{', from);
  if (start === -1) return null;
  let depth = 0;
  let inStr = false;
  let esc = false;
  for (let i = start; i < s.length; i++) {
    const ch = s[i];
    if (inStr) {
      if (esc) { esc = false; continue; }
      if (ch === '\\') { esc = true; continue; }
      if (ch === '"') inStr = false;
      continue;
    }
    if (ch === '"') { inStr = true; continue; }
    if (ch === '{') depth++;
    else if (ch === '}') {
      depth--;
      if (depth === 0) return { json: s.slice(start, i + 1), end: i + 1 };
    }
  }
  return null;
}

function takeMessage(buf) {
  const crlf = buf.indexOf('\r\n\r\n');
  const lf = buf.indexOf('\n\n');
  const headerEnd = crlf !== -1 ? crlf : lf;
  const sepLen = crlf !== -1 ? 4 : lf !== -1 ? 2 : 0;
  if (headerEnd !== -1 && sepLen) {
    const header = buf.subarray(0, headerEnd).toString('utf8');
    const match = /Content-Length:\s*(\d+)/i.exec(header);
    if (match) {
      const len = Number(match[1]);
      const start = headerEnd + sepLen;
      if (buf.length < start + len) return null;
      return { msg: JSON.parse(buf.subarray(start, start + len).toString('utf8')), rest: buf.subarray(start + len) };
    }
  }
  const s = buf.toString('utf8');
  const extracted = extractJson(s);
  if (!extracted) return null;
  return { msg: JSON.parse(extracted.json), rest: Buffer.from(s.slice(extracted.end)) };
}

function text(body, isError = false) {
  return { content: [{ type: 'text', text: body }], ...(isError ? { isError: true } : {}) };
}

async function tool(name, args) {
  let reply;
  if (name === 'look') reply = await ask({ op: 'look' });
  else if (name === 'act') reply = await ask({ op: 'act', button: args.button });
  else if (name === 'step') reply = await ask({ op: 'step', ticks: Number(args.ticks) || 20 });
  else if (name === 'play') reply = await ask({ op: 'play', seconds: Number(args.seconds) || 5 });
  else if (name === 'restart') reply = await ask({ op: 'restart', seed: args.seed });
  else return text(`Unknown tool ${name}`, true);
  if (!reply || reply.ok === false) return text(reply?.error || 'No answer from the cellar.', true);
  return text(String(reply.text || ''));
}

async function handle(msg) {
  if (!msg.method || msg.id === undefined) return;
  if (msg.method === 'initialize') {
    const requested = typeof msg.params?.protocolVersion === 'string' ? msg.params.protocolVersion : '2025-06-18';
    write({
      jsonrpc: '2.0',
      id: msg.id,
      result: {
        protocolVersion: requested,
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: 'hearthdelve', version: '0.1.0' },
        instructions: 'Headless Hearthdelve cellar, same room as the app. look, then act with flask, ward, or potion. step and play let the tactics fight. restart begins a new seed. This does not drive the phone screen.',
      },
    });
    return;
  }
  if (msg.method === 'ping') {
    write({ jsonrpc: '2.0', id: msg.id, result: {} });
    return;
  }
  if (msg.method === 'tools/list') {
    write({ jsonrpc: '2.0', id: msg.id, result: { tools: TOOLS } });
    return;
  }
  if (msg.method === 'prompts/list') {
    write({ jsonrpc: '2.0', id: msg.id, result: { prompts: [] } });
    return;
  }
  if (msg.method === 'resources/list') {
    write({ jsonrpc: '2.0', id: msg.id, result: { resources: [] } });
    return;
  }
  if (msg.method === 'tools/call') {
    try {
      write({ jsonrpc: '2.0', id: msg.id, result: await tool(String(msg.params?.name ?? ''), msg.params?.arguments ?? {}) });
    } catch (err) {
      write({ jsonrpc: '2.0', id: msg.id, result: text(err instanceof Error ? err.message : String(err), true) });
    }
    return;
  }
  write({ jsonrpc: '2.0', id: msg.id, error: { code: -32601, message: `Method not found: ${msg.method}` } });
}

let buf = Buffer.alloc(0);
let chain = Promise.resolve();
process.stdin.on('data', (chunk) => {
  buf = Buffer.concat([buf, Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)]);
  while (true) {
    let taken = null;
    try { taken = takeMessage(buf); } catch { break; }
    if (!taken) break;
    buf = taken.rest;
    chain = chain.then(() => handle(taken.msg));
  }
});
process.stdin.resume();
