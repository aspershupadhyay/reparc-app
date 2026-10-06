// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 the Reparc contributors. Structure adapted from Latch (AGPL-3.0-only).
// HTTP routes of the Reparc gateway:
//
//   /mcp                 MCP (JSON-RPC over Streamable HTTP) for AI apps
//   /mcp/<key>           the same, for apps that accept only a URL
//   /.well-known/*, /oauth/*   OAuth 2.1 so AI apps can sign in; the owner approves in the app
//   /v1/phone/*          the Reparc app polls for tool calls and sends answers (owner key)
//   /v1/owner/*          the Reparc app manages AI apps and sign-ins (owner key)
//   /healthz, /v1/info   public, and say nothing about the owner
//
// The page at "/" is static (public/).

import { OAuth, cleanName, hostOf } from "./oauth.js";
import { Relay, type RelayTiming } from "./relay.js";
import { Sealer } from "./seal.js";
import { bearer, newId, newToken, secretsEqual, sha256 } from "./secret.js";
import type { Store } from "./store.js";
import { contract } from "./contract.js";

export interface GatewayConfig {
  /** REPARC_OWNER_KEY. Undefined or shorter than 32 characters puts the gateway in setup mode. */
  ownerKey?: string;
  publicUrl?: string;
  /** Browser origins allowed to call /mcp (for example an MCP inspector). Empty: none. */
  allowedOrigins: string[];
  timing: RelayTiming;
}

export function configFromEnv(env: NodeJS.ProcessEnv): GatewayConfig {
  const clean = (v?: string) => (v && v.trim() !== "" ? v.trim() : undefined);
  const num = (v: string | undefined, d: number) => (v && Number.isFinite(Number(v)) ? Number(v) : d);
  return {
    ownerKey: clean(env.REPARC_OWNER_KEY),
    publicUrl: clean(env.REPARC_PUBLIC_URL)?.replace(/\/+$/, ""),
    allowedOrigins: (env.REPARC_ALLOWED_ORIGINS ?? "").split(",").map((o) => o.trim().replace(/\/+$/, "")).filter(Boolean),
    timing: {
      pollIntervalMs: num(env.REPARC_POLL_INTERVAL_MS, 700),
      pollWaitMs: 25_000,
      resultIntervalMs: num(env.REPARC_RESULT_INTERVAL_MS, 250),
      callTimeoutMs: 25_000,
    },
  };
}

const VERSION = "1.0.0";
const SUPPORTED_VERSIONS: readonly string[] = contract.supported_versions;
const TOOL_NAMES = new Set<string>(contract.tools.map((t) => t.name));
/** tools/list as MCP clients see it: Reparc's own `scope` field is left out. */
const LISTED_TOOLS = contract.tools.map(({ scope: _scope, ...rest }) => rest);
const MAX_OWNER_FAILURES_PER_MINUTE = 20;
const MAX_CALLS_PER_MINUTE = 60;
const LAST_USED_WRITE_MS = 60_000;
const APPS = "reparc:apps";
const appToken = (sha: string) => `reparc:apptoken:${sha}`;

/** Which commit this deployment runs (Vercel sets these), so an owner can check it is current. */
const BUILD = process.env.VERCEL_GIT_COMMIT_SHA ? { commit: process.env.VERCEL_GIT_COMMIT_SHA.slice(0, 7) } : {};

/** On every answer: a gateway is private, so it is never indexed or framed, and HTTPS sticks. */
export const PRIVATE_HEADERS: Readonly<Record<string, string>> = {
  "x-robots-tag": "noindex, nofollow, noarchive, nosnippet, noimageindex",
  "x-frame-options": "DENY",
  "x-content-type-options": "nosniff",
  "referrer-policy": "no-referrer",
  "strict-transport-security": "max-age=63072000; includeSubDomains",
  "permissions-policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()",
  "cross-origin-resource-policy": "same-origin",
};

const json = (status: number, body: unknown, headers: Record<string, string> = {}) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json", "cache-control": "no-store", ...headers } });
const error = (status: number, message: string) => json(status, { error: message });

class BadRequest extends Error {}

async function readJson(request: Request, limit: number): Promise<unknown> {
  const declared = Number(request.headers.get("content-length") ?? "0");
  if (declared > limit) throw new BadRequest("body too large");
  const text = await request.text();
  if (text.length > limit) throw new BadRequest("body too large");
  try {
    return JSON.parse(text);
  } catch {
    throw new BadRequest("malformed JSON");
  }
}

