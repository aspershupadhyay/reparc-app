# Reparc

**Train. Eat. Own your data.** A free, open-source gym and meal log for iPhone and Android. Your records live on your phone. There is no Reparc account and no Reparc server.

🌐 **Website:** on Vercel from `site/` (address To confirm) · ⬇️ **Download:** [latest release](https://github.com/aspershupadhyay/reparc-releases/releases/latest)

> This repository is private. Builds are published in the public [reparc-releases](https://github.com/aspershupadhyay/reparc-releases) repository (handbook 17.9).

> Beta. The core was tested on a real Android phone. AI connections, health access, and backup have passed automated tests only. Reports are welcome in [issues](https://github.com/aspershupadhyay/reparc-releases/issues).

## What it does

- **Workout:** plans, live set logging (sets, reps, load, rest timer, supersets), history, and personal records. 36 coached guides with a 3D body model and 873 public-domain exercises with photos.
- **Meal:** plan the day, then mark what you ate. Missing values stay missing; they are never shown as zero.
- **Analytics:** training heatmap, volume, muscles by body area, best lifts, and macros, each linked to the records behind it.
- **Apple Health and Health Connect:** one switch per data type. Read steps, active energy, and weight; write finished workouts and eaten meals.
- **Backup:** iCloud or Google backup, plus encrypted backup files (Argon2id and AES-256-GCM) you can restore on any phone.
- **AI connections over MCP:** let Claude, ChatGPT, Codex, Cursor, or another MCP app read the data you choose and send workout and meal plans. **Nothing is saved until you tap Approve.**

## Connect an AI

In the app, open **Me → AI connections**. Choose what the AI may use, then pick one way in. Both turn off by themselves after the time you choose.

| Way | Works with | How |
|---|---|---|
| **On this Wi-Fi** | AI apps on a computer on the same network (Claude Code, Codex, Cursor, VS Code, Claude Desktop) | Turn it on; copy the address and key into your AI app. Plain HTTP inside your network, so use trusted Wi-Fi. |
| **Online, your own gateway** | Any remote-MCP app, including claude.ai and ChatGPT | Deploy [`gateway/`](gateway/README.md) to **your own** Vercel account in one click, paste its address into the app, and approve each AI app by matching a code. |

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https%3A%2F%2Fgithub.com%2Faspershupadhyay%2Freparc&root-directory=gateway&project-name=reparc-gateway&repository-name=reparc-gateway&env=REPARC_OWNER_KEY&envDescription=Paste+the+owner+key+from+the+Reparc+app.+It+stays+in+your+Vercel+project+and+on+your+phone.&envLink=https%3A%2F%2Fgithub.com%2Faspershupadhyay%2Freparc%2Fblob%2Fmain%2Fgateway%2FREADME.md&stores=%5B%7B%22type%22%3A%22integration%22%2C%22integrationSlug%22%3A%22upstash%22%2C%22productSlug%22%3A%22upstash-kv%22%2C%22protocol%22%3A%22storage%22%7D%5D)

Start the setup in the app first (Me → AI connections → Set up my gateway), so it can make your owner key. The gateway keeps no records; read its [security model](gateway/README.md#security-model).

## Install

- **Android (8+):** download `reparc-android.apk` from the [latest release](https://github.com/aspershupadhyay/reparc-releases/releases/latest) on your phone and open it.
- **iPhone (iOS 15+):** Reparc is not on the App Store yet. Download `reparc-ios-unsigned.ipa` and install it with AltStore or Sideloadly using your own Apple ID.

Check downloads against `SHA256SUMS.txt`. The app never installs updates itself.

## Repository

| Path | What |
|---|---|
| [`app/`](app/README.md) | Flutter app for iPhone and Android |
| [`gateway/`](gateway/README.md) | Your own MCP gateway for Vercel |
| [`site/`](site/) | Website (GitHub Pages) |
| [`handbook/`](handbook/README.md) | Product and architecture plan, decision record |

**Name status:** Reparc is the chosen working name. Trademark, domain, and app-store name clearance are still pending.

**License:** GNU Affero General Public License v3.0 (AGPL-3.0-only). See [LICENSE](LICENSE).
