import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import 'database.dart';
import '../domain/roadmap.dart';
import 'models.dart';
import 'watch.dart';

const _uuid = Uuid();

class SessionExerciseView {
  const SessionExerciseView(this.item, this.exercise, this.sets);
  final SessionExercise item;
  final Exercise exercise;
  final List<SetEntry> sets;

  int get completedSets => sets.where((s) => s.completed).length;
}

class SessionDetail {
  const SessionDetail(this.session, this.exercises);
  final WorkoutSession session;
  final List<SessionExerciseView> exercises;

  int get completedSets => exercises.fold(0, (a, e) => a + e.completedSets);
  int get totalSets => exercises.fold(0, (a, e) => a + e.sets.length);
}

class SessionSummary {
  const SessionSummary(this.session, this.exerciseCount, this.completedSets);
  final WorkoutSession session;

  /// Exercises with at least one working set. Warm-up moves are not counted.
  final int exerciseCount;

  /// Completed working sets. Warm-up sets are not counted.
  final int completedSets;
}

/// One completed set with its exercise, used for history and records.
class SetRecord {
  const SetRecord(this.set, this.exercise, this.session);
  final SetEntry set;
  final Exercise exercise;
  final WorkoutSession session;
}

/// Saves and reads workout records. Every write goes to the local database
/// first (handbook 4.2). There is no network path here.
class WorkoutRepository {
  WorkoutRepository(this.db, this.clock);

  final AppDatabase db;
  final Clock clock;

  DateTime get _now => clock().toUtc();

  // ---------------------------------------------------------------- Library

  Stream<List<Exercise>> watchExercises() =>
      (db.select(db.exercises)
            ..where((e) => e.archived.equals(false))
            ..orderBy([(e) => OrderingTerm.asc(e.name.lower())]))
          .watch();