interface AppRecord {
  id: string;
  name: string;
  kind: "oauth" | "key";
  oauth_client_id?: string;
  key_sha256?: string;
  created_at_ms: number;
  last_used_ms?: number;
}

export class Gateway {
  readonly oauth: OAuth;
  readonly relay: Relay;
  private readonly lastUsedWrites = new Map<string, number>();

  constructor(private readonly store: Store, private readonly config: GatewayConfig) {
    const ready = () => !this.setupMode;
    // Without an owner key nothing can be sealed or opened; setup mode blocks the relay anyway.
    this.relay = new Relay(store, new Sealer(config.ownerKey ?? newToken("unset")), config.timing);
    this.oauth = new OAuth(store, {
      get ready() {
        return ready();
      },
      addApp: async (name, oauthClientId) => {
        const record: AppRecord = { id: newId("app"), name, kind: "oauth", oauth_client_id: oauthClientId, created_at_ms: Date.now() };
        await store.hset(APPS, record.id, JSON.stringify(record));
        return record.id;
      },
      appExists: async (id) => (await store.hget(APPS, id)) !== null,
    });
  }

  private get setupMode() {
    return this.config.ownerKey === undefined || this.config.ownerKey.length < 32;
  }

  private baseUrl(request: Request): string {
    if (this.config.publicUrl) return this.config.publicUrl;
    const url = new URL(request.url);
    const host = request.headers.get("x-forwarded-host") ?? request.headers.get("host") ?? url.host;
    const proto = request.headers.get("x-forwarded-proto") ?? url.protocol.replace(":", "");
    return `${proto}://${host}`;
  }

  /** Client address as Vercel's edge reports it (Vercel overwrites these headers, so clients cannot set them). */
  private clientIp(request: Request): string {
    return (request.headers.get("x-real-ip") ?? request.headers.get("x-forwarded-for")?.split(",")[0] ?? "unknown").trim().slice(0, 64);
  }

  async fetch(request: Request): Promise<Response> {
    const path = new URL(request.url).pathname;
    let response: Response;
    try {
      response = await this.route(request, path);
    } catch (e) {
      if (e instanceof BadRequest) response = error(400, e.message);
      else {
        // Never echo internals: they could contain record content.
        console.error("reparc gateway error", e instanceof Error ? e.name : "unknown");
        response = error(500, "internal gateway error");
      }
    }
    for (const [k, v] of Object.entries(PRIVATE_HEADERS)) response.headers.set(k, v);
    return response;
  }

  private async route(request: Request, path: string): Promise<Response> {
    const m = request.method;
    if (path === "/healthz" && m === "GET") return json(200, { status: this.setupMode ? "setup_required" : "ok", version: VERSION, ...BUILD });
    if (path === "/v1/info" && m === "GET") {
      return json(200, { product: "reparc-gateway", version: VERSION, ...BUILD, mcp_path: "/mcp", mcp_auth: ["oauth", "bearer", "secret_link"], setup_required: this.setupMode });
    }
    if (path.startsWith("/.well-known/") || path.startsWith("/oauth/")) {
      const r = await this.oauthRoute(request, path, m);
      if (r) return r;
    }
    if (path === "/mcp" || path.startsWith("/mcp/")) {
      if (m === "GET" || m === "DELETE") return json(405, { error: "this server does not open event streams; use POST" }, { allow: "POST" });
      if (m !== "POST") return json(405, { error: "use POST" }, { allow: "POST" });
      const linkToken = path.startsWith("/mcp/") ? decodeURIComponent(path.slice("/mcp/".length)) : undefined;
      return this.mcp(request, linkToken ?? bearer(request.headers.get("authorization")));
    }
    if (path.startsWith("/v1/phone/") || path.startsWith("/v1/owner/")) {
      if (this.setupMode) return error(503, "set REPARC_OWNER_KEY (at least 32 characters) and connect an Upstash Redis store in Vercel, then redeploy");
      const denied = await this.checkOwner(request);
      if (denied) return denied;
      if (path === "/v1/phone/poll" && m === "GET") return json(200, { calls: await this.relay.poll(request.signal) });
      if (path === "/v1/phone/results" && m === "POST") {
        const body = (await readJson(request, 2 * 1024 * 1024)) as { results?: unknown };
        await this.relay.answer(body?.results);
        return new Response(null, { status: 204 });
      }
      return this.owner(request, path.slice("/v1/owner/".length), m);
    }
    return error(404, "not found");
  }

