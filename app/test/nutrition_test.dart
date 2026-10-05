import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/domain/nutrition.dart';

NutritionInput entry({
  double? servingAmount = 100,
  String? servingUnit = 'g',
  double? amount = 150,
  String? amountUnit = 'g',
  double? kcal = 200,
  double? protein,
  MealStatus status = MealStatus.eaten,
  bool estimate = false,
}) => NutritionInput(
  servingAmount: servingAmount,
  servingUnit: servingUnit,
  amount: amount,
  amountUnit: amountUnit,
  energyKcal: kcal,
  proteinG: protein,
  carbsG: null,
  fatG: null,
  isEstimate: estimate,
  status: status,
);

void main() {
  test('scales per-serving values to the amount eaten', () {
    expect(entry().eaten.energyKcal, 300);
  });

  test('amount in servings multiplies the serving values', () {
    expect(entry(amount: 2, amountUnit: 'serving').eaten.energyKcal, 400);
  });

  test('different units are not converted by guessing', () {
    expect(entry(amountUnit: 'cup').eaten.energyKcal, isNull);
  });

  test('missing values stay missing and are counted', () {
    final t = totalsOf([entry(protein: 10), entry()]);
    expect(t.energyKcal.value, 600);
    expect(t.energyKcal.isComplete, isTrue);
    expect(t.proteinG.value, 15);
    expect(t.proteinG.missing, 1);
    expect(t.carbsG.value, isNull);
    expect(t.carbsG.missing, 2);
  });

  test('zero is a real value, not missing', () {
    final t = totalsOf([entry(kcal: 0)]);
    expect(t.energyKcal.value, 0);
    expect(t.energyKcal.missing, 0);
  });

  test('planned entries are not part of the totals', () {
    final t = totalsOf([entry(status: MealStatus.planned), entry(estimate: true)]);
    expect(t.entries, 1);
    expect(t.energyKcal.value, 300);
    expect(t.estimates, 1);
  });
}
