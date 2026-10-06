---
title: Technology stack and Flutter decision
status: proposed
owner: engineering
updated: 2026-10-05
---

# Section 11: Technology stack and Flutter decision

## 11.1 Decision summary

**Proposed mobile stack:** Flutter and Dart for iPhone and Android.

Use Flutter because the supplied screens need custom layouts and motion. Flutter also gives the team one shared UI system. It is a good fit for this app, but it does not guarantee a small app or fast screens. Measure release builds on real devices.

**Flutter baseline:** Flutter stable 3.47.x, checked on 2026-10-05. The 3.47 release is official. Use the latest approved 3.47 patch available when the project starts. Record the exact Flutter and bundled Dart versions in the repository tool-version file. Do not use an unpinned “latest” SDK in CI.

## 11.2 Proposed mobile tools

| Need | Proposed tool | Reason | Status |
|---|---|---|---|
| Mobile app | Flutter and Dart | One app for iPhone and Android; custom UI | Proposed |
| UI state | flutter_riverpod 3.4.3 | Keeps feature state separate from widgets; supports async states | To confirm in prototype |
| Navigation | go_router 18.0.2 | Flutter-team package; supports nested routes and deep links | To confirm in prototype |
| Local records | Drift 2.35.1 over SQLite | Typed relational data and schema migrations | To confirm encryption and platform fit |
| Secure keys | flutter_secure_storage 11.2.0 | Store tokens and keys in platform secure storage | To confirm upgrade and recovery behavior |
| Health APIs | health_connector 3.11.1 or health 13.3.2 | Candidate packages for HealthKit and Health Connect | To confirm with required data types on real devices |
| Font | SF Pro (iPhone), Inter (Android) | Native iOS feel on both platforms (D-023) | Accepted |
| Icons | Lucide assets | One consistent line-icon set | Proposed |

Package pages checked on 2026-10-05 list these candidates: flutter_riverpod 3.4.3, go_router 18.0.2, drift 2.35.1, flutter_secure_storage 11.2.0, health_connector 3.11.1, and health 13.3.2. These are registry versions, not an endorsement or a dependency lock. Re-check the supported SDK range, transitive dependencies, license, security notices, and maintenance when the prototype is built. Select only one health package if health access is approved. Commit the resolved package lock file.

Both health packages are third-party wrappers. Neither is maintained by Apple or Google. The current health_connector guide lists iOS 15+, Android API 26+, and a FlutterFragmentActivity requirement for its Health Connect flow. It also documents an Android SDK extension requirement for newer Health Connect features. The health package lists iOS 15+ and also documents FlutterFragmentActivity for its Android 14 permission flow. These platform requirements affect app reach and native setup. Health Connect itself is available on Android 9+ with Google Play services. Do not set the app minimum to match a package until the team has picked the package and checked how it behaves on the oldest supported device. In Stage 2, build a small permission and read-only prototype for each candidate, compare data-type coverage and failure handling, and choose one. Do not add either package to the core build before then.

