import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/clock.dart';
import 'database.dart';

/// Export and deletion of all local records (handbook 7.6).
class DataControls {
  DataControls(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  /// Every data scope. An export for a backup uses all of them.
  static const allScopes = {'workout', 'meal', 'body'};

  /// Version of the export file layout. Change it when fields change.
  static const exportFormatVersion = 2;

  /// Builds a JSON export of every local record.
  ///
  /// The export keeps field names, units, timestamps, sources, and missing
  /// values. A missing value is written as null, never as zero.
  ///
  /// [scopes] limits the export to the data the user chose: `workout`,
  /// `meal`, and `body` (profile, targets, weight). Settings that are not
  /// personal data, such as units, are always kept.
  Future<String> exportJson({required String appVersion, Set<String> scopes = DataControls.allScopes}) async {
    Future<List<Map<String, Object?>>> rows(TableInfo<Table, DataClass> t) async {
      final data = await db.select(t).get();
      return [for (final r in data) _jsonSafe(r.toJson(serializer: _IsoSerializer()))];
    }

    final workout = scopes.contains('workout'), meal = scopes.contains('meal'), body = scopes.contains('body');
    final settings = [
      for (final r in await rows(db.settings))
        if (body || !(r['key'] as String).startsWith('profile.') && r['key'] != 'targetsOn') r,
    ];
    final none = <Map<String, Object?>>[];
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
        'sodiumMg is milligrams. fiberG and sugarG are grams.',
        'programs.plan is a JSON document: the roadmap days, warm-ups, and exercise targets.',
      ],
      'scopes': [
        for (final s in DataControls.allScopes)
          if (scopes.contains(s)) s,
      ],
      'tables': {
        'exercises': workout ? await rows(db.exercises) : none,
        'workoutTemplates': workout ? await rows(db.workoutTemplates) : none,
        'templateExercises': workout ? await rows(db.templateExercises) : none,
        'workoutSessions': workout ? await rows(db.workoutSessions) : none,
        'sessionExercises': workout ? await rows(db.sessionExercises) : none,
        'setEntries': workout ? await rows(db.setEntries) : none,
        'foods': meal ? await rows(db.foods) : none,
        'mealSlots': meal ? await rows(db.mealSlots) : none,
        'mealEntries': meal ? await rows(db.mealEntries) : none,
        'programs': workout ? await rows(db.programs) : none,
        'bodyWeights': body ? await rows(db.bodyWeights) : none,
        'settings': settings,
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
      db.programs,
      db.bodyWeights,
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
