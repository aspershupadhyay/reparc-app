import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/data_controls.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/workout_repository.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime.utc(2026, 3, 2, 8));
  });
  tearDown(() => db.close());

  test('new database has default meal slots', () async {
    final slots = await MealRepository(db, clock.call).watchSlots().first;
    expect(slots.map((s) => s.name), ['Breakfast', 'Lunch', 'Dinner', 'Snacks']);
  });

  test('export keeps units, sources, timestamps, and null for missing values', () async {
    final meals = MealRepository(db, clock.call);
    await meals.addEntry(
      day: '2026-03-02',
      slotId: 'slot-breakfast',
      food: const FoodValues(name: 'Oats', servingAmount: 40, servingUnit: 'g', energyKcal: 150),
      amount: 60,
      amountUnit: 'g',
      status: MealStatus.eaten,
    );
    final json = jsonDecode(await DataControls(db, clock.call).exportJson(appVersion: '0.1.0')) as Map<String, dynamic>;
    expect(json['format'], 'reparc-export');
    final entry = ((json['tables'] as Map)['mealEntries'] as List).single as Map;
    expect(entry['amount'], 60);
    expect(entry['amountUnit'], 'g');
    expect(entry['servingAmount'], 40);
    expect(entry['proteinG'], isNull);
    expect(entry['source'], sourceManual);
    expect(entry['createdAt'], '2026-03-02T08:00:00.000Z');
    expect(entry['status'], 'eaten');
  });

  test('delete all removes records and restores default slots', () async {
    final w = WorkoutRepository(db, clock.call);
    final ex = await w.createExercise(name: 'Squat');
    final s = await w.startSession();
    final se = await w.addSessionExercise(s, ex);
    await w.addSet(se);
    await MealRepository(db, clock.call).addSlot('Pre-workout');

    await DataControls(db, clock.call).deleteAll();

    expect(await db.select(db.exercises).get(), isEmpty);
    expect(await db.select(db.workoutSessions).get(), isEmpty);
    expect(await db.select(db.setEntries).get(), isEmpty);
    expect((await db.select(db.mealSlots).get()).length, 4);
  });
}
