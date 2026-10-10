import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../domain/nutrition.dart';
import 'database.dart';
import 'models.dart';

const _uuid = Uuid();

extension MealEntryNutrition on MealEntry {
  NutritionInput get input => NutritionInput(
    servingAmount: servingAmount,
    servingUnit: servingUnit,
    amount: amount,
    amountUnit: amountUnit,
    energyKcal: energyKcal,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
    fiberG: fiberG,
    sugarG: sugarG,
    sodiumMg: sodiumMg,
    isEstimate: isEstimate,
    status: status,
  );
}

/// Values the user enters for a food. Null means not recorded.
class FoodValues {
  const FoodValues({
    required this.name,
    this.brand,
    this.servingAmount,
    this.servingUnit,
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.isEstimate = false,
    this.source = sourceManual,
    this.note,
  });

  final String name;
  final String? brand;
  final double? servingAmount;
  final String? servingUnit;
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final bool isEstimate;
  final String source;
  final String? note;

  factory FoodValues.fromFood(Food f) => FoodValues(
    name: f.name,
    brand: f.brand,
    servingAmount: f.servingAmount,
    servingUnit: f.servingUnit,
    energyKcal: f.energyKcal,
    proteinG: f.proteinG,
    carbsG: f.carbsG,
    fatG: f.fatG,
    fiberG: f.fiberG,
    sugarG: f.sugarG,
    sodiumMg: f.sodiumMg,
    isEstimate: f.isEstimate,
    source: f.source,
    note: f.note,
  );

  factory FoodValues.fromEntry(MealEntry e) => FoodValues(
    name: e.name,
    brand: e.brand,
    servingAmount: e.servingAmount,
    servingUnit: e.servingUnit,
    energyKcal: e.energyKcal,
    proteinG: e.proteinG,
    carbsG: e.carbsG,
    fatG: e.fatG,
    fiberG: e.fiberG,
    sugarG: e.sugarG,
    sodiumMg: e.sodiumMg,
    isEstimate: e.isEstimate,
    source: e.source,
    note: e.note,
  );
}

class MealRepository {
  MealRepository(this.db, this.clock);

  final AppDatabase db;
  final Clock clock;

  DateTime get _now => clock().toUtc();

  // ------------------------------------------------------------------ Slots

  Stream<List<MealSlot>> watchSlots() =>
      (db.select(db.mealSlots)
            ..where((s) => s.archived.equals(false))
            ..orderBy([(s) => OrderingTerm.asc(s.position)]))
          .watch();

