import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/workout_repository.dart';
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

  test('starting a plan copies it; later plan edits do not change the session', () async {
    final squat = await repo.createExercise(name: 'Squat', variation: 'Back');
    final plan = await repo.createTemplate('Legs');
    await repo.addTemplateExercise(plan, squat, targetSets: 3, targetReps: 5);

    final sessionId = await repo.startSession(templateId: plan);
    var detail = (await repo.loadSession(sessionId))!;
    expect(detail.exercises, hasLength(1));
    expect(detail.exercises.single.sets, hasLength(3));
    // Template targets do not become recorded values.
    expect(detail.exercises.single.sets.every((s) => s.reps == null && !s.completed), isTrue);

    final item = (await repo.loadTemplate(plan))!.items.single.item;
    await repo.removeTemplateExercise(item.id);
    detail = (await repo.loadSession(sessionId))!;
    expect(detail.exercises, hasLength(1));
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

  test('copying a plan keeps order and targets', () async {
    final a = await repo.createExercise(name: 'A');
    final b = await repo.createExercise(name: 'B');
    final plan = await repo.createTemplate('Full body');
    await repo.addTemplateExercise(plan, a, targetSets: 2);
    await repo.addTemplateExercise(plan, b, targetSets: 4);
    await repo.moveTemplateExercise(plan, 1, 0);
    final copy = (await repo.loadTemplate(await repo.copyTemplate(plan)))!;
    expect(copy.template.name, 'Full body (copy)');
    expect(copy.items.map((i) => i.exercise.name), ['B', 'A']);
    expect(copy.items.map((i) => i.item.targetSets), [4, 2]);
  });
}
