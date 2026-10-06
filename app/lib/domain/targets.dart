/// Daily nutrition targets from a user's own profile.
///
/// Every number here is a general guide for healthy adults, not medical
/// advice. Each target carries the rule and the source it came from, so the
/// app and any AI client can show why it exists (handbook 5.5 and 10.7).
library;

import 'dart:math' as math;

import 'nutrition.dart';

enum Sex {
  male('Male'),
  female('Female');

  const Sex(this.label);
  final String label;
}

enum Activity {
  sedentary('Mostly sitting', 'Desk job, little walking', 1.2),
  light('Light', 'Train 1–3 days a week', 1.375),
  moderate('Moderate', 'Train 3–5 days a week', 1.55),
  high('High', 'Train 6–7 days a week', 1.725),
  athlete('Very high', 'Hard training and a physical job', 1.9);

  const Activity(this.label, this.hint, this.factor);
  final String label;
  final String hint;

  /// Multiplier on resting energy (Mifflin-St Jeor activity factors).
  final double factor;
}

enum BodyGoal {
  lose('Lose fat', 0.80),
  maintain('Stay the same', 1.0),
  gain('Build muscle', 1.10);

  const BodyGoal(this.label, this.energyFactor);
  final String label;

  /// Energy compared with maintenance: 20% less, the same, or 10% more.
  final double energyFactor;

  /// Default protein in grams per kg of body weight.
  double get proteinPerKg => switch (this) {
    BodyGoal.lose => 2.0,
    BodyGoal.maintain => 1.6,
    BodyGoal.gain => 1.8,
  };
}

enum Diet {
  nonVeg('Eat everything', 'Meat, fish, eggs, dairy, and plants'),
  eggetarian('Vegetarian + eggs', 'No meat or fish. Eggs and dairy are fine'),
  vegetarian('Vegetarian', 'No meat, fish, or eggs. Dairy is fine'),
  vegan('Vegan', 'Plants only. No meat, fish, eggs, or dairy');

  const Diet(this.label, this.hint);
  final String label;
  final String hint;

  /// True when this diet allows a food tagged [tag].
  bool allows(String tag) => switch (this) {
    Diet.nonVeg => true,
    Diet.eggetarian => tag != 'meat' && tag != 'fish',
    Diet.vegetarian => tag == 'plant' || tag == 'dairy',
    Diet.vegan => tag == 'plant',
  };
}

/// What the user told the app about themselves. Every field is optional.
class Profile {
  const Profile({
    this.sex,
    this.ageYears,
    this.heightCm,
    this.weightKg,
    this.activity,
    this.goal,
    this.diet,
    this.proteinPerKg,
  });

  final Sex? sex;
  final int? ageYears;
  final double? heightCm;
  final double? weightKg;
  final Activity? activity;
  final BodyGoal? goal;
  final Diet? diet;

  /// User's own protein ratio. Null uses the goal's default.
  final double? proteinPerKg;

  /// True when there is enough to calculate energy.
  bool get isComplete =>
      sex != null && ageYears != null && heightCm != null && weightKg != null && activity != null && goal != null;

  Map<String, String?> toMap() => {
    'sex': sex?.name,
    'ageYears': ageYears?.toString(),
    'heightCm': heightCm?.toString(),
    'weightKg': weightKg?.toString(),
    'activity': activity?.name,
    'goal': goal?.name,
    'diet': diet?.name,
    'proteinPerKg': proteinPerKg?.toString(),
  };

  static Profile fromMap(Map<String, String> m) => Profile(
    sex: Sex.values.asNameMap()[m['sex']],
    ageYears: int.tryParse(m['ageYears'] ?? ''),
    heightCm: double.tryParse(m['heightCm'] ?? ''),
    weightKg: double.tryParse(m['weightKg'] ?? ''),
    activity: Activity.values.asNameMap()[m['activity']],
    goal: BodyGoal.values.asNameMap()[m['goal']],
    diet: Diet.values.asNameMap()[m['diet']],
    proteinPerKg: double.tryParse(m['proteinPerKg'] ?? ''),
  );
}

/// One target: an amount to reach, or a limit to stay under.
class Target {
  const Target(this.nutrient, this.amount, {required this.rule, required this.source, this.isLimit = false});
  final Nutrient nutrient;
  final double amount;

  /// Plain words: how the number was worked out.
  final String rule;
  final String source;

