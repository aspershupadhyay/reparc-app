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
