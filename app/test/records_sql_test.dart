import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/analytics.dart';

import 'helpers.dart';

/// The fast, SQL-side records and volumes must give the same answers as
/// the plain Dart rules over every completed set (2026-10-12).
void main() {
  test('SQL records, PR moments, and volumes match the Dart rules', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final repo = WorkoutRepository(db, FakeClock(DateTime.utc(2026, 5, 1)).call);
    final rnd = Random(7);
    final ex = [for (var i = 0; i < 6; i++) await repo.createExercise(name: 'Move $i')];
    final base = DateTime.utc(2026, 1, 1);
    await db.batch((b) {
      for (var d = 0; d < 60; d++) {
        final sid = 's$d';
        // A few sessions share a start time, and the last two are live.
        final start = base.add(Duration(days: d ~/ 2 * 2, hours: 18));
        final status = d >= 58
            ? (d == 58 ? SessionStatus.active : SessionStatus.paused)
            : (d % 9 == 0 ? SessionStatus.incomplete : SessionStatus.finished);
        b.insert(
          db.workoutSessions,
          WorkoutSessionsCompanion.insert(
            id: sid,
            name: 'W',
            status: status,
            startedAt: start,
            utcOffsetMinutes: 0,
            timeZoneName: 'UTC',
            createdAt: start,
            updatedAt: start,
          ),
        );
        for (var e = 0; e < 4; e++) {
          final se = '$sid-$e';
          b.insert(
            db.sessionExercises,
            SessionExercisesCompanion.insert(
              id: se,
              sessionId: sid,
              exerciseId: ex[rnd.nextInt(ex.length)],
              position: e,
              createdAt: start,
              updatedAt: start,
            ),
          );
          for (var s = 0; s < 4; s++) {
            final hasLoad = rnd.nextInt(8) != 0;
            b.insert(
              db.setEntries,
              SetEntriesCompanion.insert(
                id: '$se-$s',
                sessionExerciseId: se,
                position: s,
                setType: s == 0 ? SetType.warmup : SetType.working,
                reps: Value(rnd.nextInt(6) == 0 ? null : 5 + rnd.nextInt(6)),
                load: Value(hasLoad ? 20 + rnd.nextInt(8) * 2.5 : null),
                loadUnit: Value(hasLoad ? (rnd.nextInt(5) == 0 ? 'lb' : 'kg') : null),
                completed: Value(rnd.nextInt(6) != 0),
                createdAt: start,
                updatedAt: start,
              ),
            );
          }
        }
      }
    });

    final all = await repo.completedSets();
    String key(PersonalRecord p) => '${p.source.exercise.id} ${p.source.set.loadUnit} ${p.source.set.id}';
    // The same records. Two records of one exercise (kg and lb) may swap
    // places: the old rule left their order to the sort.
    final fast = await repo.heaviestLoadRecords();
    expect(fast.map(key).toSet(), heaviestLoads(all).map(key).toSet());
    expect(fast, hasLength(heaviestLoads(all).length));
    expect(
      fast.map((p) => p.source.exercise.name).toList(),
      heaviestLoads(all).map((p) => p.source.exercise.name).toList(),
    );
    var moments = 0;
    for (var d = 0; d < 60; d++) {
      moments += newRecordsIn('s$d', all).length;
      expect(
        (await repo.newRecordsInSession('s$d')).map(key).toSet(),
        newRecordsIn('s$d', all).map(key).toSet(),
        reason: 's$d',
      );
    }
    expect(moments, greaterThan(0), reason: 'The data must hold PR moments to compare');
    final cards = await repo.watchHistory().first;
    final bySession = <String, List<SetRecord>>{};
    for (final r in all) {
      (bySession[r.session.id] ??= []).add(r);
    }
    for (final c in cards) {
      final v = volumeOf(bySession[c.session.id] ?? const []);
      if (v.counted == 0) {
        expect(c.volume, isNull);
      } else {
        expect(c.volume!.kg, closeTo(v.kg, 1e-6));
        expect((c.volume!.counted, c.volume!.skipped), (v.counted, v.skipped));
      }
    }
  });
}
