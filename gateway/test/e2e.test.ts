// SPDX-License-Identifier: AGPL-3.0-only
// End to end: the official MCP TypeScript SDK client → gateway → fake phone.
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { api, fakePhone, type Harness, start } from "./helpers.js";

let h: Harness;
before(async () => { h = await start(); });
after(async () => { await h.close(); });

async function connect(url: string, token?: string) {
  const client = new Client({ name: "Test client", version: "1.0.0" });
  const transport = new StreamableHTTPClientTransport(new URL(url), token ? { requestInit: { headers: { authorization: `Bearer ${token}` } } } : undefined);
  await client.connect(transport);
  return client;
}

test("an app key reaches the phone through MCP and the queue holds only ciphertext", async () => {
  const { status, body } = await api(h.base, "/v1/owner/keys", { method: "POST", body: JSON.stringify({ name: "Codex" }) });
  assert.equal(status, 201);
  const key = body.key as string;
  assert.match(key, /^rmk_[0-9a-f]{64}$/);

  const marker = "SECRET-MEAL-NAME-7731";
  const phone = fakePhone(h.base, (tool, args) => {
    return { content: [{ type: "text", text: `${marker} ${tool}` }], structuredContent: { tool, args }, isError: false };
  });
  const client = await connect(`${h.base}/mcp`, key);
  try {
    const tools = await client.listTools();
    assert.equal(tools.tools.length, 12);
    assert.ok(tools.tools.every((t) => !("scope" in t)));
    const instructions = client.getInstructions() ?? "";
    assert.match(instructions, /Nothing is saved until the owner approves/);

    const result = await client.callTool({ name: "list_meals", arguments: { from: "2026-03-01", to: "2026-03-02" } });
    assert.equal(result.isError, false);
    assert.match((result.content as any[])[0].text, new RegExp(marker));
    assert.deepEqual(phone.seen.at(-1)?.client, "Codex");
    assert.deepEqual(phone.seen.at(-1)?.args, { from: "2026-03-01", to: "2026-03-02" });
    assert.ok(!h.store.dump().includes(marker), "answers must not stay in the store");

    const unknown = await client.callTool({ name: "drop_everything", arguments: {} }).catch((e: Error) => e);
    assert.ok(unknown instanceof Error);
  } finally {
    phone.stop();
    await client.close();
  }
});

test("the secret-link form works, and revoking an app cuts it off at once", async () => {
  const { body } = await api(h.base, "/v1/owner/keys", { method: "POST", body: JSON.stringify({ name: "Cursor" }) });
  const phone = fakePhone(h.base);
  const client = await connect(`${h.base}/mcp/${body.key}`);
  try {
    const r = await client.callTool({ name: "get_overview", arguments: {} });
    assert.equal(r.isError, false);
  } finally {
    phone.stop();
    await client.close();
  }
  const state = await api(h.base, "/v1/owner/state");
  const app = state.body.apps.find((a: any) => a.name === "Cursor");
  assert.ok(app && !("key_sha256" in app));
  assert.equal((await api(h.base, `/v1/owner/apps/${app.id}`, { method: "DELETE" })).status, 200);
  const again = await api(h.base, "/mcp", { method: "POST", body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/list" }) }, body.key);
  assert.equal(again.status, 401);
  assert.match(again.headers.get("www-authenticate") ?? "", /resource_metadata=/);
});

test("with no phone polling, a tool call returns a clear error instead of hanging", async () => {
  const fresh = await start();
  try {
    const { body } = await api(fresh.base, "/v1/owner/keys", { method: "POST", body: JSON.stringify({ name: "Claude" }) });
    const client = await connect(`${fresh.base}/mcp`, body.key);
    const r = await client.callTool({ name: "get_overview", arguments: {} });
    assert.equal(r.isError, true);
    assert.match((r.content as any[])[0].text, /phone is not connected/);
    const activity = (await api(fresh.base, "/v1/owner/state")).body.activity;
    assert.equal(activity[0].outcome, "phone_offline");
    assert.ok(!("arguments" in activity[0]));
    await client.close();
  } finally {
    await fresh.close();
  }
});

test("while a call waits for the phone, Redis holds only the sealed call", async () => {
  const fresh = await start();
  try {
    const { body } = await api(fresh.base, "/v1/owner/keys", { method: "POST", body: JSON.stringify({ name: "Claude" }) });
    // One poll marks the phone online; nobody answers after that.
    await api(fresh.base, "/v1/phone/poll");
    const marker = "PRIVATE-FOOD-NOTE-5521";
    const waiting = api(fresh.base, "/mcp", { method: "POST", body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "get_exercise_history", arguments: { exercise: marker } } }) }, body.key);
    await new Promise((r) => setTimeout(r, 200));
    const dump = fresh.store.dump();
    assert.ok(dump.includes("reparc:queue"), "the call should be queued");
    assert.ok(!dump.includes(marker), "the queued call must be sealed");
    assert.ok(!dump.includes("get_exercise_history"), "even the tool name is sealed");
    const r = await waiting;
    assert.match(r.body.result.content[0].text, /did not answer in time/);
  } finally {
    await fresh.close();
  }
});