Sources: [Flutter release notes](https://docs.flutter.dev/release/release-notes), [Riverpod](https://pub.dev/packages/flutter_riverpod), [go_router](https://pub.dev/packages/go_router), [Drift](https://pub.dev/packages/drift), [secure storage](https://pub.dev/packages/flutter_secure_storage), [health_connector](https://pub.dev/packages/health_connector), [health](https://pub.dev/packages/health).

## 11.3 Local database and encryption

Use SQLite through Drift for local records if the technical prototype confirms migrations and platform support.

**To confirm:** Whether the local database must use SQLCipher or another encryption layer. Encryption adds key management and recovery work. Do not claim encrypted database storage until the implementation and key handling are reviewed.

Store access tokens and encryption keys outside the database in platform secure storage. The Android plugin docs warn that device backup can restore encrypted preferences without the required key. Define backup exclusions or a tested recovery design. Test app reinstall, device restore, and major upgrades before release.

## 11.4 Network and backend

Do not build a backend for the first local-first release. Workout and meal logging, analytics, export, and deletion can run on the phone. This reduces cost and limits how much personal data the service can expose.

Add a backend only after the product owner approves cloud sync or remote MCP. These features need a data-location plan, access model, backup and deletion rules, monitoring, and support owner. The working backend candidates are Node.js 24 LTS, Fastify 5, PostgreSQL, and the official MCP TypeScript SDK. They are not selected or required for the first release. Use one service first.

A Google or Apple sign-in proves identity. It does not back up the app's records to that provider. Choose account, storage, sync, and backup as separate decisions. A remote MCP service also needs access to the records it answers questions about. If records stay only on the phone, remote MCP cannot read them. Do not imply otherwise in the app.

**Recommendation if sync is approved:** Use Apple and Google for sign-in, then store synced records in the app's own account database. Keep the phone database for offline work. Enforce account separation in the backend. A shared app backend supports both mobile platforms and avoids separate iCloud and Google Drive backup behavior.

**To confirm:** Whether cloud sync or remote MCP is worth the privacy and operations cost. Choose the identity provider, cloud region, database, backup, and retention only after review. Do not use provider sign-in as a storage plan.

## 11.5 Flutter versus Expo with React Native

| Question | Flutter | Expo with React Native |
|---|---|---|
| Main language | Dart | TypeScript and JavaScript |
| Custom visual system | Strong control over shared rendering | Strong capability; uses the React Native UI model |
| Health APIs | Flutter plugins or native platform code | Native libraries and Expo development builds |
| Quick preview | Flutter run and hot reload | Expo development build; Expo Go cannot load every native package |
| Team fit | Best when the team can use Dart | Best when the team already knows React and TypeScript |
| App size | Includes Flutter engine; measure release output | Depends on native modules and assets; measure release output |

Expo SDK 57 targets React Native 0.86 in the version table checked on 2026-10-05. Expo development builds are required for custom native code. Do not use Expo Go as proof that HealthKit or Health Connect works. Sources: [Expo SDK versions](https://docs.expo.dev/versions/latest/), [Expo development builds](https://docs.expo.dev/develop/development-builds/introduction/).

Flutter is the current recommendation because the team can choose its stack and the visual references need custom rendering. If the actual team has strong React Native experience, compare a small prototype before locking the choice.

Flutter's engine adds a baseline to release size. App size also depends on assets and packages. Do not call either framework “bulky” or “light” without release measurements. Source: https://docs.flutter.dev/resources/faq

## 11.6 Performance and version rules

Before the app build, set target devices and numeric limits for startup, set entry, memory, battery, and download size.

- Test release builds, not debug builds.
- Measure a lower-cost supported Android phone and an older supported iPhone.
- Keep packages few and necessary.
- Do not add animation packages for simple transitions.
- Do not add a chart package until the chart needs are defined.
- Upgrade Flutter and packages in a branch.
- Run migration and platform checks before merging an upgrade.

**To confirm:** Minimum supported iOS and Android versions and all numeric performance limits.

## 11.7 App updates

Use GitHub for source, reviews, release tags, and signed release metadata. Do not let the installed app fetch and execute GitHub code or install a new binary itself.

The release pipeline must submit signed app builds to the official stores. The app may fetch release metadata and release notes. It must not fetch executable code or a binary update outside the platform store flow.

- Google Play builds may use Play In-App Updates.
- iPhone builds must link to the App Store for a public release.
- Test builds use Google Play internal testing or Apple TestFlight.
- Direct GitHub APK installation is a separate Android sideload path. Do not advertise it inside the Google Play app.
- iOS users cannot install a public app update from GitHub through the app.

See [Production readiness and app updates](16-production-and-app-updates.md) for release details.

## 11.9 Implementation record

Updated 2026-10-05. The app in `app/` follows the proposed stack. The stack decision stays **Proposed** until device measurements exist.

| Item | Version or value | Note |
|---|---|---|
| Flutter | 3.47.6 stable, Dart 3.13.5 | Pinned in `.tool-versions` and CI |
| flutter_riverpod | 3.4.3 | State and data streams |
| go_router | 18.0.2 | Five-tab `StatefulShellRoute`; live workout is a root route |
| drift, drift_dev | 2.35.1 | Dates stored as ISO 8601 text. Schema version 1 |
| drift_flutter | 0.3.1 | Opens the database file. `sqlite3_flutter_libs` is end-of-life; native SQLite now comes from the `sqlite3` package build hooks |
| lucide_icons_flutter | 3.1.22 | MIT wrapper around the ISC Lucide font. It bundles extra weight fonts. Measure the size cost and replace it with a reviewed subset if needed |
| share_plus | 13.3.1 | User-started export only |
| path_provider | 2.1.6 | Temporary export file |
| package_info_plus | 10.2.2 | Installed version in App updates |
| uuid, intl | 4.6.0, 0.20.3 | Record IDs; number and date formats |

`flutter_secure_storage` and health packages are not added. No feature needs them yet.

The Android release build has no INTERNET permission. Debug and profile builds keep it for development tools.

**To confirm:** Application ID and bundle ID (`app.reparc.reparc` is a placeholder). Minimum OS versions (the Flutter defaults are in use: iOS 15.0). Android and iOS backup treatment of the database (platform defaults are in use).

## 11.8 AI context

- **Purpose:** Give contributors one clear, maintainable technology plan.
- **Mobile:** Flutter and Dart proposed.
- **State:** Riverpod candidate.
- **Routes:** go_router candidate.
- **Local data:** Drift and SQLite candidate.
- **Keys:** Platform secure storage candidate.
- **Health:** Evaluate health_connector 3.11.1 or health 13.3.2. Select one only after platform tests.
- **Backend:** None for local-only first release; Node.js, TypeScript, Fastify, PostgreSQL, and MCP SDK if sync or remote MCP is approved.
- **Rule:** Package versions are dated candidates, not permanent promises.
- **Do not:** Add packages without a need or claim speed without measurement.