  /** Owner key check with a per-address limit on wrong keys. */
  private async checkOwner(request: Request): Promise<Response | undefined> {
    const ip = sha256(this.clientIp(request));
    const minute = Math.floor(Date.now() / 60_000);
    const failKey = `reparc:ownerfail:${ip}:${minute}`;
    if (Number((await this.store.get(failKey)) ?? "0") >= MAX_OWNER_FAILURES_PER_MINUTE) return error(429, "too many wrong keys; wait a minute");
    const token = bearer(request.headers.get("authorization"));
    if (token !== undefined && secretsEqual(token, this.config.ownerKey!)) return undefined;
    await this.store.incr(failKey, 120_000);
    return json(401, { error: "missing or wrong owner key" }, { "www-authenticate": "Bearer" });
  }

  // ---- Owner API ----

  private async apps(): Promise<AppRecord[]> {
    return Object.values(await this.store.hgetall(APPS))
      .map((raw) => JSON.parse(raw) as AppRecord)
      .sort((a, b) => a.created_at_ms - b.created_at_ms);
  }

  private async owner(request: Request, rest: string, m: string): Promise<Response> {
    if (rest === "state" && m === "GET") {
      const requests = await this.oauth.pendingRequests();
      return json(200, {
        phone_online: await this.relay.phoneOnline(),
        apps: (await this.apps()).map(({ key_sha256: _k, oauth_client_id: _o, ...app }) => app),
        requests: requests.map((r) => ({ id: r.id, client_name: r.client_name, match: r.match, return_host: hostOf(r.redirect_uri), created_at_ms: r.created_at_ms })),
        activity: await this.relay.activity(),
      });
    }
    if (rest.startsWith("requests/") && m === "POST") {
      const body = (await readJson(request, 1024)) as { approve?: unknown };
      if (typeof body?.approve !== "boolean") return error(400, "approve must be true or false");
      const ok = await this.oauth.decideAsOwner(decodeURIComponent(rest.slice("requests/".length)), body.approve);
      return ok ? json(200, { ok: true }) : error(404, "this sign-in request has expired");
    }
    if (rest.startsWith("apps/") && m === "DELETE") {
      const id = decodeURIComponent(rest.slice("apps/".length));
      const raw = await this.store.hget(APPS, id);
      if (!raw) return error(404, "no such app");
      const app = JSON.parse(raw) as AppRecord;
      if (app.key_sha256) await this.store.del(appToken(app.key_sha256));
      await this.store.hdel(APPS, id);
      return json(200, { ok: true });
    }
    if (rest === "keys" && m === "POST") {
      const body = (await readJson(request, 1024)) as { name?: unknown };
      if ((await this.apps()).length >= 50) return error(409, "remove an AI app first; at most 50 are allowed");
      const key = newToken("rmk");
      const record: AppRecord = { id: newId("app"), name: cleanName(body?.name), kind: "key", key_sha256: sha256(key), created_at_ms: Date.now() };
      await this.store.set(appToken(record.key_sha256!), record.id);
      await this.store.hset(APPS, record.id, JSON.stringify(record));
      return json(201, { id: record.id, key });
    }
    return error(404, "not found");
  }

  // ---- OAuth ----

  private async oauthRoute(request: Request, path: string, m: string): Promise<Response | undefined> {
    const base = this.baseUrl(request);
    if (m === "OPTIONS") return this.oauth.preflight();
    if (m === "GET" && (path === "/.well-known/oauth-protected-resource" || path === "/.well-known/oauth-protected-resource/mcp")) return this.oauth.protectedResource(base);
    if (m === "GET" && (path === "/.well-known/oauth-authorization-server" || path === "/.well-known/openid-configuration")) return this.oauth.authorizationServer(base);
    if (path === "/oauth/register" && m === "POST") return this.oauth.register(request);
    if (path === "/oauth/authorize" && m === "GET") return this.oauth.authorize(request, base);
    if (path === "/oauth/token" && m === "POST") return this.oauth.token(request);
    if (path === "/oauth/revoke" && m === "POST") return this.oauth.revoke(request);
    if (path.startsWith("/oauth/requests/")) {
      const id = decodeURIComponent(path.slice("/oauth/requests/".length));
      if (m === "GET") return this.oauth.requestStatus(id);
      if (m === "POST") return this.oauth.decideInBrowser(request, id);
    }
    return undefined;
  }

  // ---- MCP ----

