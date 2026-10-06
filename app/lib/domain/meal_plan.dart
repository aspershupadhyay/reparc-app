/// Food list and day meal plans by diet.
///
/// Food values come from USDA FoodData Central (public domain), per 100 g.
/// The planner picks meal ideas the diet allows and scales the portions to
/// the user's energy target, then tops up protein if it is short. It only
/// proposes: the user reviews the plan and chooses to add it (handbook 5.7).
library;

import 'dart:convert';
import 'dart:math' as math;

import 'nutrition.dart';
import 'targets.dart';

class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.fdcId,
    required this.diet,
    required this.group,
    required this.portionG,
    required this.portion,
    required this.per100g,
  });

  factory FoodItem.fromJson(Map<String, Object?> j) => FoodItem(
    id: j['id'] as String,
    name: j['name'] as String,
    fdcId: (j['fdcId'] as num).toInt(),
    diet: j['diet'] as String,
    group: j['group'] as String,
    portionG: (j['portionG'] as num).toDouble(),
    portion: j['portion'] as String,
    per100g: {
      for (final e in (j['per100g'] as Map).entries) e.key as String: (e.value as num).toDouble(),
    },
  );

  final String id;
  final String name;
  final int fdcId;

  /// plant, dairy, egg, fish, or meat.
  final String diet;
  final String group;
  final double portionG;
  final String portion;

  /// kcal, protein, carbs, fiber, fat, sugar, sodium per 100 g. A missing
  /// key means USDA has no value. It is not zero.
  final Map<String, double> per100g;

  String get source => 'USDA FoodData Central, FDC ID $fdcId';

  double? valueFor(Nutrient n, double grams) {
    final v = per100g[_key(n)];
    return v == null ? null : v * grams / 100;
  }

  /// Protein per 100 kcal. Higher means a leaner protein source.
  double get proteinDensity => (per100g['protein'] ?? 0) / math.max(1, per100g['kcal'] ?? 1) * 100;
}

String _key(Nutrient n) => switch (n) {
  Nutrient.energy => 'kcal',
  Nutrient.protein => 'protein',
  Nutrient.carbs => 'carbs',
  Nutrient.fiber => 'fiber',
  Nutrient.fat => 'fat',
  Nutrient.sugar => 'sugar',
  Nutrient.sodium => 'sodium',
};

class FoodLibrary {
  FoodLibrary(List<FoodItem> foods) : foods = List.unmodifiable(foods), byId = {for (final f in foods) f.id: f};

  factory FoodLibrary.parse(String json) {
    final root = (jsonDecode(json) as Map).cast<String, Object?>();
    return FoodLibrary([for (final f in root['foods'] as List) FoodItem.fromJson((f as Map).cast<String, Object?>())]);
  }

  final List<FoodItem> foods;
  final Map<String, FoodItem> byId;

  List<FoodItem> forDiet(Diet d) => foods.where((f) => d.allows(f.diet)).toList();
}

/// Meal slots the planner fills.
enum MealKind {
  breakfast('Breakfast'),
  lunch('Lunch'),
  snack('Snack'),
  dinner('Dinner');

  const MealKind(this.label);
  final String label;
}

/// A meal idea: foods and grams for one standard portion.
class MealIdea {
  const MealIdea(this.kind, this.name, this.parts);
  final MealKind kind;
  final String name;
  final List<(String foodId, double grams)> parts;

  bool allowedFor(Diet d, FoodLibrary lib) => parts.every((p) => d.allows(lib.byId[p.$1]!.diet));
}

