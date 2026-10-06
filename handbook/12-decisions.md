---
title: Decision record
status: active-plan
owner: maintainers
updated: 2026-10-05
---

# Decision record

Keep major choices here. Update the related chapter when a decision changes.

## D-001: Flutter is the mobile baseline

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Plan the iPhone and Android app with Flutter and Dart.

**Reason:** The product needs custom screens, shared motion, and local-first logging.

**Risk:** Release size, team experience, and plugin behavior need proof.

**Proof needed:** Release size and performance on real devices. Test health access before including it.

## D-002: One visual system

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Use both supplied images as layout references. Use one theme, Manrope, and reviewed Lucide icons.

**Reason:** The references have different palettes. Separate palettes may make one app feel like two products.

**Proof needed:** Contrast and user review on a prototype.

## D-003: Local save before sync

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Save core records locally before optional network sync.

**Reason:** Gym logging must work without a reliable network.

**Risk:** Phone-only data can be lost with the device.

## D-004: Analytics have two meanings

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Keep user progress separate from company product-use measurement.

**Reason:** They use different data and need different privacy controls.

## D-005: Health access is optional

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Ask for the smallest permission when a user selects a feature that needs it.

**Reason:** Manual logging must continue when a user declines.

## D-006: MCP starts read-only

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Let the first MCP version read only the data categories the user approves.

**Reason:** Narrow read access is easier to explain and review.

**Risk:** A remote AI receives records needed for a request.

## D-007: Cloud services are not part of the local-only release

**Status:** Proposed.  
**Date:** 2026-10-05.

**Choice:** Do not add a backend until the product owner approves sync or remote MCP.

**Reason:** Local-only use reduces service and data-exposure work.

**Risk:** A user may lose data with a lost phone. The app must explain export and backup limits.

## Open decisions

- First user group and launch countries.
- Trademark, domain, and app-store clearance for the chosen working name Reparc.
- Account, sync, MCP, and BYOK release timing.
- Database encryption and account recovery.
- Backend and identity provider.
- Food data source and license.
- Minimum operating-system versions.
- Final application ID and bundle ID.
- Whether Android and iOS system backups include the local database.
- Numeric app-size and performance targets.
- Support owner and security contact.

## AI context

- **Purpose:** Preserve the reason and evidence for major choices.
- **Rule:** Proposed does not mean final.
- **Rule:** Revisit choices when evidence changes.
- **Rule:** Update this log and the related handbook section together.


## D-008: Five main tabs and reference image roles

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Use Home, Workout, Meal, Analytics, and Me. Put exercise library, plans, workout history, and logging in Workout. Put account and AI/MCP controls in Me. Use the first supplied image as the Meal layout reference and the second as the Workout layout reference.

**Reason:** This matches the user's requested navigation and makes the two core logging jobs directly available.

**Rule:** Keep one shared design system. Do not copy reference image sample content or identity.

## D-009: Local-first private beta

**Status:** Proposed.
**Date:** 2026-10-05.

**Choice:** Start without mandatory sign-in or a backend. Save core records locally. Add sync and remote MCP only after a separate data-flow and security review.

**Reason:** Sign-in alone does not back up app data. A remote AI service cannot fetch phone-only records without a network data path.

**Risk:** Users can lose phone-only records if they lose or erase the device. Provide export and clear warnings.

**Proof needed:** User research, local migration and recovery tests, export review, privacy threat model, and decision on cloud backup.


## D-010: Include optional HealthKit and Health Connect support

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Plan HealthKit for iPhone and Health Connect for Android. Request the smallest data access needed for a named feature. Explain each data type before the operating-system permission request.

**Reason:** The user asked for health-platform access and clear permission requests.

**Release gate:** Complete a native device prototype, choose one Flutter package, confirm supported data types, review current store rules, and test grant, refusal, revocation, and unavailable states.

**Privacy rule:** A user can refuse a permission and keep using manual workout and meal logging.


## D-011: Production controls start with the first commit

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Build the intended customer app with production architecture, data safety, tests, CI, accessibility, and release controls from the start. Internal user and platform checks are required release gates. Do not ship a disposable prototype as the production app.

