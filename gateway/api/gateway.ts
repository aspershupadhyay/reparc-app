// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 the Reparc contributors
// Vercel Function entry point. vercel.json rewrites /mcp, /healthz, /v1/*,
// /oauth/*, and /.well-known/* here; the page at "/" is static (public/).
import { Gateway, configFromEnv } from "../src/gateway.js";
import { storeFromEnv } from "../src/store.js";

const store = storeFromEnv(process.env);
const gateway = store ? new Gateway(store, configFromEnv(process.env)) : undefined;

async function handle(request: Request): Promise<Response> {
  if (!gateway) {
    return new Response(
      JSON.stringify({ error: "No Redis store is connected. In Vercel: Storage → Upstash Redis → connect it to this project, then redeploy." }),
      { status: 503, headers: { "content-type": "application/json", "cache-control": "no-store" } },
    );
  }
  return gateway.fetch(request);
}

export const GET = handle;
export const POST = handle;
export const DELETE = handle;
export const OPTIONS = handle;
