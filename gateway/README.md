# Reparc gateway

Your own MCP server on Vercel. It lets an AI app (Claude, ChatGPT, Codex, Cursor, and others) ask the Reparc app on **your** phone about **your** workouts and meals, and send plans for you to approve.

It is for one person: you. You deploy it into your own free Vercel account. Nobody else runs it, and only you hold its key.

```text
 Your AI app  ──HTTPS──▶  Your gateway (Vercel)  ◀──HTTPS──  Reparc on your phone
 (claude.ai,             holds each question a few          answers from local data,
  ChatGPT, …)            seconds, sealed with your key      only what you switched on
```

## Set it up (about 5 minutes)

Start in the app, so it can make your owner key first.

1. In Reparc, open **Me → AI connections → Set up my gateway**. Tap **Copy owner key**.
2. Tap **Open Vercel** (or use the button below on a computer). On Vercel:
   1. Sign in. The free **Hobby** plan is enough.
   2. Keep the new repository **private**.
   3. **Upstash Redis:** add it. Plan **Free**. Pick the region nearest to Vercel's default function region (`us-east-1` for `iad1`).
   4. **REPARC_OWNER_KEY:** paste the owner key.
   5. Press **Deploy**.
3. Copy your new address (`reparc-gateway-….vercel.app`) into Reparc and tap **Connect this phone**.
4. In Reparc, choose what the AI may use (Workouts, Meals, Health data, Plan suggestions) and tap **Turn on** under *Online*.
5. In your AI app, add a custom connector or remote MCP server with the address `https://<your-address>/mcp`. A browser page shows a 4-letter code. Check that Reparc shows the same code, then tap **Approve**.

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Faspershupadhyay%2Freparc&root-directory=gateway&project-name=reparc-gateway&repository-name=reparc-gateway&env=REPARC_OWNER_KEY&envDescription=Paste+the+owner+key+from+the+Reparc+app.+It+stays+in+your+Vercel+project+and+on+your+phone.&envLink=https%3A%2F%2Fgithub.com%2Faspershupadhyay%2Freparc%2Fblob%2Fmain%2Fgateway%2FREADME.md&stores=%5B%7B%22type%22%3A%22integration%22%2C%22integrationSlug%22%3A%22upstash%22%2C%22productSlug%22%3A%22upstash-kv%22%2C%22protocol%22%3A%22storage%22%7D%5D)

**AI app has no sign-in option?** In Reparc, **Create a key** under *AI apps with access*. Give the app the address plus the header `Authorization: Bearer <key>`, or the secret link `https://<your-address>/mcp/<key>` for apps that take only a URL. Treat the secret link like a password.

**Keep Reparc open while the AI works.** The phone answers only while online access is on. The access turns off by itself after the time you chose (15 minutes to 2 hours). If the phone is not connected, the AI gets a clear "phone is not connected" answer.

## What the AI can do

The tools are listed in [`app/assets/mcp/tools.json`](../app/assets/mcp/tools.json). The gateway and the app read the same list.

- Read: overview, workouts, exercise history, personal records, plans, meals, nutrition totals, and health summary.
- Search the built-in exercise library.
- **Propose** workout plans and meal plans. A proposal changes nothing. You review it in Reparc and tap **Approve** or **Decline**.

The AI cannot change or delete a record.

## Security model

What protects your data, and what does not. Read it before you deploy.

**Who can reach your records**
- The gateway has no copy of your records. It can only forward a question to the phone. The phone checks the question against its own rules and your switches, then answers.
- An AI app needs a credential you approved: an OAuth token (after you approved the matching code on the phone) or a key you made in the app. Removing the app in Reparc cuts its access at once.
- Your phone authenticates with the owner key. The owner key exists in two places only: your Vercel project settings and your phone's secure storage (Keychain or Android Keystore).

**In transit and at rest**
- AI app ↔ gateway and phone ↔ gateway use HTTPS (Vercel's TLS) with HSTS.
- While a question or answer waits in Upstash Redis, it is sealed with AES-256-GCM. The key is derived from your owner key (HKDF-SHA256), so Upstash stores only ciphertext. Each sealed value is bound to its slot, so it cannot be replayed as another. Values expire within 60 seconds.
- The gateway does keep metadata: approved app names, token hashes (SHA-256, never the tokens), and the last 50 calls as *app, tool name, time, outcome*. No arguments or answers are logged.

**Attack protections**
- OAuth 2.1 with PKCE (S256 only), exact redirect matching, single-use codes, one-hour access tokens, rotating refresh tokens, and the owner's approval on the phone with a matching code. The gateway never asks for the owner key in a browser. A page that does is phishing.
- Browser requests to `/mcp` are refused unless their origin is listed in `REPARC_ALLOWED_ORIGINS` (blocks cross-site requests and DNS rebinding).
- Rate limits: 20 wrong owner keys per minute per address, 60 tool calls per minute per app, 20 client registrations per minute, 5 sign-in requests waiting at once. Request bodies are size-limited.
- Strict security headers on every answer, including `X-Frame-Options: DENY`, `noindex`, and a strict Content-Security-Policy on pages.

**What it cannot protect**
- The AI provider receives the answers its app asks for. That is the point of the connection. Share only the categories you are comfortable sending to that provider.
- Anyone with your Vercel or Upstash account access, or your owner key, controls the gateway. Use strong passwords and two-factor sign-in for both.
- If you think your owner key leaked: set a new `REPARC_OWNER_KEY` in Vercel → *Settings → Environment Variables*, redeploy, then in Reparc tap **Forget this gateway** and connect again with the new key.

These protections are tested in `test/` (OAuth flow, revocation, sealing, rate limits, origin checks). They have not had an independent security audit.

## Settings

| Variable | Required | Meaning |
|---|---|---|
| `REPARC_OWNER_KEY` | yes | Owner key from the app, at least 32 characters. Without it the gateway stays in setup mode. |
| `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` (or `KV_REST_API_*`) | yes | Set by the Upstash integration. |
| `REPARC_PUBLIC_URL` | no | Your address, if you add a custom domain. |
| `REPARC_ALLOWED_ORIGINS` | no | Comma-separated browser origins allowed to call `/mcp`, for example an MCP inspector. |
| `REPARC_POLL_INTERVAL_MS` | no | How often a waiting phone checks for questions. Default 700. |

**Free-plan budget:** while online access is on, the phone's long poll uses about 5,000 Upstash commands per hour. Upstash's free plan allows about 100 hours of online access per month. Short access windows keep you well inside it.

## Develop

```sh
cd gateway
npm ci
npm run typecheck
npm test                      # OAuth, relay, security, and an end-to-end test with the official MCP SDK
REPARC_OWNER_KEY=$(openssl rand -hex 32) npm run dev   # http://127.0.0.1:8788, in-memory store
npm run sync-contract         # after changing app/assets/mcp/tools.json
```

License: AGPL-3.0-only. Parts are adapted from [Latch](https://github.com/aspershupadhyay/latch) (AGPL-3.0-only).
