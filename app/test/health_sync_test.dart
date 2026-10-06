import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/health/health_sync.dart';

import 'fake_health.dart';
import 'helpers.dart';

void main() {
  test('writes only records saved after the switch, each once, and skips meals without values', () async {
    final db = memoryDb();
    final clock = FakeClock(DateTime.utc(2026, 3, 2, 8));
    final health = FakeHealth();
    final settings = SettingsRepository(db);
    final w = WorkoutRepository(db, clock.call);
    final m = MealRepository(db, clock.call);
    final sync = HealthSync(db, health, settings, clock.call);

    final old = await w.startSession();
    await w.end(old, finished: true);
    clock.advance(const Duration(hours: 1));
    await settings.setHealth('writeWorkouts', true, now: clock.now);
    await settings.setHealth('writeMeals', true, now: clock.now);
    clock.advance(const Duration(minutes: 5));

    final s = await w.startSession();
    clock.advance(const Duration(minutes: 45));
    await w.end(s, finished: true);
    final live = await w.startSession();
    expect(live, isNotEmpty);

    Future<String> meal(String name, double? kcal) => m.addEntry(
      day: '2026-03-02',
      slotId: 'slot-lunch',
      food: FoodValues(name: name, servingAmount: 1, servingUnit: 'serving', energyKcal: kcal),
      amount: 1,
      amountUnit: 'serving',
      status: MealStatus.eaten,
    );
    final rice = await meal('Rice', 200);
    await meal('Water', null);

    expect(await sync.run(), 2);
    expect(health.workouts, [s]);
    expect(health.meals, [rice]);
    expect(await sync.run(), 0);

    await settings.setHealth('writeMeals', false);
    await meal('Bread', 90);
    expect(await sync.run(), 0);
    await db.close();
  });
}
