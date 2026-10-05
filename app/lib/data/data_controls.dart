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
      },
    };
    return const JsonEncoder.withIndent('  ').convert(out);
  }

  /// Deletes every local record and restores default meal slots.
  Future<void> deleteAll() => db.transaction(() async {
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
    ]) {
      await db.delete(t).go();
    }
    await db.seedMealSlots();
  });
}

Map<String, Object?> _jsonSafe(Map<String, dynamic> m) => m.map((k, v) => MapEntry(k, v));

class _IsoSerializer extends ValueSerializer {
  final _default = const ValueSerializer.defaults();

  @override
  T fromJson<T>(dynamic json) => _default.fromJson<T>(json);

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return _default.toJson<T>(value);
  }
}
