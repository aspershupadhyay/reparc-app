import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/roadmap.dart';
import 'package:reparc/domain/session_time.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late WorkoutRepository repo;

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime.utc(2026, 3, 2, 18));
    repo = WorkoutRepository(db, clock.call);
  });
  tearDown(() => db.close());

  test('starting a plan day copies it; later plan edits do not change the session', () async {
    final programs = ProgramRepository(db, clock.call);
    final squat = await repo.createExercise(name: 'Squat', variation: 'Back');
    final row = await repo.createExercise(name: 'Row');
    final plan = ProgramPlan(
      days: [
        simpleDay('Legs', [
          (exerciseId: userRef(squat), name: 'Squat', sets: 3, reps: 5),
          (exerciseId: userRef(row), name: 'Row', sets: null, reps: null),
        ]),
      ],
    );
    final id = await programs.create(plan, name: 'Legs');
    final sessionId = await repo.startProgramDay(programId: id, dayIndex: 0);
    var detail = (await repo.loadSession(sessionId))!;
    expect(detail.exercises.map((e) => e.exercise.id), [squat, row], reason: 'user: links to the own exercise');
    expect(detail.exercises.first.sets, hasLength(3));
    // Targets do not become recorded values.
    expect(detail.exercises.first.sets.every((s) => s.reps == null && !s.completed), isTrue);
    expect(detail.exercises.first.item.note, 'Target: 3 × 5');
    // Without a target: one empty set and no note.
    expect(detail.exercises.last.sets, hasLength(1));
    expect(detail.exercises.last.item.note, isNull);

    await programs.save(id, plan.copyWith(days: [simpleDay('Legs', const [])]));
    detail = (await repo.loadSession(sessionId))!;
    expect(detail.exercises, hasLength(2));
  });

  test('only one live session at a time', () async {
    await repo.startSession();
    expect(repo.startSession(), throwsStateError);
  });

  test('pause time is excluded from elapsed time and survives reload', () async {
    final id = await repo.startSession();
    clock.advance(const Duration(minutes: 10));
    await repo.pause(id);
    clock.advance(const Duration(minutes: 5));
    await repo.resume(id);
    clock.advance(const Duration(minutes: 2));

    // Simulate an app restart: read only what is stored.
    final s = (await repo.loadSession(id))!.session;
    final elapsed = sessionElapsed(
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      pausedAt: s.pausedAt,
      pausedMs: s.pausedMs,
      now: clock.now,
    );
    expect(elapsed, const Duration(minutes: 12));
    expect(s.status, SessionStatus.active);
  });

  test('finishing while paused counts the pause and clears the rest timer', () async {
    final id = await repo.startSession();
    await repo.startRest(id, 90);
    clock.advance(const Duration(minutes: 30));
    await repo.pause(id);
    clock.advance(const Duration(minutes: 10));
    await repo.end(id, finished: true);
    final s = (await repo.loadSession(id))!.session;
    expect(s.status, SessionStatus.finished);
    expect(s.restStartedAt, isNull);
    expect(
      sessionElapsed(
        startedAt: s.startedAt,
        endedAt: s.endedAt,
        pausedAt: s.pausedAt,
        pausedMs: s.pausedMs,
        now: clock.now,
      ),
      const Duration(minutes: 30),
    );
  });

  test('set values keep missing distinct from zero and keep the unit', () async {
    final ex = await repo.createExercise(name: 'Plank');
    final id = await repo.startSession();
    final se = await repo.addSessionExercise(id, ex);
    final setId = await repo.addSet(se, type: SetType.timed);
    await repo.updateSet(setId, const SetEntriesCompanion(durationSec: Value(60)));
    final zeroSet = await repo.addSet(se);
    await repo.updateSet(zeroSet, const SetEntriesCompanion(load: Value(0), loadUnit: Value('kg'), reps: Value(10)));

    final sets = (await repo.loadSession(id))!.exercises.single.sets;
    expect(sets[0].reps, isNull);
    expect(sets[0].load, isNull);
    expect(sets[0].durationSec, 60);
    expect(sets[1].load, 0);
    expect(sets[1].loadUnit, 'kg');
  });

  test('deleted set can be restored with the same id and position', () async {
    final ex = await repo.createExercise(name: 'Row');
    final id = await repo.startSession();
    final se = await repo.addSessionExercise(id, ex);
    final a = await repo.addSet(se);
    await repo.addSet(se);
    final removed = await repo.deleteSet(a);
    expect((await repo.loadSession(id))!.totalSets, 1);
    await repo.restoreSet(removed!);
    final sets = (await repo.loadSession(id))!.exercises.single.sets;
    expect(sets.map((s) => s.id).first, a);
  });

  test('history and records only use completed sets in saved sessions', () async {
    final ex = await repo.createExercise(name: 'Bench press');
    final id = await repo.startSession();
    final se = await repo.addSessionExercise(id, ex);
    final done = await repo.addSet(se);
    await repo.updateSet(done, const SetEntriesCompanion(load: Value(60), loadUnit: Value('kg'), reps: Value(5)));
    await repo.setCompleted(done, true);
    await repo.addSet(se); // Not completed.

    expect(await repo.completedSets(exerciseId: ex), isEmpty, reason: 'live session is not saved yet');
    await repo.end(id, finished: false);
    final history = await repo.completedSets(exerciseId: ex);
    expect(history, hasLength(1));
    expect(history.single.set.load, 60);

    final summaries = await repo.sessionSummaries();
    expect(summaries.single.completedSets, 1);
    expect(summaries.single.exerciseCount, 1);
    expect(summaries.single.session.status, SessionStatus.incomplete);
  });

  test('deleting a session removes its sets', () async {
    final ex = await repo.createExercise(name: 'Curl');
    final id = await repo.startSession();
    final se = await repo.addSessionExercise(id, ex);
    await repo.addSet(se);
    await repo.deleteSession(id);
    expect(await db.select(db.setEntries).get(), isEmpty);
    expect(await db.select(db.sessionExercises).get(), isEmpty);
  });

  test('archived exercise leaves the library but stays in saved sessions', () async {
    final ex = await repo.createExercise(name: 'Dip');
    final id = await repo.startSession();
    await repo.addSessionExercise(id, ex);
    await repo.archiveExercise(ex);
    expect(await repo.watchExercises().first, isEmpty);
    expect((await repo.loadSession(id))!.exercises.single.exercise.name, 'Dip');
  });

  test('copying a plan keeps its days and is not followed', () async {
    final programs = ProgramRepository(db, clock.call);
    final id = await programs.adopt(
      buildProgram(goal: RoadmapGoal.strength, level: RoadmapLevel.beginner, setup: GymSetup.fullGym, days: 2),
      name: 'Strength',
    );
    final copy = await programs.copy(id);
    final all = await programs.all();
    final c = all.firstWhere((p) => p.id == copy);
    expect(c.name, 'Strength (copy)');
    expect(c.followed, isFalse);
    expect(c.plan.encode(), all.firstWhere((p) => p.id == id).plan.encode());
    expect((await programs.active())!.id, id);
  });

  test('a built-in exercise maps to one row and keeps its history', () async {
    final a = await repo.ensureCatalogExercise(catalogId: 'back-squat', name: 'Back squat');
    final b = await repo.ensureCatalogExercise(catalogId: 'back-squat', name: 'Back squat');
    expect(a, b);
    await repo.archiveExercise(a);
    expect(await repo.ensureCatalogExercise(catalogId: 'back-squat', name: 'Back squat'), a);
    expect((await repo.watchExercises().first).single.catalogId, 'back-squat');
  });
}
