import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/analytics_repository.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/analytics.dart';

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
}
