// SPDX-License-Identifier: AGPL-3.0-only
// Shared test setup: the gateway as a local Node server with an in-memory
// store, and a fake phone that answers tool calls like the Reparc app.
import type { Server } from "node:http";
import { Gateway, configFromEnv } from "../src/gateway.js";
import { MemoryStore } from "../src/store.js";
import { startLocal } from "../src/local.js";

export const OWNER = "rok_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef";

export interface Harness {
  base: string;
  store: MemoryStore;
  gateway: Gateway;
  server: Server;
  close(): Promise<void>;
}

export async function start(env: Record<string, string> = { REPARC_OWNER_KEY: OWNER }): Promise<Harness> {
  const store = new MemoryStore();
  const config = { ...configFromEnv(env), timing: { pollIntervalMs: 10, pollWaitMs: 300, resultIntervalMs: 10, callTimeoutMs: 2000 } };
  const gateway = new Gateway(store, config);
  const server = await startLocal(gateway, 0);
  const address = server.address();
  const base = `http://127.0.0.1:${typeof address === "object" && address ? address.port : 0}`;
  return { base, store, gateway, server, close: () => new Promise((r) => server.close(() => r())) };
}

export async function api(base: string, path: string, init: RequestInit = {}, token: string | undefined = OWNER) {
  const headers: Record<string, string> = { "content-type": "application/json", ...((init.headers as Record<string, string>) ?? {}) };
  if (token) headers.authorization = `Bearer ${token}`;
  const res = await fetch(base + path, { ...init, headers });
  const text = await res.text();
  let body: any = null;
  try { body = text ? JSON.parse(text) : null; } catch { body = text; }
  return { status: res.status, body, headers: res.headers };
}

/** Polls like the app and answers each call with `answer`. Returns a stop function. */
export function fakePhone(base: string, answer: (tool: string, args: any, client: string) => unknown = (tool) => ({
  content: [{ type: "text", text: `ok ${tool}` }], structuredContent: { tool }, isError: false,
})) {
  let running = true;
  const seen: { tool: string; args: any; client: string }[] = [];
  (async () => {
    while (running) {
      try {
        const { body } = await api(base, "/v1/phone/poll");
        const calls = (body?.calls ?? []) as any[];
        if (calls.length === 0) continue;
        for (const c of calls) seen.push({ tool: c.tool, args: c.arguments, client: c.client });
        await api(base, "/v1/phone/results", { method: "POST", body: JSON.stringify({ results: calls.map((c) => ({ id: c.id, result: answer(c.tool, c.arguments, c.client) })) }) });
      } catch {
        await new Promise((r) => setTimeout(r, 20));
      }
    }
  })();
  return { seen, stop: () => { running = false; } };
}
