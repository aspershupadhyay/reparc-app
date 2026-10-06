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
| `lib/data/` | Drift database, repositories, export and delete, providers |
| `lib/domain/` | Pure calculations: nutrition totals and targets, strength, roadmaps, meal plans, progress, records |
| `lib/mcp/` | Read-only AI tools over an export file, and the MCP protocol handler |
| `tool/mcp/server.dart` | Local MCP server (stdio). See [tool/mcp/README.md](tool/mcp/README.md) |
| `tool/food_library/` | Builds the bundled USDA food list |
| `lib/features/` | The five tabs: `home`, `workout`, `meal`, `analytics`, `me` |
| `lib/app/` | App widget and routes |

## Data rules in code

- Every write goes to the local database first. There is no network code.
- A missing value is stored as `null`. It is never stored or shown as zero.
- Units, timestamps, UTC offsets, and sources are stored with each record.
- The database schema version is in `lib/data/database.dart`. A schema change needs a migration and a migration test.

## Release signing

Android release signing reads `android/key.properties`, which is git-ignored. Never commit keys.
