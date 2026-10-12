import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';

import 'helpers.dart';

void main() {
  test('same as yesterday copies each food as planned, and Undo removes the copies', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = FakeClock(DateTime.utc(2026, 3, 3, 7));
    final repo = MealRepository(db, clock.call);
    await repo.addEntry(
      day: '2026-03-02',
      slotId: 'slot-lunch',
      food: const FoodValues(name: 'Dal', servingAmount: 100, servingUnit: 'g', proteinG: 9),
      amount: 200,
      amountUnit: 'g',
      status: MealStatus.eaten,
    );
    await repo.addEntry(
      day: '2026-03-02',
      slotId: 'slot-dinner',
      food: const FoodValues(name: 'Roti', servingAmount: 1, servingUnit: 'piece'),
      amount: 2,
      amountUnit: 'piece',
      status: MealStatus.eaten,
    );

    final ids = await repo.copyDayAsPlanned('2026-03-02', '2026-03-03');
    expect(ids, hasLength(2));
    final copied = await repo.entriesInRange('2026-03-03', '2026-03-03');
    expect(copied.map((e) => e.name), ['Dal', 'Roti']);
    expect(
      copied.every((e) => e.status == MealStatus.planned && e.eatenAt == null),
      isTrue,
      reason: 'Nothing is marked eaten ahead of time',
    );
    final dal = copied.first;
    expect((dal.slotId, dal.amount, dal.amountUnit, dal.proteinG), ('slot-lunch', 200.0, 'g', 9.0));
    expect(dal.energyKcal, isNull, reason: 'A missing value stays missing');
    expect(await repo.entriesInRange('2026-03-02', '2026-03-02'), hasLength(2), reason: 'The day before is unchanged');

    await repo.deleteEntries(ids);
    expect(await repo.entriesInRange('2026-03-03', '2026-03-03'), isEmpty);
  });

  test('recent foods are newest first, one for each name and brand', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = FakeClock(DateTime.utc(2026, 3, 3, 7));
    final repo = MealRepository(db, clock.call);
    Future<void> add(String name, {String? brand, double amount = 1}) async {
      clock.advance(const Duration(minutes: 1));
      await repo.addEntry(
        day: '2026-03-03',
        slotId: 'slot-lunch',
        food: FoodValues(name: name, brand: brand, servingAmount: 1, servingUnit: 'piece'),
        amount: amount,
        amountUnit: 'piece',
        status: MealStatus.eaten,
      );
    }

    await add('Roti', amount: 2);
    await add('Dal');
    await add('roti', amount: 3);
    await add('Whey', brand: 'A');
    await add('Whey', brand: 'B');
    final recent = await repo.watchRecentFoods().first;
    expect(recent.map((e) => '${e.name} ${e.brand ?? ''}'.trim()), ['Whey B', 'Whey A', 'roti', 'Dal']);
    expect(recent[2].amount, 3, reason: 'The last amount used is offered again');
    expect(await repo.watchRecentFoods(limit: 2).first, hasLength(2));
  });
}
