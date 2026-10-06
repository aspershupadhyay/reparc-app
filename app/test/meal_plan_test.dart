import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/domain/meal_plan.dart';
import 'package:reparc/domain/nutrition.dart';
import 'package:reparc/domain/targets.dart';

void main() {
  final lib = FoodLibrary.parse(File('assets/foods/foods.json').readAsStringSync());

  test('food values match USDA and missing stays missing', () {
    final chicken = lib.byId['chicken-breast']!;
    expect(chicken.fdcId, 171477);
    expect(chicken.valueFor(Nutrient.energy, 150), closeTo(247.5, 1e-9)); // 165 kcal/100 g
    expect(chicken.valueFor(Nutrient.protein, 150), closeTo(46.53, 1e-9));
    expect(lib.byId['shrimp']!.valueFor(Nutrient.fiber, 100), isNull);
  });

  test('every meal idea uses known foods', () {
    for (final m in mealIdeas) {
      for (final (id, g) in m.parts) {
        expect(lib.byId[id], isNotNull, reason: '$id in ${m.name}');
        expect(g, greaterThan(0));
      }
    }
  });

  for (final diet in Diet.values) {
    test('${diet.name}: every slot has an idea and only allowed foods', () {
      for (var seed = 0; seed < 7; seed++) {
        final plan = planDay(lib: lib, diet: diet, energy: 2400, protein: 150, seed: seed);
        expect(plan.meals.length, greaterThanOrEqualTo(4));
        for (final m in plan.meals) {
          for (final p in m.parts) {
            expect(diet.allows(p.food.diet), isTrue, reason: '${p.food.id} in ${diet.name}');
          }
        }
        // Lands near the energy target and reaches protein.
        expect(plan.total(Nutrient.energy)!, inInclusiveRange(2400 * 0.8, 2400 * 1.25));
        expect(plan.total(Nutrient.protein)!, greaterThanOrEqualTo(150 * 0.95 - 1));
      }
    });
  }

  test('totals are the sum of the parts', () {
    final plan = planDay(lib: lib, diet: Diet.nonVeg, energy: 2000, seed: 3);
    var kcal = 0.0;
    for (final m in plan.meals) {
      for (final p in m.parts) {
        kcal += p.food.per100g['kcal']! * p.grams / 100;
      }
    }
    expect(plan.total(Nutrient.energy), closeTo(kcal, 1e-6));
  });
}
