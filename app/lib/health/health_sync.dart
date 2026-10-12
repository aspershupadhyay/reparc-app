import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/database.dart';
import '../data/meal_repository.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../data/settings_repository.dart';
import 'health_service.dart';

/// Writes finished workouts, runs, walks, rides, and eaten meals to Apple Health or Health
/// Connect, when the user switched that on (handbook 9.5).
///
/// - Only records saved after the switch was turned on are written.
/// - Each record is written once; [HealthWrites] remembers it.
/// - A meal with no nutrient values is not written.
/// - Edits made after writing are not sent. The user can change or delete
///   the copy in the Health app.
class HealthSync {
  HealthSync(this.db, this.health, this.settings, this.clock);

  final AppDatabase db;
  final HealthSource health;
  final SettingsRepository settings;
  final Clock clock;
  bool _busy = false;

  /// Writes what is due. Returns the number of records written.
  Future<int> run() async {
    if (_busy) return 0;
    _busy = true;
    try {
      final s = await settings.watch().first;
      var written = 0;
      if (s.health.contains(HealthFeature.writeWorkouts.name)) {
        written += await _workouts();
        written += await _activities();
      }
      if (s.health.contains(HealthFeature.writeMeals.name)) written += await _meals();
      return written;
    } catch (_) {
      // The health store can be unavailable; the next change tries again.
      return 0;
    } finally {
      _busy = false;
    }
  }

  Future<Set<String>> _done(String kind) async => {
    for (final r in await (db.select(db.healthWrites)..where((w) => w.kind.equals(kind))).get()) r.recordId,
  };

  Future<void> _mark(String id, String kind) => db
      .into(db.healthWrites)
      .insertOnConflictUpdate(HealthWritesCompanion.insert(recordId: id, kind: kind, writtenAt: clock().toUtc()));

  Future<int> _workouts() async {
    final since = await settings.healthSince(HealthFeature.writeWorkouts.name);
    if (since == null) return 0;
    final done = await _done('workout');
    final sessions =
        await (db.select(db.workoutSessions)
              ..where((x) => x.status.equalsValue(SessionStatus.finished))
              ..where((x) => x.endedAt.isBiggerOrEqualValue(since)))
            .get();
    var n = 0;
    for (final x in sessions) {
      if (done.contains(x.id) || x.endedAt == null) continue;
      if (await health.writeWorkout(id: x.id, title: x.name, start: x.startedAt.toLocal(), end: x.endedAt!.toLocal())) {
        await _mark(x.id, 'workout');
        n++;
      }
    }
    return n;
  }

  /// Finished runs, walks, and rides, as workouts of that kind.
  Future<int> _activities() async {
    final since = await settings.healthSince(HealthFeature.writeWorkouts.name);
    if (since == null) return 0;
    final done = await _done('activity');
    final list =
        await (db.select(db.activities)
              ..where((x) => x.status.equalsValue(ActivityStatus.finished))
              ..where((x) => x.endedAt.isBiggerOrEqualValue(since)))
            .get();
    var n = 0;
    for (final a in list) {
      if (done.contains(a.id) || a.endedAt == null || (a.distanceM ?? 0) < 10) continue;
      if (await health.writeWorkout(
        id: a.id,
        title: a.name,
        start: a.startedAt.toLocal(),
        end: a.endedAt!.toLocal(),
        activity: a.kind,
      )) {
        await _mark(a.id, 'activity');
        n++;
      }
    }
    return n;
  }

  Future<int> _meals() async {
    final since = await settings.healthSince(HealthFeature.writeMeals.name);
    if (since == null) return 0;
    final done = await _done('meal');
    final slots = {for (final s in await db.select(db.mealSlots).get()) s.id: s.kind};
    final entries =
        await (db.select(db.mealEntries)
              ..where((e) => e.status.equalsValue(MealStatus.eaten))
              ..where((e) => e.eatenAt.isBiggerOrEqualValue(since)))
            .get();
    var n = 0;
    for (final e in entries) {
      if (done.contains(e.id) || e.eatenAt == null) continue;
      final v = e.input.eaten;
      if (v.energyKcal == null && v.proteinG == null && v.carbsG == null && v.fatG == null) continue;
      if (await health.writeMeal(
        id: e.id,
        name: e.name,
        slotKind: slots[e.slotId],
        at: e.eatenAt!.toLocal(),
        energyKcal: v.energyKcal,
        proteinG: v.proteinG,
        carbsG: v.carbsG,
        fatG: v.fatG,
      )) {
        await _mark(e.id, 'meal');
        n++;
      }
    }
    return n;
  }
}

/// Runs [HealthSync] a few seconds after workouts or meals change.
final healthSyncProvider = Provider<HealthSync>((ref) {
  final db = ref.watch(databaseProvider);
  final sync = HealthSync(
    db,
    ref.watch(healthSourceProvider),
    ref.watch(settingsRepoProvider),
    ref.watch(clockProvider),
  );
  Timer? debounce;
  final sub = db
      .tableUpdates(TableUpdateQuery.onAllTables([db.workoutSessions, db.activities, db.mealEntries, db.settings]))
      .listen((
        _,
      ) {
        debounce?.cancel();
        debounce = Timer(const Duration(seconds: 3), () => unawaited(sync.run()));
      });
  ref.onDispose(() {
    debounce?.cancel();
    unawaited(sub.cancel());
  });
  return sync;
});
