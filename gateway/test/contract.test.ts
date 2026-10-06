// SPDX-License-Identifier: AGPL-3.0-only
import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { contract } from "../src/contract.js";

test("the gateway lists exactly the tools the phone serves", () => {
  const app = JSON.parse(readFileSync(new URL("../../app/assets/mcp/tools.json", import.meta.url), "utf8"));
  assert.deepEqual(JSON.parse(JSON.stringify(contract)), app, "run `npm run sync-contract` after changing app/assets/mcp/tools.json");
  assert.equal(contract.tools.length, 12);
});
