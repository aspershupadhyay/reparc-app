// SPDX-License-Identifier: AGPL-3.0-only
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { Sealer } from "../src/seal.js";
import { OWNER, api, type Harness, start } from "./helpers.js";

let h: Harness;
before(async () => { h = await start(); });
after(async () => { await h.close(); });

test("without an owner key the gateway stays in setup mode", async () => {
  const s = await start({});
  try {
    assert.equal((await api(s.base, "/v1/info", {}, undefined)).body.setup_required, true);
    assert.equal((await api(s.base, "/v1/owner/state")).status, 503);
    assert.equal((await api(s.base, "/mcp", { method: "POST", body: "{}" }, "rmk_x")).status, 503);
    const short = await start({ REPARC_OWNER_KEY: "too-short" });
    assert.equal((await api(short.base, "/v1/owner/state", {}, "too-short")).status, 503);
    await short.close();
  } finally {
    await s.close();
  }
});

test("public endpoints say nothing about the owner", async () => {
  const info = await api(h.base, "/v1/info", {}, undefined);
  assert.equal(info.body.product, "reparc-gateway");
  assert.ok(!("phone_online" in info.body));
  assert.equal(info.headers.get("x-frame-options"), "DENY");
  assert.match(info.headers.get("strict-transport-security") ?? "", /max-age/);
  assert.equal(info.headers.get("x-robots-tag")?.startsWith("noindex"), true);
});

test("wrong owner keys are refused, then the address is locked out for the minute", async () => {
  const s = await start();
  try {
    for (let i = 0; i < 20; i++) assert.equal((await api(s.base, "/v1/owner/state", {}, `rok_wrong${i}`)).status, 401);
    assert.equal((await api(s.base, "/v1/owner/state", {}, "rok_wrong")).status, 429);
    assert.equal((await api(s.base, "/v1/phone/poll", {}, undefined)).status, 429);
  } finally {
    await s.close();
  }
});

test("MCP refuses browsers, batches, bad versions, unknown tools, and huge bodies", async () => {
  const { body } = await api(h.base, "/v1/owner/keys", { method: "POST", body: JSON.stringify({ name: "x" }) });
  const key = body.key;
  const rpc = (msg: unknown, headers: Record<string, string> = {}) => api(h.base, "/mcp", { method: "POST", body: typeof msg === "string" ? msg : JSON.stringify(msg), headers }, key);
  assert.equal((await rpc({ jsonrpc: "2.0", id: 1, method: "tools/list" }, { origin: "https://evil.example" })).status, 403);
  assert.equal((await rpc([{ jsonrpc: "2.0", id: 1, method: "tools/list" }])).body.error.code, -32600);
  assert.equal((await rpc({ jsonrpc: "2.0", id: 1, method: "tools/list" }, { "mcp-protocol-version": "1999-01-01" })).status, 400);
  assert.equal((await rpc({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "exec", arguments: {} } })).body.error.code, -32602);
  assert.equal((await rpc("x".repeat(300 * 1024))).status, 400);
  assert.equal((await rpc("{bad")).body.error.code, -32700);
  assert.equal((await api(h.base, "/mcp", { method: "GET" }, key)).status, 405);
  assert.equal((await api(h.base, "/mcp", { method: "POST", body: "{}" }, `${key}x`)).status, 401);
});

test("sealed relay values cannot be read with another key or moved to another slot", () => {
  const a = new Sealer(OWNER);
  const sealed = a.seal('{"meal":"oats"}', "result:c_1");
  assert.ok(!sealed.includes("oats"));
  assert.equal(a.open(sealed, "result:c_1"), '{"meal":"oats"}');
  assert.equal(a.open(sealed, "result:c_2"), undefined);
  assert.equal(new Sealer(`${OWNER}x`).open(sealed, "result:c_1"), undefined);
  const tampered = sealed.slice(0, -2) + (sealed.endsWith("A") ? "BB" : "AA");
  assert.equal(a.open(tampered, "result:c_1"), undefined);
});

test("the phone can only answer calls with well-formed IDs", async () => {
  const r = await api(h.base, "/v1/phone/results", { method: "POST", body: JSON.stringify({ results: [{ id: "../../x", result: {} }, { id: "c_zz", result: {} }] }) });
  assert.equal(r.status, 204);
  assert.ok(!h.store.dump().includes("reparc:result:../../x"));
});
