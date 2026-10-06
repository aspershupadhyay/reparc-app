import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/analytics_repository.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/analytics.dart';
import 'package:reparc/domain/nutrition.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  late WorkoutRepository w;
  late MealRepository m;
  late AnalyticsRepository a;

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime(2026, 3, 2, 18));
    w = WorkoutRepository(db, clock.call);
    m = MealRepository(db, clock.call);
    a = AnalyticsRepository(db, w, m);
  });
  tearDown(() => db.close());

  Future<void> workout(String exId, List<(double?, String?, int?)> sets, {bool complete = true}) async {
    final id = await w.startSession();
    final se = await w.addSessionExercise(id, exId);
    for (final s in sets) {
      final setId = await w.addSet(se);
      await w.updateSet(setId, SetEntriesCompanion(load: Value(s.$1), loadUnit: Value(s.$2), reps: Value(s.$3)));
      if (complete) await w.setCompleted(setId, true);
    }
    await w.end(id, finished: true);
  }

  test('summary is traced to saved records and keeps reps gaps visible', () async {
    final squat = await w.createExercise(name: 'Squat');
    await workout(squat, [(100, 'kg', 5), (100, 'kg', null)]);
    clock.advance(const Duration(days: 1));
    await workout(squat, [(105, 'kg', 3)]);
    clock.advance(const Duration(days: 1));
    await workout(squat, [(110, 'kg', 1)], complete: false);

    final s = await a.load(DateTime(2026, 3, 1), DateTime(2026, 3, 7));
    expect(s.sessions, hasLength(3));
    expect(s.trainingDays, hasLength(3));
    expect(s.completedSets, 3);
    expect(s.totalReps, 8);
    expect(s.setsWithoutReps, 1);
    expect(s.setsByDay, {'2026-03-02': 2, '2026-03-03': 1});
    expect(s.dayCount, 7);
  });

  test('range excludes records outside it', () async {
    final ex = await w.createExercise(name: 'Row');
    await workout(ex, [(50, 'kg', 8)]);
    final s = await a.load(DateTime(2026, 3, 3), DateTime(2026, 3, 9));
    expect(s.sessions, isEmpty);
    expect(s.completedSets, 0);
  });

  test('heaviest load keeps units and exercises apart', () async {
    final bench = await w.createExercise(name: 'Bench press');
    final incline = await w.createExercise(name: 'Bench press', variation: 'Incline');
    await workout(bench, [(80, 'kg', 5), (85, 'kg', 2)]);
    await workout(bench, [(200, 'lb', 1)]);
    await workout(incline, [(70, 'kg', 5), (0, 'kg', 10), (null, null, 12)]);

    final records = heaviestLoads(await w.completedSets());
    final values = records
        .map((r) => '${r.source.exercise.variation ?? '-'} ${r.source.set.load} ${r.source.set.loadUnit}')
        .toSet();
    expect(values, {'- 85.0 kg', '- 200.0 lb', 'Incline 70.0 kg'});
    expect(records.every((r) => r.rule == heaviestLoadRule), isTrue);
  });

  test('meal coverage counts only eaten entries', () async {
    await m.addEntry(
      day: '2026-03-02',
      slotId: 'slot-lunch',
      food: const FoodValues(name: 'Rice', servingAmount: 100, servingUnit: 'g', energyKcal: 130),
      amount: 200,
      amountUnit: 'g',
      status: MealStatus.eaten,
    );
    await m.addEntry(
      day: '2026-03-03',
      slotId: 'slot-lunch',
      food: const FoodValues(name: 'Soup'),
      amount: 1,
      amountUnit: 'serving',
      status: MealStatus.planned,
    );
    final s = await a.load(DateTime(2026, 3, 1), DateTime(2026, 3, 7));
    expect(s.mealDays, {'2026-03-02'});
    expect(s.nutrition.energyKcal.value, 260);
    expect(s.nutritionByDay.keys, ['2026-03-02']);
  });

  test('volume skips warm-ups, converts pounds exactly, and counts gaps', () async {
    final squat = await w.createExercise(name: 'Squat');
    final id = await w.startSession();
    final se = await w.addSessionExercise(id, squat);
    Future<void> add(double? load, String? unit, int? reps, {SetType type = SetType.working}) async {
      final s = await w.addSet(se, type: type);
      await w.updateSet(s, SetEntriesCompanion(load: Value(load), loadUnit: Value(unit), reps: Value(reps)));
      await w.setCompleted(s, true);
    }

    await add(60, 'kg', 8, type: SetType.warmup);
    await add(100, 'kg', 5);
    await add(225, 'lb', 5);
    await add(100, 'kg', null);
    await w.end(id, finished: true);

    final sets = await w.completedSets();
    final v = volumeOf(sets);
    expect(v.counted, 2);
    expect(v.skipped, 1);
    // 100 × 5 + 225 × 0.45359237 × 5 = 500 + 510.2914...
    expect(v.kg, closeTo(500 + 225 * 0.45359237 * 5, 1e-9));
    expect(v.inUnit('lb'), closeTo(v.kg / 0.45359237, 1e-9));
    expect(countSetsBy(sets, (r) => r.exercise.name), {'Squat': 3});
    expect(perWeek(6, 14), 3);
  });

  test('best estimates use sets of 1 to 10 reps and keep units apart', () async {
    final bench = await w.createExercise(name: 'Bench');
    await workout(bench, [(100, 'kg', 5), (80, 'kg', 12)]);
    clock.advance(const Duration(days: 2));
    await workout(bench, [(102.5, 'kg', 3), (200, 'lb', 5)]);
    final sets = await w.completedSets();
    final best = {for (final r in bestEstimates(sets)) r.source.set.loadUnit: r};
    // 100 × 5 → 114.58; 102.5 × 3 → 112.14. The 12-rep set is not used.
    expect(best['kg']!.source.set.load, 100);
    expect(best['kg']!.rule, bestEstimateRule);
    expect(best['lb']!.source.set.load, 200);
    final trend = estimateTrend(sets, exerciseId: bench, unit: 'kg');
    expect(trend, hasLength(2));
    expect(trend.first.$2, closeTo(114.583, 0.001));
    expect(trend.first.$1.isBefore(trend.last.$1), isTrue);
  });

  test('active time removes paused time', () async {
    final id = await w.startSession();
    clock.advance(const Duration(minutes: 10));
    await w.pause(id);
    clock.advance(const Duration(minutes: 5));
    await w.resume(id);
    clock.advance(const Duration(minutes: 20));
    await w.end(id, finished: true);
    final s = (await w.loadSession(id))!.session;
    expect(activeTime(s), const Duration(minutes: 30));
  });

  test('planned roadmap days follow the chosen weekdays', () {
    // 2 to 15 March 2026: Mondays 2 and 9, Wednesdays 4 and 11, Fridays 6 and 13.
    expect(plannedDays(from: DateTime(2026, 3, 2), to: DateTime(2026, 3, 15), weekdays: [1, 3, 5]), 6);
    expect(
      plannedDays(
        from: DateTime(2026, 3, 2),
        to: DateTime(2026, 3, 15),
        weekdays: [1, 3, 5],
        since: DateTime(2026, 3, 9),
      ),
      3,
    );
  });

  test('meal averages use only days with a value, and targets count hits', () async {
    Future<void> eat(String day, double protein, {double? fiber}) => m.addEntry(
      day: day,
      slotId: 'slot-lunch',
      food: FoodValues(name: 'Food', proteinG: protein, fiberG: fiber),
      amount: 1,
      amountUnit: 'serving',
      status: MealStatus.eaten,
    );
    await eat('2026-03-02', 120, fiber: 30);
    await eat('2026-03-03', 150);
    await eat('2026-03-04', 90, fiber: 20);
    final s = await a.load(DateTime(2026, 3, 1), DateTime(2026, 3, 7));
    final byDay = s.nutritionByDay;
    final protein = dailyAverage(byDay, Nutrient.protein);
    expect(protein.value, 120);
    expect(protein.days, 3);
    final fiber = dailyAverage(byDay, Nutrient.fiber);
    expect(fiber.value, 25);
    expect(fiber.days, 2, reason: 'A day with no fibre value is not a zero day');
    expect(daysOnTarget(byDay, Nutrient.protein, 120), (2, 3));
    expect(daysOnTarget(byDay, Nutrient.fiber, 25, limit: true), (1, 2));
  });
}
