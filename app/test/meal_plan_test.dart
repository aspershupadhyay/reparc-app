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

  test('foods by country: India foods carry portions and an honest source', () {
    final india = lib.foods.where((f) => f.countries.contains('IN')).toList();
    expect(india.length, greaterThan(80));
    expect(lib.foods.map((f) => f.id).toSet(), hasLength(lib.foods.length), reason: 'IDs are unique');
    for (final f in lib.foods) {
      expect(f.per100g['kcal'], isNotNull, reason: f.id);
      expect(f.per100g['protein'], isNotNull, reason: f.id);
    }
    final roti = lib.byId['in-roti-medium']!;
    expect(roti.allPortions.first, (label: '1 roti (7 in)', grams: 40.0));
    expect(roti.source, 'USDA FoodData Central, FDC ID 2707713');
    final paneer = lib.byId['in-paneer']!;
    expect(paneer.estimate, isTrue);
    expect(paneer.source, startsWith('Estimate: Value from queso fresco'));
    expect(paneer.per100g['sodium'], isNull, reason: 'The stand-in is salted; paneer is not');
    final poha = lib.byId['in-poha']!;
    expect((poha.estimate, poha.fdcId), (true, null));
    expect(poha.source, 'Estimate: Recipe of USDA foods');
    expect(poha.per100g['sodium'], isNull, reason: 'Recipes add no salt, so sodium is unknown');
  });

  test('food search puts the user\'s country first, and still finds every food', () {
    final inIndia = lib.search('roti', country: 'IN');
    expect(inIndia.first.id, 'in-roti-medium');
    expect(inIndia.map((f) => f.id), contains('roti'), reason: 'The common roti is still there');
    final elsewhere = lib.search('roti', country: 'US');
    expect(elsewhere.first.id, 'roti', reason: 'Common foods first, then other countries');
    expect(elsewhere.map((f) => f.id), contains('in-roti-medium'));
    expect(
      lib.search('paneer', country: 'US', diet: Diet.vegan),
      isEmpty,
      reason: 'The diet still applies',
    );
    expect(lib.search('  '), isEmpty);
  });

  test('a plan says when fibre is unknown for a food', () {
    for (var seed = 0; seed < 14; seed++) {
      final plan = planDay(lib: lib, diet: Diet.vegan, energy: null, protein: null, seed: seed);
      final unknown = plan.meals.expand((m) => m.parts).any((p) => p.value(Nutrient.fiber) == null);
      expect(plan.notes.any((n) => n.startsWith('Fibre is not known')), unknown);
    }
  });

  test('portion counts read naturally', () {
    expect(countOf(2, '1 roti'), '2 rotis');
    expect(countOf(1, '1 medium'), '1 medium');
    expect(countOf(2, '1 medium'), '2 medium');
    expect(countOf(3, '1 large egg'), '3 large eggs');
    expect(countOf(2, '1 slice'), '2 slices');
    expect(countOf(2, '2 tbsp'), '2 × 2 tbsp');
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
