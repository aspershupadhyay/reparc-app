// SPDX-License-Identifier: AGPL-3.0-only
// OAuth 2.1: register, consent page, owner approval in the app, PKCE token exchange.
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { api, type Harness, start } from "./helpers.js";

let h: Harness;
before(async () => { h = await start(); });
after(async () => { await h.close(); });

const verifier = randomBytes(32).toString("base64url");
const challenge = createHash("sha256").update(verifier).digest("base64url");
const REDIRECT = "http://127.0.0.1:33418/callback";

async function register() {
  const r = await api(h.base, "/oauth/register", { method: "POST", body: JSON.stringify({ client_name: "Claude", redirect_uris: [REDIRECT] }) }, undefined);
  assert.equal(r.status, 201);
  return r.body.client_id as string;
}

async function authorize(clientId: string, extra = "") {
  const url = `${h.base}/oauth/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(REDIRECT)}&code_challenge=${challenge}&code_challenge_method=S256&state=xyz${extra}`;
  return fetch(url, { redirect: "manual" });
}

test("discovery documents point at this gateway", async () => {
  const pr = await api(h.base, "/.well-known/oauth-protected-resource", {}, undefined);
  assert.equal(pr.body.resource, `${h.base}/mcp`);
  const as = await api(h.base, "/.well-known/oauth-authorization-server", {}, undefined);
  assert.deepEqual(as.body.code_challenge_methods_supported, ["S256"]);
});

test("full sign-in: the owner approves in the app, then PKCE yields working tokens", async () => {
  const clientId = await register();
  const page = await authorize(clientId);
  assert.equal(page.status, 200);
  const html = await page.text();
  assert.match(html, /Claude wants to read your Reparc data/);
  assert.doesNotMatch(html, /rok_/);
  assert.match(page.headers.get("content-security-policy") ?? "", /frame-ancestors 'none'/);

  const state = await api(h.base, "/v1/owner/state");
  const req = state.body.requests[0];
  assert.equal(req.client_name, "Claude");
  assert.match(req.match, /^[A-Z2-9]{4}$/);
  assert.ok(html.includes(`<span>${req.match[0]}</span>`));
  assert.equal(req.return_host, "127.0.0.1:33418");

  assert.equal((await api(h.base, `/v1/owner/requests/${req.id}`, { method: "POST", body: JSON.stringify({ approve: true }) })).status, 200);
  const status = await api(h.base, `/oauth/requests/${req.id}`, {}, undefined);
  assert.equal(status.body.status, "approved");
  const code = new URL(status.body.redirect).searchParams.get("code")!;
  assert.equal(new URL(status.body.redirect).searchParams.get("state"), "xyz");

  const bad = await fetch(`${h.base}/oauth/token`, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ grant_type: "authorization_code", code, client_id: clientId, code_verifier: "x".repeat(43) }) });
  assert.equal(bad.status, 400);
  // The failed attempt used the code up; get a fresh one.
  await authorize(clientId);
  const req2 = (await api(h.base, "/v1/owner/state")).body.requests[0];
  await api(h.base, `/v1/owner/requests/${req2.id}`, { method: "POST", body: JSON.stringify({ approve: true }) });
  const code2 = new URL((await api(h.base, `/oauth/requests/${req2.id}`, {}, undefined)).body.redirect).searchParams.get("code")!;
  const tok = await fetch(`${h.base}/oauth/token`, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ grant_type: "authorization_code", code: code2, client_id: clientId, redirect_uri: REDIRECT, code_verifier: verifier }) });
  assert.equal(tok.status, 200);
  const t = await tok.json() as any;
  assert.match(t.access_token, /^rat_/);

  const list = await api(h.base, "/mcp", { method: "POST", body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list" }) }, t.access_token);
  assert.equal(list.status, 200);
  assert.equal(list.body.result.tools.length, 12);

  // Refresh tokens rotate.
  const refresh = async (rt: string) => fetch(`${h.base}/oauth/token`, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: new URLSearchParams({ grant_type: "refresh_token", refresh_token: rt, client_id: clientId }) });
  const r1 = await refresh(t.refresh_token);
  assert.equal(r1.status, 200);
  assert.equal((await refresh(t.refresh_token)).status, 400);

  // Revoking the app in Reparc stops its tokens.
  const apps = (await api(h.base, "/v1/owner/state")).body.apps;
  for (const a of apps.filter((x: any) => x.kind === "oauth")) await api(h.base, `/v1/owner/apps/${a.id}`, { method: "DELETE" });
  assert.equal((await api(h.base, "/mcp", { method: "POST", body: JSON.stringify({ jsonrpc: "2.0", id: 2, method: "tools/list" }) }, t.access_token)).status, 401);
});

test("denying in the browser returns access_denied; bad requests are not redirected", async () => {
  const clientId = await register();
  await authorize(clientId);
  const req = (await api(h.base, "/v1/owner/state")).body.requests.at(-1);
  const deny = await fetch(`${h.base}/oauth/requests/${req.id}`, { method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" }, body: "decision=deny", redirect: "manual" });
  assert.equal(deny.status, 303);
  assert.match(deny.headers.get("location") ?? "", /error=access_denied/);

  const evil = await fetch(`${h.base}/oauth/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent("https://evil.example/cb")}&code_challenge=${challenge}&code_challenge_method=S256`, { redirect: "manual" });
  assert.equal(evil.status, 400);
  const plain = await fetch(`${h.base}/oauth/authorize?response_type=code&client_id=${clientId}&redirect_uri=${encodeURIComponent(REDIRECT)}&code_challenge=${challenge}&code_challenge_method=plain`, { redirect: "manual" });
  assert.equal(plain.status, 302);
  assert.match(plain.headers.get("location") ?? "", /error=invalid_request/);
  const reg = await api(h.base, "/oauth/register", { method: "POST", body: JSON.stringify({ redirect_uris: ["javascript:alert(1)"] }) }, undefined);
  assert.equal(reg.status, 400);
});
