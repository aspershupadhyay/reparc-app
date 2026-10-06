import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:sqlite3/sqlite3.dart' as sql;

/// Upgrades a database written by schema v1 (handbook 7.5).
void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('reparc-mig'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('v1 to v2 keeps every record and adds the new columns', () async {
    final file = File('${dir.path}/v1.sqlite');
    final raw = sql.sqlite3.open(file.path);
    for (final stmt in File('test/fixtures/schema_v1.sql').readAsStringSync().split(';\n')) {
      if (stmt.trim().isNotEmpty) raw.execute(stmt.endsWith(';') ? stmt : '$stmt;');
    }
    const t = '2026-03-02T08:00:00.000Z';
    raw.execute("INSERT INTO exercises (id, created_at, updated_at, name) VALUES ('e1', '$t', '$t', 'Squat')");
    raw.execute(
      'INSERT INTO meal_slots (id, created_at, updated_at, name, position, usual_minute) VALUES '
      "('slot-breakfast', '$t', '$t', 'Breakfast', 0, 480), ('own', '$t', '$t', 'Pre-workout', 4, NULL)",
    );
    raw.execute('PRAGMA user_version = 1');
    raw.close();

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase(file));
    final ex = await db.select(db.exercises).getSingle();
    expect(ex.name, 'Squat');
    expect(ex.catalogId, isNull);
    final slots = {for (final s in await db.select(db.mealSlots).get()) s.id: s};
    expect(slots['slot-breakfast']!.kind, 'breakfast');
    expect(slots['own']!.kind, isNull);
    expect(slots['own']!.name, 'Pre-workout');
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.data.values.first, 3);
    await db.close();
  });

  test('v2 to v3 keeps every record and adds nutrients, roadmaps, and weights', () async {
    final file = File('${dir.path}/v2.sqlite');
    final raw = sql.sqlite3.open(file.path);
    for (final stmt in File('test/fixtures/schema_v2.sql').readAsStringSync().split(';\n')) {
      if (stmt.trim().isNotEmpty) raw.execute(stmt.endsWith(';') ? stmt : '$stmt;');
    }
    const t = '2026-03-02T08:00:00.000Z';
    raw.execute(
      'INSERT INTO meal_slots (id, created_at, updated_at, name, position, usual_minute, kind) VALUES '
      "('slot-lunch', '$t', '$t', 'Lunch', 1, 780, 'lunch')",
    );
    raw.execute(
      'INSERT INTO meal_entries (id, created_at, updated_at, day, slot_id, name, protein_g, amount, amount_unit, '
      "source, status, time_zone_name) VALUES ('m1', '$t', '$t', '2026-03-02', 'slot-lunch', 'Rice', 2.7, 1, "
      "'serving', 'Manual entry', 'eaten', 'UTC')",
    );
    raw.execute(
      'INSERT INTO workout_sessions (id, created_at, updated_at, name, status, started_at, utc_offset_minutes, '
      "time_zone_name) VALUES ('s1', '$t', '$t', 'Legs', 'finished', '$t', 0, 'UTC')",
    );
    raw.execute('PRAGMA user_version = 2');
    raw.close();

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase(file));
    final m = await db.select(db.mealEntries).getSingle();
    expect(m.proteinG, 2.7);
    expect(m.fiberG, isNull, reason: 'Old entries have no fibre value. Missing is not zero.');
    expect(m.sodiumMg, isNull);
    final s = await db.select(db.workoutSessions).getSingle();
    expect(s.name, 'Legs');
    expect(s.programId, isNull);
    expect(await db.select(db.programs).get(), isEmpty);
    expect(await db.select(db.bodyWeights).get(), isEmpty);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.data.values.first, 3);
    await db.close();
  });
}
