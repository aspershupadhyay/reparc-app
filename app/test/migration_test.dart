import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/domain/roadmap.dart';
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
    expect(v.data.values.first, 5);
    await db.close();
  });

  test('v2 to v3 keeps every record and adds AI proposals and health writes', () async {
    final file = File('${dir.path}/v2.sqlite');
    final raw = sql.sqlite3.open(file.path);
    for (final stmt in File('test/fixtures/schema_v2.sql').readAsStringSync().split(';\n')) {
      if (stmt.trim().isNotEmpty) raw.execute(stmt.endsWith(';') ? stmt : '$stmt;');
    }
    const t = '2026-03-02T08:00:00.000Z';
    raw.execute(
      "INSERT INTO exercises (id, created_at, updated_at, name, catalog_id) VALUES ('e1', '$t', '$t', 'Squat', 'back-squat')",
    );
    raw.execute(
      'INSERT INTO meal_slots (id, created_at, updated_at, name, position, kind) VALUES '
      "('slot-lunch', '$t', '$t', 'Lunch', 1, 'lunch')",
    );
    raw.execute("INSERT INTO settings (key, value) VALUES ('loadUnit', 'lb')");
    raw.execute('PRAGMA user_version = 2');
    raw.close();

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase(file));
    expect((await db.select(db.exercises).getSingle()).catalogId, 'back-squat');
    expect((await db.select(db.mealSlots).getSingle()).kind, 'lunch');
    expect((await db.select(db.settings).getSingle()).value, 'lb');
    expect(await db.select(db.aiProposals).get(), isEmpty);
    expect(await db.select(db.healthWrites).get(), isEmpty);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.data.values.first, 5);
    await db.close();
  });

  test('v3 to v4 keeps every record and adds nutrients, roadmaps, and weights', () async {
    final file = File('${dir.path}/v3.sqlite');
    final raw = sql.sqlite3.open(file.path);
    for (final stmt in File('test/fixtures/schema_v3.sql').readAsStringSync().split(';\n')) {
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
    raw.execute('PRAGMA user_version = 3');
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
    expect(v.data.values.first, 5);
    await db.close();
  });

  test('v4 to v5 copies every old plan into programs and keeps the old tables', () async {
    final file = File('${dir.path}/v4.sqlite');
    final raw = sql.sqlite3.open(file.path);
    for (final stmt in File('test/fixtures/schema_v4.sql').readAsStringSync().split(';\n')) {
      if (stmt.trim().isNotEmpty) raw.execute(stmt.endsWith(';') ? stmt : '$stmt;');
    }
    const t = '2026-03-02T08:00:00.000Z';
    raw.execute(
      'INSERT INTO exercises (id, created_at, updated_at, name, catalog_id) VALUES '
      "('e1', '$t', '$t', 'Back squat', 'back-squat'), ('e2', '$t', '$t', 'My curl', NULL)",
    );
    raw.execute(
      'INSERT INTO workout_templates (id, created_at, updated_at, name, note) VALUES '
      "('t1', '$t', '$t', 'Legs', 'Heavy day'), ('t2', '$t', '$t', 'Empty', NULL)",
    );
    raw.execute(
      'INSERT INTO template_exercises (id, created_at, updated_at, template_id, exercise_id, position, '
      "target_sets, target_reps) VALUES ('i2', '$t', '$t', 't1', 'e2', 1, NULL, NULL), "
      "('i1', '$t', '$t', 't1', 'e1', 0, 3, 5)",
    );
    raw.execute(
      'INSERT INTO workout_sessions (id, created_at, updated_at, template_id, name, status, started_at, '
      "utc_offset_minutes, time_zone_name) VALUES ('s1', '$t', '$t', 't1', 'Legs', 'finished', '$t', 0, 'UTC'), "
      "('s2', '$t', '$t', NULL, 'Workout', 'finished', '$t', 0, 'UTC')",
    );
    raw.execute(
      'INSERT INTO programs (id, created_at, updated_at, name, goal, level, equipment, days_per_week, active, '
      "next_day, plan) VALUES ('p1', '$t', '$t', 'Strength', 'strength', 'beginner', 'fullGym', 2, 1, 1, "
      '\'{"goal":"strength","level":"beginner","setup":"fullGym","days":[{"name":"A","items":[]}]}\')',
    );
    raw.execute('PRAGMA user_version = 4');
    raw.close();

    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase(file));
    final programs = {for (final p in await db.select(db.programs).get()) p.id: p};
    expect(programs.keys, unorderedEquals(['p1', 't1', 't2']));
    expect(programs['p1']!.active, isTrue, reason: 'The followed roadmap stays followed');
    expect(programs['p1']!.nextDay, 1);
    final legs = programs['t1']!;
    expect(legs.name, 'Legs');
    expect(legs.active, isFalse, reason: 'A copied plan is not followed');
    expect(legs.goal, 'custom');
    expect(legs.createdAt, DateTime.parse(t));
    final day = ProgramPlan.decode(legs.plan).days.single;
    expect(day.name, 'Legs');
    expect(day.focus, 'Heavy day');
    expect(day.items.map((i) => i.exerciseId), ['back-squat', 'user:e2'], reason: 'Order follows position');
    expect(day.items.first.sets, 3);
    expect(day.items.first.repsLow, 5);
    expect(day.items.last.sets, 1, reason: 'No target: one set, as before');
    expect(day.items.last.repsLow, isNull, reason: 'A missing target stays missing');
    expect(ProgramPlan.decode(programs['t2']!.plan).days.single.items, isEmpty);
    final sessions = {for (final s in await db.select(db.workoutSessions).get()) s.id: s};
    expect(sessions['s1']!.programId, 't1');
    expect(sessions['s1']!.programDay, 0);
    expect(sessions['s1']!.templateId, 't1');
    expect(sessions['s2']!.programId, isNull);
    // The old rows stay for one release as a safety net.
    expect(await db.select(db.workoutTemplates).get(), hasLength(2));
    expect(await db.select(db.templateExercises).get(), hasLength(2));
    // Running the copy again changes nothing.
    expect(await db.copyLegacyPlans(), 0);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.data.values.first, 5);
    await db.close();
  });
}
