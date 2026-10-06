# Reparc app

Flutter app for iPhone and Android. Read the [handbook](../handbook/README.md) before you change code.

## Toolchain

- Flutter 3.47.6 stable, with Dart 3.13.5. The version is pinned in [`.tool-versions`](../.tool-versions) and in CI.
- Packages are locked in `pubspec.lock`. Use `flutter pub get --enforce-lockfile`.

## Run

```sh
cd app
flutter pub get --enforce-lockfile
flutter run
```

## Checks

Run these before you open a pull request. CI runs the same checks. Do not format generated `*.g.dart` files by hand.

```sh
find lib test -name '*.dart' ! -name '*.g.dart' -print0 | xargs -0 dart format --output=none --set-exit-if-changed
dart run build_runner build --delete-conflicting-outputs   # after a schema change
flutter analyze --fatal-infos
flutter test
```

Tests use synthetic records and an in-memory database. Never add real user records to tests.

## Layout

| Path | Purpose |
|---|---|
| `lib/core/` | Design tokens, theme, motion, formatting, shared widgets |
| `lib/data/` | Drift database, repositories, export, delete, encrypted backup and restore, providers |
| `lib/ai/` | MCP tools, Wi-Fi MCP server, gateway relay client, plan proposals (handbook 10, D-018, D-019) |
| `lib/health/` | Apple Health and Health Connect access and write-back (handbook 9, D-020) |
| `lib/domain/` | Pure calculations: nutrition totals, session time, progress, records |
| `lib/features/` | The five tabs: `home`, `workout`, `meal`, `analytics`, `me`, plus the animated `intro` |
| `assets/mcp/tools.json` | The MCP tool contract, shared with `gateway/` |
| `tool/icons/` | Renders app icons and splash images from `lib/core/brand.dart` |
| `lib/app/` | App widget and routes |

## Data rules in code

- Every write goes to the local database first. Network code exists only for AI connections, which the user turns on (`lib/ai/`).
- AI tools never change records. They create proposals that the user approves.
- Secrets (Wi-Fi key, owner key) live in secure storage, never in the database or exports.
- A missing value is stored as `null`. It is never stored or shown as zero.
- Units, timestamps, UTC offsets, and sources are stored with each record.
- The database schema version is in `lib/data/database.dart`. A schema change needs a migration and a migration test.

## Release signing

Android release signing reads `android/key.properties`, which is git-ignored. Never commit keys.