/// Simple meals from common foods. Portions are a starting point; the
/// planner scales them.
const mealIdeas = <MealIdea>[
  // Breakfast
  MealIdea(MealKind.breakfast, 'Oats with Greek yogurt and berries', [
    ('oats', 50),
    ('greek-yogurt', 170),
    ('blueberries', 100),
    ('chia', 10),
  ]),
  MealIdea(MealKind.breakfast, 'Eggs on whole-wheat toast with spinach', [
    ('egg', 150),
    ('bread-wholewheat', 64),
    ('spinach-cooked', 90),
  ]),
  MealIdea(MealKind.breakfast, 'Tofu scramble with toast', [
    ('tofu', 150),
    ('bread-wholewheat', 64),
    ('tomato', 120),
    ('olive-oil', 7),
  ]),
  MealIdea(MealKind.breakfast, 'Oats with soy milk, peanut butter, and banana', [
    ('oats', 60),
    ('soy-milk', 240),
    ('peanut-butter', 16),
    ('banana', 118),
  ]),
  MealIdea(MealKind.breakfast, 'Besan chilla with curd', [('besan', 60), ('onion', 40), ('yogurt-low-fat', 150)]),
  MealIdea(MealKind.breakfast, 'Cottage cheese, fruit, and almonds', [
    ('cottage-cheese', 200),
    ('strawberries', 150),
    ('almonds', 20),
  ]),
  // Lunch
  MealIdea(MealKind.lunch, 'Chicken, rice, and broccoli', [
    ('chicken-breast', 150),
    ('rice-white', 180),
    ('broccoli', 120),
    ('olive-oil', 7),
  ]),
  MealIdea(MealKind.lunch, 'Dal, rice, and salad', [
    ('lentils', 250),
    ('rice-brown', 150),
    ('cucumber', 100),
    ('tomato', 100),
    ('ghee', 5),
  ]),
  MealIdea(MealKind.lunch, 'Rajma with roti and curd', [
    ('kidney-beans', 220),
    ('roti', 80),
    ('yogurt-low-fat', 150),
    ('onion', 50),
  ]),
  MealIdea(MealKind.lunch, 'Chickpea quinoa bowl', [
    ('chickpeas', 160),
    ('quinoa', 185),
    ('red-pepper', 100),
    ('spinach', 30),
    ('olive-oil', 10),
  ]),
  MealIdea(MealKind.lunch, 'Tuna wrap with salad', [
    ('tuna-can', 120),
    ('tortilla-corn', 52),
    ('romaine', 60),
    ('tomato', 100),
    ('avocado', 50),
  ]),
  MealIdea(MealKind.lunch, 'Egg fried rice with peas', [
    ('egg', 100),
    ('rice-brown', 200),
    ('peas', 80),
    ('olive-oil', 7),
  ]),
  // Dinner
  MealIdea(MealKind.dinner, 'Salmon, sweet potato, and green beans', [
    ('salmon', 140),
    ('sweet-potato', 180),
    ('green-beans', 125),
  ]),
  MealIdea(MealKind.dinner, 'Tofu stir-fry with rice', [
    ('tofu', 200),
    ('rice-white', 160),
    ('broccoli', 90),
    ('mushrooms', 70),
    ('olive-oil', 10),
  ]),
  MealIdea(MealKind.dinner, 'Lean beef, potato, and salad', [
    ('beef-mince-90', 130),
    ('potato', 200),
    ('romaine', 60),
    ('carrot', 60),
  ]),
  MealIdea(MealKind.dinner, 'Chana masala with rice', [
    ('chickpeas', 220),
    ('rice-white', 150),
    ('tomato', 120),
    ('onion', 60),
    ('olive-oil', 7),
  ]),
  MealIdea(MealKind.dinner, 'Ricotta (or paneer) with roti and spinach', [
    ('ricotta', 150),
    ('roti', 80),
    ('spinach-cooked', 180),
  ]),
  MealIdea(MealKind.dinner, 'Tempeh, quinoa, and roasted veg', [
    ('tempeh', 150),
    ('quinoa', 150),
    ('cauliflower', 125),
    ('olive-oil', 7),
  ]),
  MealIdea(MealKind.dinner, 'Chicken thigh with lentils and veg', [
    ('chicken-thigh', 140),
    ('lentils', 150),
    ('carrot', 60),
    ('green-beans', 100),
  ]),
  MealIdea(MealKind.dinner, 'Cod with couscous and peas', [
    ('cod', 170),
    ('couscous', 160),
    ('peas', 80),
    ('olive-oil', 7),
  ]),
  // Snacks
  MealIdea(MealKind.snack, 'Greek yogurt and walnuts', [('greek-yogurt', 170), ('walnuts', 15)]),
  MealIdea(MealKind.snack, 'Protein shake and banana', [('whey', 30), ('milk-skim', 240), ('banana', 118)]),
  MealIdea(MealKind.snack, 'Soy protein shake and apple', [('soy-protein', 30), ('soy-milk', 240), ('apple', 180)]),
  MealIdea(MealKind.snack, 'Hummus and carrot sticks', [('hummus', 60), ('carrot', 120)]),
  MealIdea(MealKind.snack, 'Edamame', [('edamame', 155)]),
  MealIdea(MealKind.snack, 'Boiled eggs and an orange', [('egg', 100), ('orange', 130)]),
  MealIdea(MealKind.snack, 'Roasted peanuts and a banana', [('peanuts', 30), ('banana', 118)]),
];

/// Foods counted in whole pieces, so the plan says "2 eggs", not "87 g".
const _wholePieces = {
  'egg',
  'roti',
  'bread-wholewheat',
  'bread-white',
  'tortilla-corn',
  'dates',
  'banana',
  'apple',
  'orange',
};

/// Lean protein foods used to top up a short day, best first.
const _topUps = ['whey', 'greek-yogurt', 'soy-protein', 'cottage-cheese', 'tofu', 'egg-white', 'lentils', 'edamame'];

class PlannedPart {
  const PlannedPart(this.food, this.grams);
  final FoodItem food;
  final double grams;

  double? value(Nutrient n) => food.valueFor(n, grams);

  /// "2 eggs (100 g)" or "180 g".
  String get amountText {
    if (_wholePieces.contains(food.id)) {
      final n = (grams / food.portionG).round();
      return '${countOf(n, food.portion)} (${grams.round()} g)';
    }
    return '${grams.round()} g';
  }
}

