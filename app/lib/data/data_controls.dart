import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/clock.dart';
import 'database.dart';

/// Export and deletion of all local records (handbook 7.6).
class DataControls {
  DataControls(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  /// Version of the export file layout. Change it when fields change.
  static const exportFormatVersion = 1;

  /// Builds a JSON export of every local record.
  ///
  /// The export keeps field names, units, timestamps, sources, and missing
  /// values. A missing value is written as null, never as zero.
  Future<String> exportJson({required String appVersion}) async {
    Future<List<Map<String, Object?>>> rows(TableInfo<Table, DataClass> t) async {
      final data = await db.select(t).get();
      return [for (final r in data) _jsonSafe(r.toJson(serializer: _IsoSerializer()))];
    }

    final out = <String, Object?>{
      'format': 'reparc-export',
      'formatVersion': exportFormatVersion,
      'schemaVersion': db.schemaVersion,
      'appVersion': appVersion,
      'exportedAt': clock().toUtc().toIso8601String(),
      'notes': [
        'Timestamps are ISO 8601. Values ending in Z are UTC.',
        'Meal entry nutrient values are per source serving. amount and amountUnit are the amount eaten.',
        'null means the value was not recorded. It does not mean zero.',
      ],
      'tables': {
        'exercises': await rows(db.exercises),
        'workoutTemplates': await rows(db.workoutTemplates),
        'templateExercises': await rows(db.templateExercises),
        'workoutSessions': await rows(db.workoutSessions),
        'sessionExercises': await rows(db.sessionExercises),
        'setEntries': await rows(db.setEntries),
        'foods': await rows(db.foods),
        'mealSlots': await rows(db.mealSlots),
        'mealEntries': await rows(db.mealEntries),
        'settings': await rows(db.settings),
        'aiProposals': await rows(db.aiProposals),
        'healthWrites': await rows(db.healthWrites),
      },
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// Replaces every local record with the records in an export file.
  ///
  /// Used to restore a backup. Runs in one transaction: if any row fails,
  /// nothing changes. AI data choices and health switches are not restored,
  /// because the new phone has not granted them (handbook 9.2, 10.5).
  /// Returns the number of records restored.
  Future<int> importJson(String json) async {
    final root = jsonDecode(json) as Map<String, dynamic>;
    if (root['format'] != 'reparc-export') throw const FormatException('Not a Reparc export');
    final schema = root['schemaVersion'] as int? ?? 0;
    if (schema > db.schemaVersion) throw const FormatException('Made by a newer version of Reparc');
    final tables = (root['tables'] as Map).cast<String, dynamic>();
    final ser = _IsoSerializer();
    List<Map<String, dynamic>> rows(String name) => [
      for (final r in (tables[name] as List?) ?? const []) (r as Map).cast<String, dynamic>(),
    ];
    var count = 0;
    Future<void> put<T extends Table, D>(
      TableInfo<T, D> table,
      String name,
      D Function(Map<String, dynamic>) parse,
    ) async {
      for (final r in rows(name)) {
        await db.into(table).insert(parse(r) as Insertable<D>);
        count++;
      }
    }

    await db.transaction(() async {
      await _clear();
      await put(db.exercises, 'exercises', (j) => Exercise.fromJson(j, serializer: ser));
      await put(db.workoutTemplates, 'workoutTemplates', (j) => WorkoutTemplate.fromJson(j, serializer: ser));
      await put(db.templateExercises, 'templateExercises', (j) => TemplateExercise.fromJson(j, serializer: ser));
      await put(db.workoutSessions, 'workoutSessions', (j) => WorkoutSession.fromJson(j, serializer: ser));
      await put(db.sessionExercises, 'sessionExercises', (j) => SessionExercise.fromJson(j, serializer: ser));
      await put(db.setEntries, 'setEntries', (j) => SetEntry.fromJson(j, serializer: ser));
      await put(db.foods, 'foods', (j) => Food.fromJson(j, serializer: ser));
      await put(db.mealSlots, 'mealSlots', (j) => MealSlot.fromJson(j, serializer: ser));
      await put(db.mealEntries, 'mealEntries', (j) => MealEntry.fromJson(j, serializer: ser));
      await put(db.aiProposals, 'aiProposals', (j) => AiProposal.fromJson(j, serializer: ser));
      for (final r in rows('settings')) {
        final key = r['key'] as String;
        if (key.startsWith('health') || key.startsWith('ai.')) continue;
        await db.into(db.settings).insert(Setting.fromJson(r, serializer: ser));
        count++;
      }
      // Health write-back history belongs to the old phone's health store.
      if ((await db.select(db.mealSlots).get()).isEmpty) await db.seedMealSlots();
    });
    return count;
  }

  Future<void> _clear() async {
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final TableInfo<Table, dynamic> t in [
      db.setEntries,
      db.sessionExercises,
      db.workoutSessions,
      db.templateExercises,
      db.workoutTemplates,
      db.mealEntries,
      db.foods,
      db.mealSlots,
      db.exercises,
      db.settings,
      db.aiProposals,
      db.healthWrites,
    ]) {
      await db.delete(t).go();
    }
  }

  /// Deletes every local record and restores default meal slots.
  Future<void> deleteAll() => db.transaction(() async {
    await _clear();
    await db.seedMealSlots();
  });
}

Map<String, Object?> _jsonSafe(Map<String, dynamic> m) => m.map((k, v) => MapEntry(k, v));

class _IsoSerializer extends ValueSerializer {
  final _default = const ValueSerializer.defaults();

  @override
  T fromJson<T>(dynamic json) {
    if (json is String && (T == DateTime || T == _typeOf<DateTime?>())) return DateTime.parse(json) as T;
    return _default.fromJson<T>(json);
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return _default.toJson<T>(value);
  }
}

Type _typeOf<T>() => T;
