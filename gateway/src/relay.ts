// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 the Reparc contributors
// Moves one tool call at a time from an AI app to the owner's phone and the
// answer back. Calls and answers are sealed (seal.ts) and expire within a
// minute. The gateway has no copy of the owner's records: it can only ask the
// phone, and the phone decides what to answer.

import { newId } from "./secret.js";
import type { Sealer } from "./seal.js";
import type { Store } from "./store.js";

export interface RelayTiming {
  /** How often a waiting phone poll checks the queue (each check is one Redis command). */
  pollIntervalMs: number;
  /** How long one phone poll waits before it answers with no calls. */
  pollWaitMs: number;
  /** How often a waiting tool call checks for the phone's answer. */
  resultIntervalMs: number;
  /** How long a tool call waits for the phone. */
  callTimeoutMs: number;
}

export interface QueuedCall {
  id: string;
  client: string;
  tool: string;
  arguments: unknown;
  at_ms: number;
}

export interface ToolResult {
  content: { type: "text"; text: string }[];
  structuredContent?: unknown;
  isError: boolean;
}

const K = {
  queue: "reparc:queue",
  seen: "reparc:phone:seen",
  result: (id: string) => `reparc:result:${id}`,
  activity: "reparc:activity",
};

/** A phone that has not polled for this long is offline. */
export const PHONE_STALE_MS = 40_000;
const QUEUE_TTL_MS = 60_000;
const MAX_RESULT_BYTES = 512 * 1024;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export const errorResult = (message: string): ToolResult => ({
  content: [{ type: "text", text: message }],
  structuredContent: { error: message },
  isError: true,
});

export class Relay {
  constructor(private readonly store: Store, private readonly sealer: Sealer, private readonly timing: RelayTiming) {}

  async phoneOnline(now = Date.now()): Promise<boolean> {
    const seen = Number((await this.store.get(K.seen)) ?? "0");
    return now - seen < PHONE_STALE_MS;
  }

  /** Sends one call to the phone and waits for its answer. */
  async call(client: string, tool: string, args: unknown): Promise<ToolResult> {
    if (!(await this.phoneOnline())) {
      await this.log(client, tool, "phone_offline");
      return errorResult(
        "The owner's phone is not connected right now. Ask the owner to open Reparc → Me → AI connections and switch on online access, then try again.",
      );
    }
    const id = newId("c");
    const call: QueuedCall = { id, client, tool, arguments: args ?? {}, at_ms: Date.now() };
    await this.store.lpush(K.queue, this.sealer.seal(JSON.stringify(call), "call"), QUEUE_TTL_MS);
    const until = Date.now() + this.timing.callTimeoutMs;
    while (Date.now() < until) {
      const sealed = await this.store.getdel(K.result(id));
      if (sealed) {
        const plain = this.sealer.open(sealed, `result:${id}`);
        const result = plain ? parseResult(plain) : undefined;
        await this.log(client, tool, result && !result.isError ? "ok" : "error");
        return result ?? errorResult("The phone sent an answer the gateway could not read.");
      }
      await sleep(this.timing.resultIntervalMs);
    }
    await this.log(client, tool, "timeout");
    return errorResult("The phone did not answer in time. Ask the owner to keep Reparc open, then try again.");
  }

  /** Phone side: waits for calls. Marks the phone as online while it polls. */
  async poll(signal?: AbortSignal): Promise<QueuedCall[]> {
    const until = Date.now() + this.timing.pollWaitMs;
    // Once per poll: a poll lasts at most pollWaitMs, well under PHONE_STALE_MS.
    await this.store.set(K.seen, String(Date.now()), { px: PHONE_STALE_MS * 2 });
    for (;;) {
      const calls: QueuedCall[] = [];
      for (let i = 0; i < 5; i++) {
        const sealed = await this.store.rpop(K.queue);
        if (!sealed) break;
        const plain = this.sealer.open(sealed, "call");
        if (!plain) continue;
        const call = JSON.parse(plain) as QueuedCall;
        // A call older than the AI app waits for is useless to answer.
        if (Date.now() - call.at_ms < this.timing.callTimeoutMs) calls.push(call);
      }
      if (calls.length > 0 || Date.now() >= until || signal?.aborted) return calls;
      await sleep(this.timing.pollIntervalMs);
    }
  }

  /** Phone side: stores answers for the waiting tool calls. */
  async answer(results: unknown): Promise<number> {
    if (!Array.isArray(results)) return 0;
    let stored = 0;
    for (const r of results.slice(0, 10)) {
      if (typeof r !== "object" || r === null) continue;
      const { id, result } = r as { id?: unknown; result?: unknown };
      if (typeof id !== "string" || !/^c_[0-9a-f]{16}$/.test(id)) continue;
      const text = JSON.stringify(result ?? null);
      if (text.length > MAX_RESULT_BYTES) continue;
      await this.store.set(K.result(id), this.sealer.seal(text, `result:${id}`), { px: QUEUE_TTL_MS });
      stored++;
    }
    return stored;
  }

  /** Who called which tool, when, and how it ended. Never arguments or answers. */
  private async log(client: string, tool: string, outcome: string) {
    await this.store.lpush(K.activity, JSON.stringify({ at_ms: Date.now(), client, tool, outcome }), 7 * 24 * 3600_000);
    await this.store.ltrim(K.activity, 0, 49);
  }

  async activity(): Promise<unknown[]> {
    return (await this.store.lrange(K.activity, 0, 49)).map((s) => JSON.parse(s) as unknown);
  }
}

/** Accepts only the CallToolResult shape; anything else becomes an error result. */
function parseResult(text: string): ToolResult | undefined {
  try {
    const r = JSON.parse(text) as Partial<ToolResult> | null;
    if (!r || !Array.isArray(r.content)) return undefined;
    const content = r.content
      .filter((c): c is { type: "text"; text: string } => typeof c === "object" && c !== null && c.type === "text" && typeof c.text === "string")
      .slice(0, 5);
    return { content, structuredContent: r.structuredContent, isError: r.isError === true };
  } catch {
    return undefined;
  }
}