  /** The AI app a credential belongs to, checked on every request so revoking works at once. */
  private async mcpApp(token: string | undefined): Promise<AppRecord | undefined> {
    if (token === undefined || token === "" || token.length > 200) return undefined;
    const id = token.startsWith("rat_") ? await this.oauth.accessTokenApp(token) : token.startsWith("rmk_") ? await this.store.get(appToken(sha256(token))) : undefined;
    if (!id) return undefined;
    const raw = await this.store.hget(APPS, id);
    if (!raw) return undefined;
    const app = JSON.parse(raw) as AppRecord;
    const now = Date.now();
    if (now - (this.lastUsedWrites.get(id) ?? 0) > LAST_USED_WRITE_MS) {
      this.lastUsedWrites.set(id, now);
      await this.store.hset(APPS, id, JSON.stringify({ ...app, last_used_ms: now }));
    }
    return app;
  }

  private mcpUnauthorized(request: Request, hadToken: boolean) {
    const metadata = `${this.baseUrl(request)}/.well-known/oauth-protected-resource`;
    const challenge = `Bearer resource_metadata="${metadata}", scope="reparc"${hadToken ? ', error="invalid_token"' : ""}`;
    return json(401, {
      error: "unauthorized",
      error_description: "Sign in: add this server by its URL in your AI app and approve it in the Reparc app, or use a key from the Reparc app.",
    }, { "www-authenticate": challenge, "access-control-expose-headers": "www-authenticate" });
  }

  private async mcp(request: Request, token: string | undefined): Promise<Response> {
    // Browsers send Origin; a page on another site must not reach this endpoint (DNS rebinding, CSRF).
    const origin = request.headers.get("origin");
    if (origin !== null && !this.config.allowedOrigins.includes(origin.replace(/\/+$/, ""))) return error(403, "origin not allowed; see REPARC_ALLOWED_ORIGINS");
    if (this.setupMode) return error(503, "this gateway is not set up yet");
    const app = await this.mcpApp(token);
    if (!app) return this.mcpUnauthorized(request, token !== undefined);
    let message: unknown;
    try {
      message = await readJson(request, 256 * 1024);
    } catch {
      return json(400, { jsonrpc: "2.0", id: null, error: { code: -32700, message: "parse error" } });
    }
    const m = (typeof message === "object" && message !== null && !Array.isArray(message) ? message : undefined) as Record<string, unknown> | undefined;
    if (!m) return json(200, rpcError(null, -32600, "expected one JSON-RPC object; batches are not supported"));
    const version = request.headers.get("mcp-protocol-version");
    if (version !== null && m.method !== "initialize" && !SUPPORTED_VERSIONS.includes(version)) return error(400, "unsupported MCP-Protocol-Version");
    if (typeof m.method !== "string" || !("id" in m)) return new Response(null, { status: 202 });
    const id = m.id;
    if (m.jsonrpc !== "2.0") return json(200, rpcError(id, -32600, 'jsonrpc must be "2.0"'));
    const params = (typeof m.params === "object" && m.params !== null ? m.params : {}) as Record<string, unknown>;
    switch (m.method) {
      case "initialize": {
        const requested = params.protocolVersion;
        return json(200, rpcResult(id, {
          protocolVersion: typeof requested === "string" && SUPPORTED_VERSIONS.includes(requested) ? requested : SUPPORTED_VERSIONS[0],
          capabilities: { tools: { listChanged: false } },
          serverInfo: contract.server,
          instructions: contract.instructions,
        }));
      }
      case "ping": return json(200, rpcResult(id, {}));
      case "tools/list": return json(200, rpcResult(id, { tools: LISTED_TOOLS }));
      case "resources/list": return json(200, rpcResult(id, { resources: [] }));
      case "prompts/list": return json(200, rpcResult(id, { prompts: [] }));
      case "tools/call": {
        const name = params.name;
        if (typeof name !== "string" || !TOOL_NAMES.has(name)) return json(200, rpcError(id, -32602, "unknown tool"));
        const args = params.arguments ?? {};
        if (typeof args !== "object" || args === null || Array.isArray(args)) return json(200, rpcError(id, -32602, "arguments must be an object"));
        const minute = `reparc:rate:${app.id}:${Math.floor(Date.now() / 60_000)}`;
        if ((await this.store.incr(minute, 120_000)) > MAX_CALLS_PER_MINUTE) {
          return json(200, rpcResult(id, { content: [{ type: "text", text: "Too many calls this minute. Wait a moment." }], isError: true }));
        }
        // The phone checks the arguments and the owner's data choices itself.
        return json(200, rpcResult(id, await this.relay.call(app.name, name, args)));
      }
      default: return json(200, rpcError(id, -32601, "method not found"));
    }
  }
}

const rpcResult = (id: unknown, result: unknown) => ({ jsonrpc: "2.0", id, result });
const rpcError = (id: unknown, code: number, message: string) => ({ jsonrpc: "2.0", id, error: { code, message } });