  Future<void> addSlot(String name, {int? usualMinute}) async {
    final maxPos = db.mealSlots.position.max();
    final row = await (db.selectOnly(db.mealSlots)..addColumns([maxPos])).getSingle();
    final now = _now;
    await db
        .into(db.mealSlots)
        .insert(
          MealSlotsCompanion.insert(
            id: _uuid.v4(),
            name: name.trim(),
            position: (row.read(maxPos) ?? -1) + 1,
            usualMinute: Value(usualMinute),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> updateSlot(String id, {required String name, int? usualMinute}) =>
      (db.update(db.mealSlots)..where((s) => s.id.equals(id))).write(
        MealSlotsCompanion(name: Value(name.trim()), usualMinute: Value(usualMinute), updatedAt: Value(_now)),
      );

  /// Hides a slot from new days. Saved entries in it stay visible.
  Future<void> archiveSlot(String id) => (db.update(
    db.mealSlots,
  )..where((s) => s.id.equals(id))).write(MealSlotsCompanion(archived: const Value(true), updatedAt: Value(_now)));

  /// All slots, including archived ones that hold entries.
  Future<List<MealSlot>> allSlots() => (db.select(db.mealSlots)..orderBy([(s) => OrderingTerm.asc(s.position)])).get();

  // ---------------------------------------------------------------- Entries

  Stream<List<MealEntry>> watchDay(String day) =>
      (db.select(db.mealEntries)
            ..where((e) => e.day.equals(day))
            ..orderBy([(e) => OrderingTerm.asc(e.createdAt)]))
          .watch();

  Stream<List<MealEntry>> watchRange(String fromDay, String toDay) =>
      (db.select(db.mealEntries)
            ..where((e) => e.day.isBetweenValues(fromDay, toDay))
            ..orderBy([(e) => OrderingTerm.asc(e.day), (e) => OrderingTerm.asc(e.createdAt)]))
          .watch();

  Future<List<MealEntry>> entriesInRange(String fromDay, String toDay) =>
      (db.select(db.mealEntries)
            ..where((e) => e.day.isBetweenValues(fromDay, toDay))
            ..orderBy([(e) => OrderingTerm.asc(e.day), (e) => OrderingTerm.asc(e.createdAt)]))
          .get();

  Future<String> addEntry({
    required String day,
    required String slotId,
    required FoodValues food,
    required double amount,
    required String amountUnit,
    required MealStatus status,
    String? foodId,
  }) async {
    final id = _uuid.v4();
    final local = clock();
    final now = local.toUtc();
    await db
        .into(db.mealEntries)
        .insert(
          MealEntriesCompanion.insert(
            id: id,
            day: day,
            slotId: slotId,
            foodId: Value(foodId),
            name: food.name.trim(),
            brand: Value(_clean(food.brand)),
            servingAmount: Value(food.servingAmount),
            servingUnit: Value(food.servingUnit),
            energyKcal: Value(food.energyKcal),
            proteinG: Value(food.proteinG),
            carbsG: Value(food.carbsG),
            fatG: Value(food.fatG),
            fiberG: Value(food.fiberG),
            sugarG: Value(food.sugarG),
            sodiumMg: Value(food.sodiumMg),
            amount: Value(amount),
            amountUnit: Value(amountUnit),
            isEstimate: Value(food.isEstimate),
            source: food.source,
            sourceCheckedAt: Value(now),
            status: status,
            eatenAt: Value(status == MealStatus.eaten ? now : null),
            timeZoneName: local.timeZoneName,
            note: Value(_clean(food.note)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updateEntry(
    String id, {
    required String slotId,
    required FoodValues food,
    required double amount,
    required String amountUnit,
  }) => (db.update(db.mealEntries)..where((e) => e.id.equals(id))).write(
    MealEntriesCompanion(
      slotId: Value(slotId),
      name: Value(food.name.trim()),
      brand: Value(_clean(food.brand)),
      servingAmount: Value(food.servingAmount),
      servingUnit: Value(food.servingUnit),
      energyKcal: Value(food.energyKcal),
      proteinG: Value(food.proteinG),
      carbsG: Value(food.carbsG),
      fatG: Value(food.fatG),
      fiberG: Value(food.fiberG),
      sugarG: Value(food.sugarG),
      sodiumMg: Value(food.sodiumMg),
      amount: Value(amount),
      amountUnit: Value(amountUnit),
      isEstimate: Value(food.isEstimate),
      source: Value(food.source),
      note: Value(_clean(food.note)),
      updatedAt: Value(_now),
    ),
  );

  /// "Same as yesterday" (launch review Block 3): copies every food of
  /// [fromDay] into [toDay] as planned, with the same meal, amount, values,
  /// and source. The user ticks each food when it is eaten, so nothing is
  /// marked eaten ahead of time. Returns the new entry IDs, for Undo.
  Future<List<String>> copyDayAsPlanned(String fromDay, String toDay) => db.transaction(() async {
    final from = await entriesInRange(fromDay, fromDay);
    final local = clock();
    final now = local.toUtc();
    final ids = <String>[];
    for (final e in from) {
      final id = _uuid.v4();
      await db
          .into(db.mealEntries)
          .insert(
            e.copyWith(
              id: id,
              day: toDay,
              status: MealStatus.planned,
              eatenAt: const Value(null),
              timeZoneName: local.timeZoneName,
              createdAt: now,
              updatedAt: now,
            ),
          );
      ids.add(id);
    }
    return ids;
  });

  /// Removes the entries made by [copyDayAsPlanned] (Undo).
  Future<void> deleteEntries(List<String> ids) => (db.delete(db.mealEntries)..where((e) => e.id.isIn(ids))).go();

  /// Marks a planned entry as eaten, or an eaten entry as planned.
  Future<void> setStatus(String id, MealStatus status) =>
      (db.update(db.mealEntries)..where((e) => e.id.equals(id))).write(
        MealEntriesCompanion(
          status: Value(status),
          eatenAt: Value(status == MealStatus.eaten ? _now : null),
          updatedAt: Value(_now),
        ),
      );

  Future<MealEntry?> deleteEntry(String id) => db.transaction(() async {
    final e = await (db.select(db.mealEntries)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (e != null) await (db.delete(db.mealEntries)..where((x) => x.id.equals(id))).go();
    return e;
  });

  Future<void> restoreEntry(MealEntry e) => db.into(db.mealEntries).insert(e);

  // ------------------------------------------------------------------ Foods

  Stream<List<Food>> watchFoods() => (db.select(db.foods)..orderBy([(f) => OrderingTerm.asc(f.name.lower())])).watch();

  Future<String> saveFood(FoodValues v, {String? id}) async {
    final now = _now;
    final foodId = id ?? _uuid.v4();
    await db
        .into(db.foods)
        .insertOnConflictUpdate(
          FoodsCompanion.insert(
            id: foodId,
            name: v.name.trim(),
            brand: Value(_clean(v.brand)),
            servingAmount: Value(v.servingAmount),
            servingUnit: Value(v.servingUnit),
            energyKcal: Value(v.energyKcal),
            proteinG: Value(v.proteinG),
            carbsG: Value(v.carbsG),
            fatG: Value(v.fatG),
            fiberG: Value(v.fiberG),
            sugarG: Value(v.sugarG),
            sodiumMg: Value(v.sodiumMg),
            isEstimate: Value(v.isEstimate),
            source: v.source,
            sourceCheckedAt: Value(now),
            note: Value(_clean(v.note)),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return foodId;
  }

  Future<void> deleteFood(String id) => (db.delete(db.foods)..where((f) => f.id.equals(id))).go();
}

String? _clean(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}