**Reason:** The user asked for a production-ready app and a planned execution path.

**Boundary:** Production quality does not mean that every planned feature must ship at once. Sync, HealthKit, Health Connect, AI, and MCP still need their own approval and release gates.


## D-012: Use platform-managed app updates

**Status:** Accepted for the user need; distribution details are platform-specific.
**Date:** 2026-10-05.

**Choice:** Show update status and release notes in Me → Settings → App updates. Let GitHub source changes enter a reviewed release pipeline. Use the App Store for standard public iPhone releases and Google Play for Play installs on Android. Treat other distribution channels as separate decisions.

**Reason:** Public iOS apps cannot install a changed binary from GitHub. Google Play provides an in-app update flow for apps installed from Play.

**Rule:** Never execute downloaded code or install an app binary directly from GitHub. Android direct APK distribution is a separate **To confirm** decision.

**Sources:** [Apple App Review Guidelines, 2.5.2](https://developer.apple.com/app-store/review/guidelines/); [Google Play in-app updates](https://developer.android.com/guide/playcore/in-app-updates).


## D-013: Reparc is the chosen working name

**Status:** Accepted as a working name.
**Date:** 2026-10-05.

**Choice:** Use Reparc as the project and repository name while work starts.

**Reason:** The user selected Reparc to move into project setup.

**Open check:** Existing companies use Reparc, including an active UK IT consultancy. The name is not proven unique or legally clear. Check trademarks, app listings, domains, and launch regions before public product branding.


## D-014: License the project under GNU AGPL v3.0

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Use GNU Affero General Public License version 3.0 only (SPDX: AGPL-3.0-only).

**Reason:** The user selected AGPL 3.0 for the public project.

**Rule:** Keep the license text in the repository root. Review third-party assets and dependencies separately. Do not imply that app data or third-party assets use this license.


## D-015: Light and dark themes, no purple

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Replace the lavender accent. Ship light and dark modes with one token set. Follow the meal reference closely for the Meal tab.

**Reason:** The owner found the first palette off from the references and asked for both modes without purple.

**Supersedes:** The palette part of D-002. One design system and one font remain.

## D-016: Built-in coached exercise catalog with a body model

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Ship a built-in catalog grouped by body area. Each exercise has original coaching text (setup, steps, breathing, cues, mistakes, easier and harder options, dose, tempo) and an animated 3D body model with muscle highlights and joint-angle labels.

**Rule:** The text is original to this project and uses the project license. It is general technique coaching for healthy adults, not medical advice. The model is a procedural drawing, not footage of a person. Do not copy third-party exercise text, images, or video.

**To confirm:** Review of the coaching text by a qualified strength coach before public release.

## D-017: Bundled public-domain exercise photo library

**Status:** Accepted by the user.
**Date:** 2026-10-05.

**Choice:** Bundle Free Exercise DB (873 exercises with a start and an end photo, steps, muscles, and equipment) in the app. Show the two photos as a slow cross-fade loop. Use the library photos on the coached guides in place of the body model.

**Rule:** Use only media with a license that allows redistribution in this open-source repository. Free Exercise DB uses the Unlicense (public domain), pinned to one commit in `app/tool/exercise_library/build.py`. Keep a credit line on the detail screen and the license file in `app/assets/licenses/`. Do not bundle media whose license excludes images, forbids redistribution, or is unclear. This replaces the "do not copy third-party images" part of D-016 for this library only. Coached text stays original.

**Why:** The owner chose an existing open dataset over custom animation. Checked alternatives: ExerciseDB-style GIF packs exclude the media from their open license or forbid redistribution; Mixamo forbids sharing raw files.

**Trade-off:** About 26 MB of photos in the app. The photos show two positions, not full motion.


## D-018: AI access through MCP, on Wi-Fi or through the owner's own gateway

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Reparc exposes one MCP tool set (`app/assets/mcp/tools.json`) two ways. Both are off by default and turn off by themselves after 15 minutes to 2 hours.

1. **On this Wi-Fi:** the app runs an MCP server (Streamable HTTP, JSON responses) on the phone for AI apps on the same local network. It needs a 256-bit access key, accepts only private network addresses and no browser `Origin`, and blocks an address after 10 wrong keys.
2. **Online:** a gateway in `gateway/` that each user deploys into their own Vercel account with one click (Upstash Redis for short-lived state). AI apps sign in with OAuth 2.1 and PKCE; the owner approves each one in the app by matching a 4-letter code. The phone long-polls the gateway over HTTPS with the owner key and answers each tool call from local data. The gateway keeps no records. Calls and answers wait in Redis for at most 60 seconds, sealed with AES-256-GCM under a key derived from the owner key.

**Why:** The owner asked for AI access to their own data without a shared server, so each user owns their data and gateway. A phone-local server cannot be reached by cloud AI apps; a relay through the owner's own gateway can, without copying records to a server.

**Trade-off:** Wi-Fi mode is plain HTTP inside the local network; the app says to use it only on trusted Wi-Fi. Online mode needs Reparc open while the AI works, because iPhone apps cannot keep a connection in the background. The AI provider receives the answers it asks for. No independent security audit has been done.

**Proof:** `app/test/ai_tools_test.dart`, `app/test/ai_transport_test.dart`, and `gateway/test/` (OAuth, revocation, sealing, rate limits, origin checks, and an end-to-end test with the official MCP SDK client).

## D-019: AI changes arrive as proposals

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** AI apps may propose workout plans and meal plans (`propose_workout_plan`, `propose_meal_plan`). A proposal is stored apart from records (`ai_proposals`, schema v3) and changes nothing. Only the user's tap on **Approve** saves it. AI meals are saved as planned entries marked as estimates, with the AI app named as the source. At most 20 proposals can wait. There are no AI tools to edit or delete records.

**Why:** The owner wants the AI to craft exercises and plan meals. AGENTS.md and section 10.7 forbid AI changes without approval.

## D-020: Health data types and write-back

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Use the `health` package (13.3.2) for HealthKit and Health Connect. Each data type is a separate switch in **Me → Health apps**, explained before the system sheet opens: read steps, active energy, and body weight; write finished workouts and eaten meals. Health values are read when needed and not copied into the database. Writes happen once per record (`health_writes`), only for records saved after the switch was turned on. Heart rate, sleep, location, and clinical records are not requested. Android minimum is API 26.

**Why:** The owner asked for Apple Health and Health Connect, used wisely. Workout read from Health Connect was left out because the plugin also needs distance, total calories, and steps permissions for it.

**Trade-off:** Edits after a write are not sent; the user edits the copy in the Health app.

## D-021: Backup through the user's own Apple or Google account

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** No Reparc account or server. Two layers:

1. The phone's own backup: iCloud Backup includes the database; Android backup to Google Drive includes it (secure-storage values are excluded, because their Keystore keys cannot move).
2. An encrypted backup file (Argon2id, 19 MiB, 2 passes; AES-256-GCM) that the user saves to iCloud Drive, Google Drive, or anywhere, and restores on any iPhone or Android phone. Restore replaces all records in one transaction. AI and health switches are not restored.

**Why:** The owner asked for "save to my drive, like iCloud or WhatsApp". This keeps data in the user's own account with no new identity system.

**Trade-off:** No live two-way sync between devices yet. A forgotten passphrase cannot be recovered. Automatic file backup to Google Drive or iCloud Drive would need the owner's Google Cloud OAuth client and Apple iCloud container; it is not built.

## D-022: App icon and animated start

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** The Reparc mark is drawn by one painter (`lib/core/brand.dart`); D-028 replaced the first gauge design with the joint "R". The same painter renders the app icons (`tool/icons/`). On start, an animated intro builds the mark (letter, ripples, leg swing, particle burst, wordmark): 2.2 s on the first start, 1 s later, a still frame with reduced motion. A tap skips it.

**Why:** Owner request. It does not delay data entry, and it respects reduced motion (section 3.11).

## D-023: iOS-native look on iPhone and Android

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Make the app look and feel like a native iPhone app on both platforms. Use iOS system colours (grouped grey background, white cards, black in dark mode, system green, blue, orange, and red), a teal tint, and lime for training energy. Use SF Pro on iPhone and Inter on Android (Inter is an open font with the same proportions). Use an iOS tab bar, iOS segmented controls, iOS switches, iOS alerts for confirmations, swipe-back page transitions, bounce scrolling, and no ripple effects.

**Supersedes:** The palette in D-015, the Manrope font in D-002, and the lime pill on the tab bar. One design system and one token set remain. No purple.

**License:** Inter uses the SIL Open Font License 1.1. The bundled file is a Latin subset. The license is in `app/assets/fonts/Inter-OFL.txt`. SF Pro is not bundled; iPhone supplies it.

## D-024: Browse exercises by body area, then muscle

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Workout → Exercises shows seven body areas. Each area splits into muscles (for example, Arms → Biceps, Triceps, Forearms). Each muscle shows a short "Start here" list of hand-picked moves that cover different equipment, then the rest. Stretches and power moves are in their own tabs. Each area and muscle has a drawn body icon that colours only that part.

**Reason:** The full list of about 870 exercises was too much to choose from.

## D-025: Training roadmaps

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Offer five roadmaps (Aesthetic, Bodybuilding, Strength, Calisthenics, Lean & fit) at three levels, for 2–6 days a week, in a full gym, with dumbbells, or at home. Every day starts with a warm-up and ramp-up sets. The user owns the plan and can change any day, exercise, set, rep, rest, or reps-in-reserve value, and hide warm-up, cool-down, or tips.

**To confirm:** Review of the roadmaps by a qualified strength coach before public release.

## D-026: Nutrition targets, fibre, and a USDA food list

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** Record fibre, sugar, and sodium with each food. Offer daily targets from the user's profile, off by default: energy (Mifflin-St Jeor × activity), protein by goal (1.6–2.0 g/kg, +0.2 g/kg for vegans, user can set 1.2–2.4), fibre (14 g per 1,000 kcal), fat (about 25% of energy), carbs (the rest), and limits for sugar (10% of energy) and sodium (2,000 mg). Bundle 84 common foods from USDA FoodData Central SR Legacy (public domain, CC0) and a day planner for mixed, vegetarian + egg, vegetarian, and vegan diets.

**Closes:** The open decision "Food data source and license" for the bundled list. A barcode or online food search is still **To confirm**.

## D-027: MCP-ready data through a user-made file

**Status:** Accepted by the user for the local, file-based route.
**Date:** 2026-10-06.

**Choice:** Provide read-only MCP tools over a Reparc export file, and a small local MCP server (`app/tool/mcp/server.dart`, stdio only). The user picks Workouts, Meals, and Body data separately before export. AI-written roadmaps and meal plans come back through Me → AI connections → Share a file or import a plan, with a preview and approval. Imported foods are marked as estimates.

**Boundary:** The phone opens no port and sends nothing in the background. A remote MCP service and live sync stay **To confirm** (D-006, D-009).

## D-028: The joint "R" mark, in teal and lime

**Status:** Accepted by the user.
**Date:** 2026-10-06.

**Choice:** The Reparc mark is a white "R" whose leg swings from a joint through a dotted arc, the range of motion of one rep (`lib/core/brand.dart`). The joint and leg use the teal-to-lime gradient. App icons, splash, intro, website, and gateway pages use it. The palette stays teal and lime (D-023): the owner tried an ember (orange) accent in v0.3.1 and asked for teal and green back.

**Supersedes:** The gauge mark in D-022.

## D-029: Update alerts for GitHub test builds

**Status:** Accepted by the user (owner, 2026-10-06).
**Date:** 2026-10-06.

**Choice:** Until the app is in the App Store and Google Play, Reparc checks the GitHub "latest release" for a newer build: once a day when the app opens (on by default, the user can turn it off) and when the user taps **Check for updates**. Home shows a notice. **Download and install** opens the APK (Android) or the release page (iPhone) in the browser; the phone's own installer asks the user to confirm. The app never downloads or runs code by itself.

**Privacy:** A check sends one HTTPS request to GitHub with no records, account, or device data. GitHub sees the IP address. The App updates screen says so.

**Supersedes:** The AGENTS.md rule that the app must not use GitHub for updates, for the pre-store period only.
