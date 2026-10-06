// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 the Reparc contributors
// Tool calls and answers wait in Redis for a few seconds while they travel
// between an AI app and the phone. They are sealed with AES-256-GCM under a
// key derived from the owner key (which lives only in the Vercel project and
// on the phone), so the Redis provider stores only ciphertext.

import { createCipheriv, createDecipheriv, hkdfSync, randomBytes } from "node:crypto";

export class Sealer {
  private readonly key: Buffer;

  constructor(ownerKey: string) {
    this.key = Buffer.from(hkdfSync("sha256", Buffer.from(ownerKey, "utf8"), Buffer.from("reparc-gateway"), Buffer.from("relay-seal-v1"), 32));
  }

  seal(plain: string, context: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv("aes-256-gcm", this.key, iv);
    // The context binds a sealed value to its slot, so one value cannot be replayed as another.
    cipher.setAAD(Buffer.from(context, "utf8"));
    const body = Buffer.concat([cipher.update(plain, "utf8"), cipher.final()]);
    return Buffer.concat([iv, body, cipher.getAuthTag()]).toString("base64url");
  }

  /** Undefined when the value was changed, sealed for another slot, or sealed with another key. */
  open(sealed: string, context: string): string | undefined {
    try {
      const raw = Buffer.from(sealed, "base64url");
      if (raw.length < 28) return undefined;
      const decipher = createDecipheriv("aes-256-gcm", this.key, raw.subarray(0, 12));
      decipher.setAAD(Buffer.from(context, "utf8"));
      decipher.setAuthTag(raw.subarray(raw.length - 16));
      return Buffer.concat([decipher.update(raw.subarray(12, raw.length - 16)), decipher.final()]).toString("utf8");
    } catch {
      return undefined;
    }
  }
}