  /// True for "stay under" values (sugar, salt).
  final bool isLimit;

  /// Share reached, 0 or more. Null when nothing is logged.
  double? progress(double? eaten) => eaten == null || amount <= 0 ? null : eaten / amount;
}

/// Resting energy (kcal/day) with the Mifflin-St Jeor equation.
///
/// Source: Mifflin MD, St Jeor ST, et al. Am J Clin Nutr. 1990;51(2):241-7.
double restingEnergy({required Sex sex, required int ageYears, required double heightCm, required double weightKg}) =>
    10 * weightKg + 6.25 * heightCm - 5 * ageYears + (sex == Sex.male ? 5 : -161);

/// Daily energy to keep weight steady: resting energy × activity factor.
double maintenanceEnergy(Profile p) =>
    restingEnergy(sex: p.sex!, ageYears: p.ageYears!, heightCm: p.heightCm!, weightKg: p.weightKg!) *
    p.activity!.factor;

const proteinSource =
    'Morton RW et al., Br J Sports Med 2018 (benefit levels off near 1.6 g/kg); '
    'Jäger R et al., ISSN position stand 2017 (1.4–2.0 g/kg; more when eating less).';
const fiberSource = 'Dietary Guidelines for Americans 2020–2025: 14 g per 1,000 kcal.';
const carbSource = 'Energy left after protein and fat. Dietary Reference Intakes (AMDR): 45–65% of energy.';
const fatSource = 'Dietary Reference Intakes (AMDR): 20–35% of energy from fat.';
const sugarSource = 'WHO 2015 guideline: free sugars under 10% of energy.';
const sodiumSource = 'WHO 2023: under 2,000 mg sodium a day (about 5 g salt).';
const energySource = 'Mifflin-St Jeor equation × activity factor.';

/// Protein ratio the app uses for this profile, in g per kg.
///
/// Plant proteins digest a little less well, so a vegan diet adds 0.2 g/kg
/// (ISSN 2017 notes the gap; the number is a rounded safety margin).
double proteinRatio(Profile p) {
  if (p.proteinPerKg != null) return p.proteinPerKg!;
  final base = (p.goal ?? BodyGoal.maintain).proteinPerKg;
  return p.diet == Diet.vegan ? base + 0.2 : base;
}

/// Daily targets, or an empty list when the profile is not complete.
///
/// Protein needs only body weight. Energy and the rest need the full profile.
List<Target> dailyTargets(Profile p) {
  final out = <Target>[];
  final w = p.weightKg;
  if (w == null || w <= 0) return out;
  final ratio = proteinRatio(p);
  final protein = _round(w * ratio, 5);
  out.add(
    Target(
      Nutrient.protein,
      protein,
      rule: '${_fmt(ratio)} g for each kg of body weight (${_fmt(w)} kg)',
      source: proteinSource,
    ),
  );
  if (!p.isComplete) return out;

  final energy = _round(maintenanceEnergy(p) * p.goal!.energyFactor, 10);
  final goalWord = switch (p.goal!) {
    BodyGoal.lose => '20% under',
    BodyGoal.maintain => 'equal to',
    BodyGoal.gain => '10% over',
  };
  out.insert(
    0,
    Target(Nutrient.energy, energy, rule: '$goalWord the energy you burn in a day', source: energySource),
  );
  final fat = math.max(_round(energy * 0.25 / 9, 5), _round(w * 0.6, 5));
  final carbs = math.max(0.0, _round((energy - protein * 4 - fat * 9) / 4, 5));
  out.add(Target(Nutrient.carbs, carbs, rule: 'The energy left after protein and fat', source: carbSource));
  out.add(
    Target(Nutrient.fiber, _round(energy / 1000 * 14, 1), rule: '14 g for every 1,000 kcal', source: fiberSource),
  );
  out.add(Target(Nutrient.fat, fat, rule: 'About 25% of your energy', source: fatSource));
  out.add(
    Target(
      Nutrient.sugar,
      _round(energy * 0.10 / 4, 5),
      rule: 'Under 10% of energy. Labels count fruit and milk sugar too, so treat this as a loose guide',
      source: sugarSource,
      isLimit: true,
    ),
  );
  out.add(
    const Target(Nutrient.sodium, 2000, rule: 'Under 2,000 mg a day', source: sodiumSource, isLimit: true),
  );
  return out;
}

double _round(double v, double step) => (v / step).round() * step;

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
