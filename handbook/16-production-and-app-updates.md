---
title: Production readiness and app updates
status: proposed
owner: engineering-and-release
updated: 2026-10-05
---

# Section 17: Production readiness and app updates

## 17.1 Purpose

Build the app with production controls from the first commit. A private test build can have limited features. It must use the same safe data rules, architecture, and release controls as the public app.

The product owner wants users to know when an update is available. GitHub is the source and release automation platform. GitHub does not install a new app build on a user's phone.

## 17.2 Update rule

The app must not download or run executable code from GitHub. It must not replace its installed binary outside the platform's approved install flow.

Use this release path:

1. A contributor opens a reviewed pull request.
2. Required checks pass.
3. A release owner creates a protected version tag.
4. CI builds and signs the release artifact.
5. The release owner submits that artifact to the platform's private test track.
6. Test and store review gates pass.
7. The release owner publishes the approved version in stages.
8. The app shows users the published update and its release notes.

A push to a branch does not notify users. A GitHub release does not mean that a store has approved or published the app.

**Built (2026-10-06):** `.github/workflows/release.yml` runs on a `v*` tag that matches `app/pubspec.yaml`. It builds a release APK (signed with the upload key when the `ANDROID_KEYSTORE_*` secrets exist, otherwise a debug key) and an iPhone IPA that Apple has not signed (ad-hoc signed with its entitlements, for sideloading with the user's own Apple ID). It publishes both with SHA-256 checksums as a GitHub pre-release. These are test builds for people who install them on purpose. The app never downloads or installs them. App Store, TestFlight, and Google Play delivery still need the owner's developer accounts.

Apple does not allow an app to download or install code that changes app functionality. Use the App Store for the standard public iPhone release. Use TestFlight for beta distribution. Apple also documents alternative iOS distribution in some regions. Treat that as a separate launch decision. Confirm its eligibility, legal terms, and install flow before planning it. See [Apple App Review Guidelines, 2.5.2](https://developer.apple.com/app-store/review/guidelines/) and [TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).

For Google Play installs, use Google Play's in-app update API. The user and Play control the install flow. Use a flexible update for a normal release. Use an immediate update only when the release owner has a documented critical reason. See [Google Play in-app updates](https://developer.android.com/guide/playcore/in-app-updates) and [Google Play app updates](https://support.google.com/googleplay/android-developer/answer/9859350?hl=en).

An Android app installed from a downloaded APK does not qualify for Google Play in-app updates. Do not make APK self-install a default feature. If the project later supports direct Android distribution, define signature verification, user consent, update hosting, rollback, and support as a separate decision.

## 17.3 Update experience

Put update controls in **Me → Settings → App updates**.

Show:

- Installed version and build number.
- Latest store version when known.
- Last check time.
- Release notes for the available version.
- A **Check for updates** action.
- A link to the store page when the store flow is not available.
- A clear result when the app is current or the check fails.

Check for update metadata at launch, when the app returns to the foreground, and when the user asks. Cache results. Add a delay between checks. Do not block app start if the network or metadata service fails.

**Built for the GitHub test builds (D-029, 2026-10-06):** the metadata source is the GitHub "latest release" API for `aspershupadhyay/reparc`. `app/lib/updates/` reads the tag, notes, and download links (data only), compares the version with the installed one, and saves the result on the phone. It checks once a day when the app opens (the user can turn this off) and when the user taps **Check for updates**. Home shows a notice that the user can hide until the next version. **Download and install** opens the APK (Android) or the release page (iPhone) in the browser. The phone's installer does the install and asks the user. The first line of `release-notes/<version>.md` is the notice text. Store builds will use the store flows below instead.

For store builds, the metadata source, hosting, schema, and backend are **To confirm**. It may be a small public release manifest, but it must contain data only, such as version, notes, minimum supported version, and store links. Validate its signature or integrity where the chosen hosting supports it. The app must not execute content from the manifest. If metadata is unavailable, use the platform store as the source of truth.

Use an in-app notice by default. Offer push update notices only as an opt-in. Request notification permission when the user turns the option on. If permission is denied, keep the in-app notice and manual check available. Send a notice only after the version is available through the relevant store or beta channel.

Do not interrupt a live workout or meal entry. Show a notice that can wait until the user finishes. Do not start an install without the platform's user-facing flow. Save active workout state before opening a store update flow. If safe recovery is not confirmed, defer the update until the session ends.

For a standard iPhone release, open the App Store page. The user starts the install there. App Store automatic updates are controlled by the user and iOS. Alternative iOS distribution is **To confirm** and needs its own design and policy review.

On Android installed from Google Play, start the Play in-app update flow after the user selects **Update**. For a flexible update, show download progress and ask the user to restart when the update is ready. If the user cancels or the store is unavailable, leave the app usable and allow a later retry.

## 17.4 Production engineering from the first commit

Use these controls from the first repository commit:

- Protect the main branch and require reviewed pull requests before public release. During early development, the owner chose direct pushes to `main` with CI on every push.
- Pin Flutter, Dart, and package versions. Commit the dependency lock file.
- Run formatting, static analysis, unit tests, and relevant integration tests in CI.
- Check dependencies, licenses, secrets, and known security advisories.
- Keep development, test, and production configuration separate.
- Keep signing keys and service credentials in protected CI secrets.
- Use synthetic records in CI. Never use real user records in test fixtures.
- Build optimized iOS and Android artifacts for release checks.
- Record the source commit, dependency lock, version, and artifact checksum for each release.
- Keep a software bill of materials or equivalent dependency inventory for each public release.
- Review database migrations and upgrade behavior before release.
- Define crash reporting and service monitoring only after their data collection and retention are approved.

The team must set measurable startup, logging-response, memory, and download-size targets after measuring named baseline devices. Do not promise performance before those checks pass.

## 17.5 Release pipeline

### Pull request workflow

1. Run formatter checks.
2. Run static analysis and type checks.
3. Run unit and widget tests.
4. Run integration tests for changed data paths.
5. Run dependency, license, and secret checks.
6. Build unsigned or test-signed app artifacts.
7. Keep the pull request blocked when a required check fails.

### Release workflow

1. Require a reviewed release request and protected version tag.
2. Re-run all required checks on the tagged commit.
3. Build signed artifacts in protected CI.
4. Create release notes from reviewed changes.
5. Record checksums and build provenance.
6. Submit the same artifact to the internal store track.
7. Test install, upgrade, restore, and data migration.
8. Promote the same artifact after approval. Do not rebuild between test and production promotion unless the platform requires a new artifact.
9. Start a staged rollout where the store supports it.
10. Watch crash reports, update failures, support reports, and data-loss signals.
11. Stop rollout when a release gate fails.

CI provider, signing setup, store credentials, crash reporting provider, and monitoring provider are **To confirm**. Choose them after access control, retention, cost, and team ownership are clear.

## 17.6 Failure and recovery

Test these update cases:

- The app is current.
- The metadata check times out or returns invalid data.
- The store is unavailable.
- The user declines or cancels an update.
- A download pauses or fails.
- The user opens the app before a flexible update restarts.
- The installed version is below the minimum supported version.
- The update follows every supported database version.
- The app is closed during an active workout.
- Notifications are denied or disabled.
- The user revokes notification permission.

Do not promise that a store can downgrade an installed release. If a release has a serious fault, stop its rollout and prepare a corrected forward release. Use remote configuration only for reviewed settings or feature flags. Never use it to deliver executable code.

Keep local workout and meal records intact through an app update. Test upgrades from every supported database version. Back up or preserve records before a migration. Stop the migration safely if validation fails. Explain recovery steps without exposing private data.

## 17.7 Ownership and gates

Before public release, name an owner for:

- Store submissions and signing.
- Update metadata and release notes.
- CI and build failures.
- Security reports and incident response.
- User support and update issues.
- Data migrations and recovery.

The release owner must confirm the current Apple and Google requirements before each submission. Store requirements and APIs can change.

## 17.9 Private source, public builds

**Status:** Set up 2026-10-08 at the owner's request. The owner made this repository private. The license question below is **To confirm**.

- **Source:** `aspershupadhyay/reparc` stays private.
- **Builds:** a public repository, `aspershupadhyay/reparc-releases`, holds only a README and GitHub Releases (APK, IPA, `SHA256SUMS.txt`). The release workflow publishes there. The app's update check (D-029) and the website read from there, because a private repository's releases are not visible without a sign-in.
- **Website:** Vercel, project root `site/` (`site/vercel.json`). GitHub Pages for a private repository needs a paid GitHub plan, so `pages.yml` was removed.
- **Gateway:** unchanged. It already deploys to Vercel from this repository.

**Owner steps (one time):**

1. Create the public repository `reparc-releases` on GitHub, with a README. The text is in `release-notes/RELEASES-REPO-README.md`.
2. Create a fine-grained personal access token: repository access **only** `reparc-releases`, permission **Contents: Read and write**. Add it to this repository as the Actions secret `RELEASES_TOKEN`.
3. In Vercel, import this repository as a new project, set **Root Directory** to `site`, and deploy. Add a domain if wanted, then update the website link in `README.md`.
4. Push a version tag (for example `v0.4.0`) to publish the first public build.

**Limits.** Anyone can still unpack an APK or IPA and read the compiled code; private source makes copying harder, not impossible. Code that was public under AGPL-3.0 stays available under AGPL-3.0 to anyone who copied it.

**To confirm (owner):** the license for new versions. The app still ships under AGPL-3.0 (12.2), which lets anyone who gets the app ask for its source. Keeping the source private for new releases needs a different license for them, for example "all rights reserved". The owner is the only human author in the history, so the owner can choose this.

## AI context

- **Purpose:** Direct engineering agents to build and update the app safely.
- **Rule:** GitHub changes pass review and CI before a release is built.
- **Rule:** Never download or run executable app code from GitHub.
- **Rule:** Use App Store updates on iPhone and Google Play updates for Play installs.
- **Rule:** Keep user approval in the platform install flow.
- **Rule:** Do not interrupt a live workout to install an update.
- **Rule:** Update notes and diagrams when release behavior changes.
- **Rule:** Mark unselected providers and hosting as **To confirm**.
- **Rule:** A planned release flow is not a deployed release pipeline.
