import '../data/models.dart';

/// Factor that converts per-serving values to the amount eaten.
///
/// Returns null when the app cannot convert without guessing. For example,
/// the serving is "100 g" and the amount is "1 cup".
double? servingFactor({
  required double? servingAmount,
  required String? servingUnit,
  required double? amount,
  required String? amountUnit,
}) {
  if (amount == null || amountUnit == null) return null;
  if (amountUnit == 'serving') return amount;
  if (servingAmount == null || servingAmount <= 0 || servingUnit == null) return null;
  if (servingUnit != amountUnit) return null;
  return amount / servingAmount;
}

double? scaled(double? perServing, double? factor) => perServing == null || factor == null ? null : perServing * factor;

/// The nutrients the app records. Grams, except energy (kcal) and sodium (mg).
enum Nutrient {
  energy('Energy', 'kcal'),
  protein('Protein', 'g'),
  carbs('Carbs', 'g'),
  fiber('Fibre', 'g'),
  fat('Fat', 'g'),
  sugar('Sugar', 'g'),
  sodium('Sodium', 'mg');

  const Nutrient(this.label, this.unit);
  final String label;
  final String unit;
}

/// One nutrient total over several entries.
///
/// [missing] counts entries that have no value for this nutrient. The UI
/// shows them so a partial total is not read as a full total.
class NutrientTotal {
  const NutrientTotal(this.value, this.counted, this.missing);

  /// Sum of known values, or null when no entry has a value.
  final double? value;
  final int counted;
  final int missing;

  bool get isComplete => missing == 0 && counted > 0;
}

class NutritionTotals {
  const NutritionTotals({
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = const NutrientTotal(null, 0, 0),
    this.sugarG = const NutrientTotal(null, 0, 0),
    this.sodiumMg = const NutrientTotal(null, 0, 0),
    required this.entries,
    required this.estimates,
  });

  final NutrientTotal energyKcal;
  final NutrientTotal proteinG;
  final NutrientTotal carbsG;
  final NutrientTotal fatG;
  final NutrientTotal fiberG;
  final NutrientTotal sugarG;
  final NutrientTotal sodiumMg;
  final int entries;

  /// Entries with values marked as estimates.
  final int estimates;

  NutrientTotal of(Nutrient n) => switch (n) {
    Nutrient.energy => energyKcal,
    Nutrient.protein => proteinG,
    Nutrient.carbs => carbsG,
    Nutrient.fiber => fiberG,
    Nutrient.fat => fatG,
    Nutrient.sugar => sugarG,
    Nutrient.sodium => sodiumMg,
  };
}

/// Values of one entry for the amount eaten.
class EntryNutrients {
  const EntryNutrients(
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG, [
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
  ]);
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
}

/// Minimal view of a meal entry for calculations.
class NutritionInput {
  const NutritionInput({
    required this.servingAmount,
    required this.servingUnit,
    required this.amount,
    required this.amountUnit,
    required this.energyKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    required this.isEstimate,
    required this.status,
  });

  final double? servingAmount;
  final String? servingUnit;
  final double? amount;
  final String? amountUnit;
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final bool isEstimate;
  final MealStatus status;

  EntryNutrients get eaten {
    final f = servingFactor(
      servingAmount: servingAmount,
      servingUnit: servingUnit,
      amount: amount,
      amountUnit: amountUnit,
    );
    return EntryNutrients(
      scaled(energyKcal, f),
      scaled(proteinG, f),
      scaled(carbsG, f),
      scaled(fatG, f),
      scaled(fiberG, f),
      scaled(sugarG, f),
      scaled(sodiumMg, f),
    );
  }
}

/// Totals for entries the user marked as eaten. Planned entries are not
/// part of the food log (handbook 5.6).
NutritionTotals totalsOf(Iterable<NutritionInput> all) => _totals(all.where((e) => e.status == MealStatus.eaten));

/// Totals for planned entries only. Used to show what a plan would add.
NutritionTotals plannedTotalsOf(Iterable<NutritionInput> all) =>
    _totals(all.where((e) => e.status == MealStatus.planned));

NutritionTotals _totals(Iterable<NutritionInput> picked) {
  final list = picked.toList();
  final values = list.map((e) => e.eaten).toList();

  NutrientTotal sum(double? Function(EntryNutrients) pick) {
    double total = 0;
    var counted = 0;
    var missing = 0;
    for (final v in values) {
      final x = pick(v);
      if (x == null) {
        missing++;
      } else {
        total += x;
        counted++;
      }
    }
    return NutrientTotal(counted == 0 ? null : total, counted, missing);
  }

  return NutritionTotals(
    energyKcal: sum((v) => v.energyKcal),
    proteinG: sum((v) => v.proteinG),
    carbsG: sum((v) => v.carbsG),
    fatG: sum((v) => v.fatG),
    fiberG: sum((v) => v.fiberG),
    sugarG: sum((v) => v.sugarG),
    sodiumMg: sum((v) => v.sodiumMg),
    entries: list.length,
    estimates: list.where((e) => e.isEstimate).length,
  );
}
