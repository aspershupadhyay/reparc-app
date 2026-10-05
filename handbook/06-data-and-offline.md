---
title: Data model and offline use
status: proposed
owner: engineering
updated: 2026-10-05
---

# Section 7: Data model and offline use

## 7.1 Purpose
See [Product and data diagrams](13-diagrams.md) for the local-first record flow.



Keep records correct and available when a network is missing. Preserve enough source data to rebuild summaries.

## 7.2 Core records

Use stable IDs for:

- User settings and optional goals.
- Exercise definitions and workout templates.
- Workout sessions.
- Exercise entries within a session.
- Set entries.
- Meal plans and meal slots.
- Meals and food entries.
- Health imports.
- Consent choices.
- Sync state and deletion markers.

A record must keep its creation time, edit time, units, and source where relevant. Keep the timezone used for the user's day view.

## 7.3 Value rules

- Keep zero separate from missing.
- Keep the original unit when converting a value.
- Keep the source of imported data.
- Keep the source serving size and amount eaten as separate values.
- Keep planned data separate from completed data.
- Use a stable ID so retrying sync does not create a duplicate.

## 7.4 Offline use

- Save core records to the local database first.
- Show that the local save finished.
- Queue cloud sync only if the user enabled sync.
- Show a sync error without blocking logging.
- Retry safely.
- Test app closure during a write and during sync.
- Keep an unfinished workout after restart.

## 7.5 Migrations

A migration changes the local data format. Every migration must have:

- A version number.
- A backup or recovery plan.
- A test from the last supported version.
- A failure path that does not erase the only copy.
- A release note when user behavior changes.

Do not downgrade a database unless a tested recovery path exists.

### Schema history

| Version | Change | Test |
|---|---|---|
| 1 | First local schema | — |
| 2 | `exercises.catalog_id` links a built-in exercise. `meal_slots.kind` sets the meal icon and colour. | `app/test/migration_test.dart` upgrades a real v1 file and checks that no record is lost |

## 7.6 Backup, export, and delete

A local database is not a backup. Explain when records exist only on this phone. Define how iOS and Android device backups treat the database and secure keys. Do not restore an encrypted database without its key. Test restore and export before release. Keep a user-controlled export path.

Export must include field names, units, timestamps, source, and missing values. Use a documented format such as JSON or CSV.

Deletion must remove the record from local storage and mark it for cloud deletion when sync is active. Explain backup retention before account deletion.

## 7.6.1 Export format (built)

The app exports one JSON file with `format: "reparc-export"` and `formatVersion: 1`. It contains every table, field names, units, ISO 8601 timestamps, UTC offsets for sessions, sources, and `null` for missing values. Meal entry nutrients are per source serving. `amount` and `amountUnit` are the amount eaten. Change `formatVersion` when fields change.

## 7.7 AI context

- **Purpose:** Keep source records trustworthy and usable offline.
- **Source of truth:** Saved user records, not charts.
- **Write rule:** Local commit first; remote sync second.
- **Conflict rule:** Never discard a change without notice.
- **Export rule:** Include units, time, and source.
- **Export:** JSON format version 1 is built. See 7.6.1.
- **To confirm:** Encryption at rest and OS backup treatment.
