import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/roadmap.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late WorkoutRepository workouts;
  late ProgramRepository programs;

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime.utc(2026, 3, 2, 18));
    workouts = WorkoutRepository(db, clock.call);
    programs = ProgramRepository(db, clock.call);
  });
  tearDown(() => db.close());

  test('a roadmap day starts a session with ramp-up sets and targets, then moves to the next day', () async {
    final plan = buildProgram(
      goal: RoadmapGoal.strength,
      level: RoadmapLevel.intermediate,
      setup: GymSetup.fullGym,
      days: 3,
    );
    final id = await programs.adopt(plan);
    expect((await programs.active())!.nextDay, 0);

    final sessionId = await workouts.startProgramDay(programId: id, dayIndex: 0);
    final detail = (await workouts.loadSession(sessionId))!;
    expect(detail.session.programId, id);
    expect(detail.session.name, plan.days[0].name);
    expect(detail.exercises, hasLength(plan.days[0].work.length));
    final first = detail.exercises.first;
    final main = plan.days[0].work.first;
    expect(first.exercise.catalogId, main.exerciseId);
    expect(first.sets.where((s) => s.setType == SetType.warmup), hasLength(3));
    expect(first.sets.where((s) => s.setType == SetType.working), hasLength(main.sets));
    expect(first.item.note, startsWith('Target: '));
    // Targets are never saved as done values.
    expect(first.sets.every((s) => s.reps == null && s.load == null && !s.completed), isTrue);

    await workouts.end(sessionId, finished: true);
    expect((await programs.active())!.nextDay, 1);
  });

  test('a new roadmap replaces the active one and edits are saved', () async {
    final a = await programs.adopt(
      buildProgram(goal: RoadmapGoal.aesthetic, level: RoadmapLevel.beginner, setup: GymSetup.home),
    );
    final b = await programs.adopt(
      buildProgram(goal: RoadmapGoal.calisthenics, level: RoadmapLevel.beginner, setup: GymSetup.home),
    );
    expect((await programs.active())!.id, b);
    final rows = await db.select(db.programs).get();
    expect(rows.firstWhere((r) => r.id == a).active, isFalse);

    final saved = (await programs.active())!;
    final edited = saved.plan.copyWith(showWarmup: false, days: [saved.plan.days.first.copyWith(name: 'My day')]);
    await programs.save(b, edited);
    final again = (await programs.active())!;
    expect(again.plan.showWarmup, isFalse);
    expect(again.plan.days.single.name, 'My day');
    expect(again.row.daysPerWeek, 1);
  });
}