  Future<Exercise?> exercise(String id) => (db.select(db.exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Stream<Exercise?> watchExercise(String id) =>
      (db.select(db.exercises)..where((e) => e.id.equals(id))).watchSingleOrNull();

  Future<String> createExercise({
    required String name,
    String? variation,
    String? equipment,
    String? targetMuscles,
    String? note,
  }) async {
    final id = _uuid.v4();
    final now = _now;
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: id,
            name: name.trim(),
            variation: Value(_clean(variation)),
            equipment: Value(_clean(equipment)),
            targetMuscles: Value(_clean(targetMuscles)),
            note: Value(_clean(note)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateExercise(
    String id, {
    required String name,
    String? variation,
    String? equipment,
    String? targetMuscles,
    String? note,
  }) => (db.update(db.exercises)..where((e) => e.id.equals(id))).write(
    ExercisesCompanion(
      name: Value(name.trim()),
      variation: Value(_clean(variation)),
      equipment: Value(_clean(equipment)),
      targetMuscles: Value(_clean(targetMuscles)),
      note: Value(_clean(note)),
      updatedAt: Value(_now),
    ),
  );

  /// Returns the row that logs built-in exercise [catalogId], creating it
  /// on first use. One row per built-in exercise keeps its history together.
  Future<String> ensureCatalogExercise({
    required String catalogId,
    required String name,
    String? equipment,
    String? targetMuscles,
  }) => db.transaction(() async {
    final found = await (db.select(db.exercises)..where((e) => e.catalogId.equals(catalogId))).getSingleOrNull();
    if (found != null) {
      if (found.archived) {
        await (db.update(db.exercises)..where((e) => e.id.equals(found.id))).write(
          ExercisesCompanion(archived: const Value(false), updatedAt: Value(_now)),
        );
      }
      return found.id;
    }
    final id = _uuid.v4();
    final now = _now;
    await db
        .into(db.exercises)
        .insert(
          ExercisesCompanion.insert(
            id: id,
            name: name,
            equipment: Value(equipment),
            targetMuscles: Value(targetMuscles),
            catalogId: Value(catalogId),
            instructionSource: const Value('Reparc coaching guide'),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  });

  /// The logged row for a built-in exercise, if the user has used it.
  Stream<Exercise?> watchCatalogExercise(String catalogId) =>
      (db.select(db.exercises)..where((e) => e.catalogId.equals(catalogId))).watchSingleOrNull();

  /// Removes an exercise from the library. Saved workouts keep it.
  Future<void> archiveExercise(String id) => (db.update(db.exercises)..where((e) => e.id.equals(id))).write(
    ExercisesCompanion(archived: const Value(true), updatedAt: Value(_now)),
  );

  /// Completed sets for one exercise, newest first.
  Stream<List<SetRecord>> watchExerciseHistory(String exerciseId) {
    return watchTables(
      db,
      [db.setEntries, db.sessionExercises, db.workoutSessions, db.exercises],
      () => completedSets(exerciseId: exerciseId),
    );
  }

  /// Completed sets in saved (finished or incomplete) sessions.
  Future<List<SetRecord>> completedSets({
    String? exerciseId,
    DateTime? fromUtc,
    DateTime? toUtc,
  }) async {
    final q =
        db.select(db.setEntries).join([
            innerJoin(db.sessionExercises, db.sessionExercises.id.equalsExp(db.setEntries.sessionExerciseId)),
            innerJoin(db.exercises, db.exercises.id.equalsExp(db.sessionExercises.exerciseId)),
            innerJoin(db.workoutSessions, db.workoutSessions.id.equalsExp(db.sessionExercises.sessionId)),
          ])
          ..where(db.setEntries.completed.equals(true))
          ..where(db.workoutSessions.status.isNotInValues([SessionStatus.active, SessionStatus.paused]))
          ..orderBy([
            OrderingTerm.desc(db.workoutSessions.startedAt),
            OrderingTerm.asc(db.sessionExercises.position),
            OrderingTerm.asc(db.setEntries.position),
          ]);
    if (exerciseId != null) q.where(db.sessionExercises.exerciseId.equals(exerciseId));
    if (fromUtc != null) q.where(db.workoutSessions.startedAt.isBiggerOrEqualValue(fromUtc));
    if (toUtc != null) q.where(db.workoutSessions.startedAt.isSmallerThanValue(toUtc));
    final rows = await q.get();
    return [
      for (final r in rows)
        SetRecord(r.readTable(db.setEntries), r.readTable(db.exercises), r.readTable(db.workoutSessions)),
    ];
  }

  // --------------------------------------------------------------- Sessions

  /// The session that is in progress or paused, if any.
  Stream<WorkoutSession?> watchLiveSession() =>
      (db.select(db.workoutSessions)
            ..where((s) => s.status.isInValues([SessionStatus.active, SessionStatus.paused]))
            ..orderBy([(s) => OrderingTerm.desc(s.startedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<WorkoutSession?> liveSession() =>
      (db.select(db.workoutSessions)
            ..where((s) => s.status.isInValues([SessionStatus.active, SessionStatus.paused]))
            ..limit(1))
          .getSingleOrNull();

  /// Starts an empty session.
  Future<String> startSession() => db.transaction(() async {
    final live = await liveSession();
    if (live != null) throw StateError('A workout is already in progress.');
    final local = clock();
    final now = local.toUtc();
    final id = _uuid.v4();
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            name: 'Workout',
            status: SessionStatus.active,
            startedAt: now,
            utcOffsetMinutes: local.timeZoneOffset.inMinutes,
            timeZoneName: local.timeZoneName,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  });

  /// The exercise row a plan item logs to: the user's own exercise for a
  /// `user:` reference, else the row for that built-in ID.
  Future<String> _exerciseFor(PlanItem item) async {
    final own = userRefId(item.exerciseId);
    if (own != null) {
      final row = await (db.select(db.exercises)..where((e) => e.id.equals(own))).getSingleOrNull();
      if (row != null) return row.id;
      // The exercise is gone: log under the plan's name instead.
      return createExercise(name: item.name);
    }
    return ensureCatalogExercise(catalogId: item.exerciseId, name: item.name);
  }

  /// Starts a session from one day of a plan. Warm-up moves come first, with
  /// warm-up sets to tick off (warm-up sets never count toward volume, sets,
  /// or records). Then the working exercises, with lighter ramp-up sets
  /// before the first big lift and the day's target as a note. Cool-down
  /// stretches stay on the roadmap day; they are not logged.
  Future<String> startProgramDay({required String programId, required int dayIndex}) => db.transaction(() async {
    final live = await liveSession();
    if (live != null) throw StateError('A workout is already in progress.');
    final row = await (db.select(db.programs)..where((p) => p.id.equals(programId))).getSingle();
    final plan = ProgramPlan.decode(row.plan);
    if (dayIndex < 0 || dayIndex >= plan.days.length) throw StateError('That day is not in the roadmap.');
    final day = plan.days[dayIndex];
    final local = clock();
    final now = local.toUtc();
    final id = _uuid.v4();
    await db
        .into(db.workoutSessions)
        .insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            name: day.name,
            status: SessionStatus.active,
            startedAt: now,
            utcOffsetMinutes: local.timeZoneOffset.inMinutes,
            timeZoneName: local.timeZoneName,
            programId: Value(programId),
            programDay: Value(dayIndex),
            createdAt: now,
            updatedAt: now,
          ),
        );
    var pos = 0;
    if (plan.showWarmup) {
      for (final item in day.warmup) {
        final exId = await _exerciseFor(item);
        final seId = await _insertSessionExercise(id, exId, pos++);
        await _setNote(seId, ['Warm-up', item.details, ?item.note].where((s) => s.isNotEmpty).join(' · '));
        for (var i = 0; i < item.sets; i++) {
          final setId = await _insertSet(seId, i, SetType.warmup);
          if (item.seconds != null) {
            // The plan's time is a target, kept apart from the measured time.
            await updateSet(setId, SetEntriesCompanion(targetSec: Value(item.seconds)));
          }
        }
      }
    }
    for (final item in day.work) {
      final exId = await _exerciseFor(item);
      final seId = await _insertSessionExercise(id, exId, pos++);
      final note = [
        if (item.details.isNotEmpty) 'Target: ${item.details}',
        if (item.rampUp) 'Ramp-up sets first: ${rampUpText(plan.level)} of your working weight',
        ?item.note,
      ];
      if (note.isNotEmpty) await _setNote(seId, note.join('\n'));
      var setPos = 0;
      if (item.rampUp) {
        for (final _ in rampUpSets(plan.level)) {
          await _insertSet(seId, setPos++, SetType.warmup);
        }
      }
      for (var i = 0; i < item.sets; i++) {
        final setId = await _insertSet(seId, setPos++, item.seconds != null ? SetType.timed : SetType.working);
        if (item.seconds != null) {
          // The plan's time is a target, kept apart from the measured time.
          await updateSet(setId, SetEntriesCompanion(targetSec: Value(item.seconds)));
        }
      }
    }
    return id;
  });

  Future<void> _setNote(String sessionExerciseId, String note) => (db.update(
    db.sessionExercises,
  )..where((s) => s.id.equals(sessionExerciseId))).write(SessionExercisesCompanion(note: Value(note)));

  Stream<SessionDetail?> watchSession(String id) => watchTables(
    db,
    [db.workoutSessions, db.sessionExercises, db.setEntries, db.exercises],
    () => loadSession(id),
  );

  Future<SessionDetail?> loadSession(String id) async {
    final s = await (db.select(db.workoutSessions)..where((s) => s.id.equals(id))).getSingleOrNull();
    if (s == null) return null;
    final rows =
        await (db.select(db.sessionExercises).join([
                innerJoin(db.exercises, db.exercises.id.equalsExp(db.sessionExercises.exerciseId)),
              ])
              ..where(db.sessionExercises.sessionId.equals(id))
              ..orderBy([OrderingTerm.asc(db.sessionExercises.position)]))
            .get();
    final seIds = rows.map((r) => r.readTable(db.sessionExercises).id).toList();
    final sets = seIds.isEmpty
        ? <SetEntry>[]
        : await (db.select(db.setEntries)
                ..where((x) => x.sessionExerciseId.isIn(seIds))
                ..orderBy([(x) => OrderingTerm.asc(x.position)]))
              .get();
    return SessionDetail(s, [
      for (final r in rows)
        SessionExerciseView(
          r.readTable(db.sessionExercises),
          r.readTable(db.exercises),
          sets.where((x) => x.sessionExerciseId == r.readTable(db.sessionExercises).id).toList(),
        ),
    ]);
  }

  Stream<List<SessionSummary>> watchHistory() => watchTables(
    db,
    [db.workoutSessions, db.sessionExercises, db.setEntries],
    () => sessionSummaries(),
  );

  Future<List<SessionSummary>> sessionSummaries({DateTime? fromUtc, DateTime? toUtc}) async {
    final q = db.select(db.workoutSessions)
      ..where((s) => s.status.isNotInValues([SessionStatus.active, SessionStatus.paused]))
      ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]);
    if (fromUtc != null) q.where((s) => s.startedAt.isBiggerOrEqualValue(fromUtc));
    if (toUtc != null) q.where((s) => s.startedAt.isSmallerThanValue(toUtc));
    final sessions = await q.get();
    if (sessions.isEmpty) return const [];
    final ids = sessions.map((s) => s.id).toList();
    // Working sets only: warm-up sets never count toward totals (as in
    // Analytics). A warm-up move with no working set is not counted either.
    final notWarmup = db.setEntries.setType.equalsValue(SetType.warmup).not();
    final exCount = db.sessionExercises.id.count(distinct: true, filter: notWarmup);
    final setCount = db.setEntries.id.count(
      distinct: true,
      filter: db.setEntries.completed.equals(true) & notWarmup,
    );
    final rows =
        await (db.selectOnly(db.sessionExercises).join([
                leftOuterJoin(db.setEntries, db.setEntries.sessionExerciseId.equalsExp(db.sessionExercises.id)),
              ])
              ..addColumns([db.sessionExercises.sessionId, exCount, setCount])
              ..where(db.sessionExercises.sessionId.isIn(ids))
              ..groupBy([db.sessionExercises.sessionId]))
            .get();
    final stats = {
      for (final r in rows) r.read(db.sessionExercises.sessionId)!: (r.read(exCount)!, r.read(setCount)!),
    };
    return [
      for (final s in sessions) SessionSummary(s, stats[s.id]?.$1 ?? 0, stats[s.id]?.$2 ?? 0),
    ];
  }

  Future<void> pause(String id) async {
    final s = await _session(id);
    if (s.status != SessionStatus.active) return;
    await _writeSession(id, WorkoutSessionsCompanion(status: const Value(SessionStatus.paused), pausedAt: Value(_now)));
  }

  Future<void> resume(String id) async {
    final s = await _session(id);
    if (s.status != SessionStatus.paused) return;
    final now = _now;
    final extra = s.pausedAt == null ? 0 : now.difference(s.pausedAt!).inMilliseconds;
    await _writeSession(
      id,
      WorkoutSessionsCompanion(
        status: const Value(SessionStatus.active),
        pausedAt: const Value(null),
        pausedMs: Value(s.pausedMs + extra),
        // A pause also pauses the rest: the rest goes on from where it was.
        restStartedAt: s.restStartedAt == null
            ? const Value.absent()
            : Value(s.restStartedAt!.add(Duration(milliseconds: extra))),
      ),
    );
  }

  /// Ends a live session as finished or incomplete.
  Future<void> end(String id, {required bool finished}) async {
    final s = await _session(id);
    final now = _now;
    var pausedMs = s.pausedMs;
    if (s.pausedAt != null) pausedMs += now.difference(s.pausedAt!).inMilliseconds;
    await _writeSession(
      id,
      WorkoutSessionsCompanion(
        status: Value(finished ? SessionStatus.finished : SessionStatus.incomplete),
        endedAt: Value(now),
        pausedAt: const Value(null),
        pausedMs: Value(pausedMs),
        restStartedAt: const Value(null),
        restTargetSec: const Value(null),
      ),
    );
    // Only a finished day moves the roadmap on. An incomplete one stays next.
    if (finished && s.programId != null && s.programDay != null) {
      final prog = await (db.select(db.programs)..where((p) => p.id.equals(s.programId!))).getSingleOrNull();
      if (prog != null) {
        final days = ProgramPlan.decode(prog.plan).days.length;
        await (db.update(db.programs)..where((p) => p.id.equals(prog.id))).write(
          ProgramsCompanion(nextDay: Value(days == 0 ? 0 : (s.programDay! + 1) % days), updatedAt: Value(now)),
        );
      }
    }
  }

  Future<void> renameSession(String id, String name) =>
      _writeSession(id, WorkoutSessionsCompanion(name: Value(name.trim())));

  Future<void> setSessionNote(String id, String? note) =>
      _writeSession(id, WorkoutSessionsCompanion(note: Value(_clean(note))));

  /// Deletes a session with its exercises and sets.
  Future<void> deleteSession(String id) => (db.delete(db.workoutSessions)..where((s) => s.id.equals(id))).go();

  /// Starts a rest of [seconds], from [from] when the set ended earlier,
  /// such as while the phone was locked.
  Future<void> startRest(String id, int seconds, {DateTime? from}) => _writeSession(
    id,
    WorkoutSessionsCompanion(restStartedAt: Value(from ?? _now), restTargetSec: Value(seconds)),
  );

  Future<void> setRestTarget(String id, int seconds) =>
      _writeSession(id, WorkoutSessionsCompanion(restTargetSec: Value(seconds)));

  Future<void> stopRest(String id) => _writeSession(
    id,
    const WorkoutSessionsCompanion(restStartedAt: Value(null), restTargetSec: Value(null)),
  );

  Future<WorkoutSession> _session(String id) =>
      (db.select(db.workoutSessions)..where((s) => s.id.equals(id))).getSingle();

  Future<void> _writeSession(String id, WorkoutSessionsCompanion c) =>
      (db.update(db.workoutSessions)..where((s) => s.id.equals(id))).write(c.copyWith(updatedAt: Value(_now)));

  // ------------------------------------------------------ Session exercises

  Future<String> addSessionExercise(String sessionId, String exerciseId) async {
    final pos = await _nextPosition(db.sessionExercises, db.sessionExercises.sessionId, sessionId);
    final id = await _insertSessionExercise(sessionId, exerciseId, pos);
    await _writeSession(sessionId, const WorkoutSessionsCompanion());
    return id;
  }

  Future<void> replaceSessionExercise(String itemId, String exerciseId) =>
      (db.update(db.sessionExercises)..where((x) => x.id.equals(itemId))).write(
        SessionExercisesCompanion(exerciseId: Value(exerciseId), updatedAt: Value(_now)),
      );

  Future<void> setSkipped(String itemId, bool skipped) =>
      (db.update(db.sessionExercises)..where((x) => x.id.equals(itemId))).write(
        SessionExercisesCompanion(skipped: Value(skipped), updatedAt: Value(_now)),
      );

  Future<void> moveSessionExercise(String sessionId, int from, int to) => db.transaction(() async {
    final items =
        await (db.select(db.sessionExercises)
              ..where((t) => t.sessionId.equals(sessionId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final moved = items.removeAt(from);
    items.insert(to, moved);
    for (final (i, item) in items.indexed) {
      await (db.update(db.sessionExercises)..where((t) => t.id.equals(item.id))).write(
        SessionExercisesCompanion(position: Value(i), updatedAt: Value(_now)),
      );
    }
  });

  /// Removes an exercise and its sets. Returns what is needed for undo.
  Future<SessionExerciseView?> removeSessionExercise(String itemId) => db.transaction(() async {
    final item = await (db.select(db.sessionExercises)..where((x) => x.id.equals(itemId))).getSingleOrNull();
    if (item == null) return null;
    final ex = await (db.select(db.exercises)..where((x) => x.id.equals(item.exerciseId))).getSingle();
    final sets = await (db.select(db.setEntries)..where((x) => x.sessionExerciseId.equals(itemId))).get();
    await (db.delete(db.sessionExercises)..where((x) => x.id.equals(itemId))).go();
    return SessionExerciseView(item, ex, sets);
  });

  Future<void> restoreSessionExercise(SessionExerciseView v) => db.transaction(() async {
    await db.into(db.sessionExercises).insert(v.item);
    for (final s in v.sets) {
      await db.into(db.setEntries).insert(s);
    }
  });

  Future<String> _insertSessionExercise(String sessionId, String exerciseId, int pos) async {
    final id = _uuid.v4();
    final now = _now;
    await db
        .into(db.sessionExercises)
        .insert(
          SessionExercisesCompanion.insert(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            position: pos,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  // ------------------------------------------------------------------- Sets

  Future<String> addSet(String sessionExerciseId, {SetType type = SetType.working}) async {
    final pos = await _nextPosition(db.setEntries, db.setEntries.sessionExerciseId, sessionExerciseId);
    return _insertSet(sessionExerciseId, pos, type);
  }

  Future<String> _insertSet(String sessionExerciseId, int pos, SetType type) async {
    final id = _uuid.v4();
    final now = _now;
    await db
        .into(db.setEntries)
        .insert(
          SetEntriesCompanion.insert(
            id: id,
            sessionExerciseId: sessionExerciseId,
            position: pos,
            setType: type,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  /// Saves set fields. Pass [Value.absent] for fields that do not change.
  Future<void> updateSet(String id, SetEntriesCompanion c) =>
      (db.update(db.setEntries)..where((s) => s.id.equals(id))).write(c.copyWith(updatedAt: Value(_now)));

  Future<void> setCompleted(String id, bool completed, {DateTime? at}) => updateSet(
    id,
    SetEntriesCompanion(completed: Value(completed), completedAt: Value(completed ? (at ?? _now) : null)),
  );

  Future<SetEntry?> deleteSet(String id) => db.transaction(() async {
    final s = await (db.select(db.setEntries)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (s != null) await (db.delete(db.setEntries)..where((x) => x.id.equals(id))).go();
    return s;
  });

  Future<void> restoreSet(SetEntry s) => db.into(db.setEntries).insert(s);

  // ---------------------------------------------------------------- Helpers

  Future<int> _nextPosition(TableInfo<Table, dynamic> table, GeneratedColumn<String> parent, String parentId) async {
    final pos = table.columnsByName['position']! as GeneratedColumn<int>;
    final maxPos = pos.max();
    final row =
        await (db.selectOnly(table)
              ..addColumns([maxPos])
              ..where(parent.equals(parentId)))
            .getSingle();
    final m = row.read(maxPos);
    return m == null ? 0 : m + 1;
  }
}

String? _clean(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}