/// "2 rotis", "1 medium", "3 large eggs": a count of a "1 …" portion, said
/// the way people say it. Portions that do not start with "1 " keep "n ×".
String countOf(int n, String portion) {
  if (!portion.startsWith('1 ')) return '$n × $portion';
  final unit = portion.substring(2);
  if (n == 1) return '1 $unit';
  // Size words stay as they are ("2 medium").
  if (const {'medium', 'small', 'large'}.contains(unit)) return '$n $unit';
  final words = unit.split(' ');
  final noun = words.last;
  words[words.length - 1] = noun.endsWith('s') || noun.endsWith(')') ? noun : '${noun}s';
  return '$n ${words.join(' ')}';
}

class PlannedMeal {
  const PlannedMeal(this.kind, this.name, this.parts);
  final MealKind kind;
  final String name;
  final List<PlannedPart> parts;

  double? total(Nutrient n) => _sum(parts.map((p) => p.value(n)));
}

class DayPlan {
  const DayPlan(this.meals, this.notes);
  final List<PlannedMeal> meals;

  /// Plain-word notes about how the plan was made and what is short.
  final List<String> notes;

  double? total(Nutrient n) => _sum(meals.map((m) => m.total(n)));
}

double? _sum(Iterable<double?> v) {
  final known = v.whereType<double>().toList();
  return known.isEmpty ? null : known.fold<double>(0, (a, b) => a + b);
}

double _roundPart(String id, double grams, FoodItem f) {
  if (_wholePieces.contains(id)) return math.max(1, (grams / f.portionG).round()) * f.portionG;
  return math.max(5, (grams / 5).round() * 5).toDouble();
}

/// Builds one day of meals for [diet].
///
/// - [energy] scales every portion so the day lands near the target
///   (within 60–160% of the standard portions).
/// - [protein], when the day is short by more than 5%, adds a lean protein
///   top-up as an extra snack.
/// - [seed] rotates the ideas so each day can differ.
DayPlan planDay({
  required FoodLibrary lib,
  required Diet diet,
  double? energy,
  double? protein,
  List<MealKind> slots = MealKind.values,
  int seed = 0,
}) {
  final notes = <String>[];
  final chosen = <MealIdea>[];
  for (final kind in slots) {
    final options = mealIdeas.where((m) => m.kind == kind && m.allowedFor(diet, lib)).toList();
    if (options.isEmpty) {
      notes.add('No ${kind.label.toLowerCase()} idea fits a ${diet.label.toLowerCase()} diet yet.');
      continue;
    }
    chosen.add(options[(seed + kind.index) % options.length]);
  }

  double base(Nutrient n) =>
      chosen.fold(0.0, (a, m) => a + m.parts.fold(0.0, (b, p) => b + (lib.byId[p.$1]!.valueFor(n, p.$2) ?? 0)));

  var factor = 1.0;
  final baseKcal = base(Nutrient.energy);
  if (energy != null && baseKcal > 0) {
    factor = (energy / baseKcal).clamp(0.6, 1.6);
    if (factor != energy / baseKcal) {
      notes.add('Portions reached their limit. The day is ${factor < 1 ? 'above' : 'below'} your energy target.');
    }
  }

  final meals = [
    for (final m in chosen)
      PlannedMeal(m.kind, m.name, [
        for (final (id, g) in m.parts) PlannedPart(lib.byId[id]!, _roundPart(id, g * factor, lib.byId[id]!)),
      ]),
  ];

  if (protein != null) {
    // Up to two lean top-ups, each at most two usual portions.
    final pool = [
      for (final id in _topUps)
        if (lib.byId[id] case final f? when diet.allows(f.diet)) f,
    ];
    for (final pick in pool.take(2)) {
      final have = _sum(meals.map((m) => m.total(Nutrient.protein))) ?? 0;
      final gap = protein - have;
      if (gap <= protein * 0.05) break;
      final per = pick.per100g['protein']! / 100;
      final grams = math.min(gap / per, pick.portionG * 2);
      final part = PlannedPart(pick, _roundPart(pick.id, grams, pick));
      meals.add(PlannedMeal(MealKind.snack, 'Protein top-up: ${pick.name.toLowerCase()}', [part]));
      notes.add('Added ${part.amountText} of ${pick.name.toLowerCase()} to close a ${gap.round()} g protein gap.');
    }
    final left = protein - (_sum(meals.map((m) => m.total(Nutrient.protein))) ?? 0);
    if (left > protein * 0.05) notes.add('Still ${left.round()} g short of your protein target.');
  }
  final noFiber = {
    for (final m in meals)
      for (final part in m.parts)
        if (part.value(Nutrient.fiber) == null) part.food.name.toLowerCase(),
  };
  if (noFiber.isNotEmpty) notes.add('Fibre is not known for ${noFiber.join(', ')}. The fibre total leaves it out.');
  return DayPlan(meals, notes);
}
