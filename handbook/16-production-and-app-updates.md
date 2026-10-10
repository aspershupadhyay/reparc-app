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

**Built (2026-10-06):** `.github/workflows/release.yml` runs on a `v*` tag that matches `app/pubspec.yaml`. It builds a release APK (signed with the upload key when the `ANDROID_KEYSTORE_*` secrets exist, otherwise a debug key) and an iPhone IPA that Apple has not signed (ad-hoc signed with its entitlements, for sideloading with the user's own Apple ID). It publishes both with SHA-256 checksums as a GitHub pre-release. These are test builds for people who install them on purpose. The app never installs them by itself; see the update flow in 17.3. App Store, TestFlight, and Google Play delivery still need the owner's developer accounts.

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

**Built for the GitHub test builds (D-029, 2026-10-06):** the metadata source is the GitHub "latest release" API for the public builds repository `aspershupadhyay/reparc` (17.9). `app/lib/updates/` reads the tag, notes, and download links (data only), compares the version with the installed one, and saves the result on the phone. It checks once a day when the app opens (the user can turn this off) and when the user taps **Check for updates**. Home shows a notice that the user can hide until the next version. **Download and install** on Android downloads the APK in the app with a progress bar, checks its SHA-256 against `SHA256SUMS.txt`, and opens Android's installer, which asks the user (D-029, updated 2026-10-08). On iPhone it opens the release page. Code: `app/lib/updates/apk_installer.dart` and `MainActivity.kt`; tests: `app/test/apk_installer_test.dart`. The first line of `release-notes/<version>.md` is the notice text. Store builds will use the store flows below instead.

**Download speed (v0.4.14, 2026-10-11, owner report "slow even on 5G"):** an update is a 55–60 MB APK from GitHub's release servers over one connection, which often gives only a few MB/s in India; the app cannot change that. The app's own costs were cut: progress is reported about four times a second instead of for every network chunk (about a thousand screen updates per download), and the SHA-256 check runs on a background isolate after the download instead of on the UI thread during it. Google Play will be faster still: its own servers in India, and updates that send only what changed.

**APK per processor type (v0.4.9, 2026-10-10):** each release has the full `reparc-android.apk` (every phone, about 105 MB) and one APK per processor type: `reparc-android-arm64-v8a.apk`, `-armeabi-v7a.apk`, and `-x86_64.apk` (measured on v0.4.9: full 105.6 MB, arm64-v8a 57.9 MB, armeabi-v7a 55.7 MB, x86_64 59.4 MB). All come from one build with the same version code, so any of them can update any other. From v0.4.9 the app downloads the APK for its own processor type and falls back to the full APK. The full APK is uploaded first, because older app versions take the first `.apk` in the release. The website still links to the full APK. `SHA256SUMS.txt` lists every file.

**Download state and a fresh check (v0.4.10, 2026-10-10):** **Download and install** first asks GitHub for the latest release, so a version published after the last daily check is the one downloaded (before, the app downloaded the version its last check had saved). The download belongs to the app, not to the App updates screen (`apkDownloadProvider`): Back or another tab does not stop it or lose its progress, and a second tap cannot start a second download. When this version's APK is already on the phone and still matches its checksum, **Open installer** opens Android's installer again without a new download.

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

**Actions minutes (2026-10-11, owner request):** the private repository ran out of its monthly GitHub Actions minutes after a day of releases. CI now saves minutes:

- `ci.yml` (format, analyze, test, gateway, website) runs on pull requests that change code, not on handbook, release-note, or Markdown changes, and not again after a merge.
- `android-build.yml` runs only when Android build files change (`app/android/**`, `pubspec`, `distribution.dart`). It still checks that the Play bundle has no installer.
- `ios-build.yml` runs only when iPhone build files change. It runs on a Mac, which GitHub counts at 10 times the minutes.
- Every release (`release.yml`) still builds Android, the Play bundle, and iPhone.
- Any of them can be started by hand (Actions → the workflow → Run workflow).

Never make the repository public to get free minutes: the full history would be copied by bots within minutes, and public forks stay public (17.9). If minutes run out again, raise the Actions spending limit or add a self-hosted runner.

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

**Build speed (2026-10-10):** CI keeps Gradle and its build cache between runs (`setup-java` with `cache: gradle`, and `org.gradle.caching`). The Android and iOS builds run beside the format, analyze, and test job instead of after it. The pull request Android build makes the 64-bit ARM APK only; the release builds every type.

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

**Status:** Set up 2026-10-08 at the owner's request. The license question below is **To confirm**.

| Repository | Visibility | Holds |
|---|---|---|
| `aspershupadhyay/reparc-app` | Private | All source code, the handbook, the gateway, and CI. All development happens here. |
| `aspershupadhyay/reparc` | Public | A README, GitHub Releases (APK, IPA, `SHA256SUMS.txt`), and the website on its `gh-pages` branch. No source code. |

- The release workflow in `reparc-app` builds the app and publishes the release to `reparc` with the `RELEASES_TOKEN` secret. Nobody commits to `reparc` except its README.
- The app's update check (D-029), the Support link, and the website read from `reparc`. Apps already installed (v0.3.x) also check `aspershupadhyay/reparc`, so they find new builds there.
- **Never make `reparc-app` public.** Git history keeps every old file, so a public repository shows all source ever committed, even after files are deleted.
- **Website:** GitHub Pages from the public `reparc` repository, at https://aspershupadhyay.github.io/reparc/. `.github/workflows/site.yml` copies only the static files in `site/` to its `gh-pages` branch, as one commit with no history. Vercel (`site/vercel.json`) is a later option.
- **Gateway:** deploys to Vercel from `reparc-app`, folder `gateway/`.

**Owner steps (one time), in this order:**

1. Rename the current repository `reparc` to `reparc-app` (Settings → General → Repository name). Keep it private.
2. On every computer and session that has a copy, point it at the new name before step 3: `git remote set-url origin https://github.com/aspershupadhyay/reparc-app.git`. GitHub redirects the old name only until a new repository takes it; after that, a push to the old address would go to the public repository.
3. Create the new public repository `reparc` with a README (text: `release-notes/PUBLIC-REPO-README.md`).
4. Create a fine-grained token with access to `reparc` only and **Contents: Read and write**. Save it in `reparc-app` as the Actions secret `RELEASES_TOKEN`.
5. Turn on the website: in the public `reparc` repository, Settings → Pages → Source **Deploy from a branch** → branch **gh-pages**, folder **/ (root)** → Save. Run the **Website** workflow in `reparc-app` once (Actions → Website → Run workflow) to create that branch first. Later: check that the Vercel gateway project points to `reparc-app`.
6. Push a version tag in `reparc-app` (for example `v0.4.0`) to publish the first public build.

**Limits.** Anyone can unpack an APK or IPA and read the compiled code; private source makes copying harder, not impossible. Code that was public under AGPL-3.0 stays available under AGPL-3.0 to anyone who copied it.

**License:** Settled on 2026-10-10 (D-035). From 0.4.11 the app is all rights reserved; the gateway stays AGPL-3.0-only.

## 17.10 Google Play build

**Status:** Build set up 2026-10-10 (D-036). Not uploaded to Play yet. The Play Console steps below are the owner's.

### Two builds, one app

| | GitHub APK | Google Play App Bundle |
|---|---|---|
| Made by | `release.yml`, every `v*` release | `release.yml`, same run, only with the upload key |
| Flag | none | `--dart-define=REPARC_STORE=play` |
| Where | public `reparc` releases | private workflow artifact `play-bundle` (30 days) |
| Updates | in-app check and **Download and install** (D-029) | Google Play |
| `REQUEST_INSTALL_PACKAGES`, update file provider, installer channel | yes | removed |
| Application ID, version code | `app.reparc.reparc`, pubspec build number | the same |

- The switch is one define. Dart reads it in `lib/core/distribution.dart`. Gradle reads the same define and merges `android/app/src/play/AndroidManifest.xml`, which removes the permission and the provider, and sets `BuildConfig.PLAY_BUILD`, which leaves out the installer channel in `MainActivity`.
- In the Play build, Me shows **Version** with "Updates come from Google Play" instead of App updates, Home shows no update banner, and Me → Privacy says updates come from Play.
- CI (`ci.yml`, Android job) builds both on every pull request and checks each merged manifest.
- **Signing:** use Play App Signing. Upload the bundle signed with the existing upload key (`ANDROID_KEYSTORE_*` secrets). Google then signs what users install with its own key. So a phone with the GitHub APK cannot update to the Play version in place: Android sees a different signature. Before switching a phone to the Play version, make a backup file (Me → Backup and restore), uninstall, install from Play, and restore.
- **Version codes:** Play needs a higher version code for each upload. Raise the `+N` in `app/pubspec.yaml` with every release, as now.

### Exact alarms

The app keeps `SCHEDULE_EXACT_ALARM` (decided 2026-10-10). Android's guide says apps that need precisely timed, user-facing actions and are not alarm, timer, or calendar apps should use `SCHEDULE_EXACT_ALARM`, which the user grants in Android settings. `USE_EXACT_ALARM`, which Play restricts, is not used. RepArc uses it only for the rest and set cues of a guided workout on the lock screen. Without it, those cues can come late, and only the start and end cues are set (handbook 4.13). The launch review called this a risk. Check the current Play policy page before the first upload.

### Play Console answers (draft, from the code on 2026-10-10)

Check each answer against the app before submitting. If a data flow changes, update these, `site/privacy.html`, and Me → Privacy together.

**Privacy policy URL:** https://aspershupadhyay.github.io/reparc/privacy.html. The app links to it from Me → Privacy (`privacyPolicyUrl`).

**Data safety:**

- Does the app collect or share user data? **No.** Google's definition counts data sent off the device by the developer. RepArc has no server, no analytics, and no SDK that sends data. Health Connect reads and writes stay on the phone.
- Data sent off the phone only by the user's own action is outside "collection": a backup to their Google account, a file they export, and an AI connection they turn on, which sends answers to the AI app they chose. Describe these in the privacy policy (done).
- Encrypted in transit: the gateway relay uses HTTPS, and messages are sealed with the user's key.
- Users can ask for deletion: data lives only on the phone. Me → Export or delete removes it.

**Health apps declaration and Health Connect permissions:** one reason per permission.

| Permission | Feature | Reason to enter |
|---|---|---|
| `READ_STEPS` | Me → Health apps → Steps | Shows the user's daily steps next to their workouts and meals. |
| `READ_ACTIVE_CALORIES_BURNED` | Active energy | Shows energy burned next to energy eaten. |
| `READ_WEIGHT` | Body weight | Shows body weight in the user's progress charts. |
| `WRITE_EXERCISE` | Save workouts to Health Connect | Saves finished workouts so the user's other health apps see them. |
| `WRITE_NUTRITION` | Save meals to Health Connect | Saves eaten meals so the user's other health apps see them. |

Each is asked for only when the user switches that feature on. Health data is not sent to any server, not used for ads, and not sold.

**Content rating and audience:** fitness, no user-generated content shared with others, no ads, no purchases. Target 18+ (16+ at the youngest), as the launch review proposes. **To confirm (owner).**

### Owner steps before the first upload

1. Pick the developer account type: personal (needs a closed test with 12 testers for 14 days) or organisation (needs a D-U-N-S number). Start the closed test early.
2. Decide the company or legal name and the support email (open since 2026-10-10). Then add the email to the store listing, the privacy policy, and a Help row in Me.
3. Re-make the voice clips on an ElevenLabs plan that allows commercial use, or record new ones. The current clips come from the free plan, which allows non-commercial use only. The owner chose to keep them until then (2026-10-10). **This must be done before a public Play release.**
4. Run a release. Download `play-bundle` from the Release run (Actions → Release → the run → Artifacts) and upload it to the closed-test track.
5. Fill in Data safety, the health apps declaration, the content rating, and the store listing (icon 512 px, feature graphic 1024 × 500, 4–8 phone screenshots, short and full description).

**To confirm:** a qualified coach review of the coaching text and plans (D-016, D-025); TalkBack, large text, and a low-cost phone on a real device.

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
