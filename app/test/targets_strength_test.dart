import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/domain/nutrition.dart';
import 'package:reparc/domain/strength.dart';
import 'package:reparc/domain/targets.dart';

void main() {
  group('targets', () {
    test('Mifflin-St Jeor resting energy matches the published equation', () {
      expect(restingEnergy(sex: Sex.male, ageYears: 30, heightCm: 180, weightKg: 80), 1780);
      expect(restingEnergy(sex: Sex.female, ageYears: 25, heightCm: 165, weightKg: 60), closeTo(1345.25, 1e-9));
    });

    test('full profile gives every target with its rule', () {
      const p = Profile(
        sex: Sex.male,
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        activity: Activity.moderate,
        goal: BodyGoal.maintain,
      );
      final t = {for (final x in dailyTargets(p)) x.nutrient: x};
      expect(t[Nutrient.energy]!.amount, 2760); // 1780 × 1.55 = 2759 → 2760
      expect(t[Nutrient.protein]!.amount, 130); // 80 × 1.6 = 128 → 130
      expect(t[Nutrient.fat]!.amount, 75); // 2760 × 25% / 9 = 76.7 → 75
      expect(t[Nutrient.carbs]!.amount, 390); // (2760 − 520 − 675) / 4 = 391 → 390
      expect(t[Nutrient.fiber]!.amount, 39); // 2.76 × 14 = 38.6 → 39
      expect(t[Nutrient.sugar]!.isLimit, isTrue);
      expect(t[Nutrient.sodium]!.amount, 2000);
      for (final x in t.values) {
        expect(x.source, isNotEmpty);
        expect(x.rule, isNotEmpty);
      }
    });

    test('weight alone gives only protein; vegan adds 0.2 g/kg; user ratio wins', () {
      expect(dailyTargets(const Profile()), isEmpty);
      final only = dailyTargets(const Profile(weightKg: 70, goal: BodyGoal.gain));
      expect(only.single.nutrient, Nutrient.protein);
      expect(only.single.amount, 125); // 70 × 1.8 = 126 → 125
      expect(proteinRatio(const Profile(goal: BodyGoal.gain, diet: Diet.vegan)), closeTo(2.0, 1e-9));
      expect(proteinRatio(const Profile(goal: BodyGoal.lose, proteinPerKg: 1.65)), 1.65);
    });

    test('losing fat lowers energy by 20%', () {
      const base = Profile(
        sex: Sex.female,
        ageYears: 25,
        heightCm: 165,
        weightKg: 60,
        activity: Activity.sedentary,
        goal: BodyGoal.lose,
      );
      final e = dailyTargets(base).firstWhere((t) => t.nutrient == Nutrient.energy).amount;
      expect(e, 1290); // 1345.25 × 1.2 × 0.8 = 1291.4 → 1290
    });

    test('diet rules', () {
      expect(Diet.vegan.allows('dairy'), isFalse);
      expect(Diet.vegetarian.allows('egg'), isFalse);
      expect(Diet.eggetarian.allows('egg'), isTrue);
      expect(Diet.eggetarian.allows('fish'), isFalse);
      expect(Diet.nonVeg.allows('meat'), isTrue);
    });

    test('profile round-trips through settings text', () {
      const p = Profile(sex: Sex.female, ageYears: 40, heightCm: 170.5, weightKg: 64.2, diet: Diet.vegan);
      final back = Profile.fromMap({
        for (final e in p.toMap().entries)
          if (e.value != null) e.key: e.value!,
      });
      expect(back.sex, Sex.female);
      expect(back.heightCm, 170.5);
      expect(back.weightKg, 64.2);
      expect(back.diet, Diet.vegan);
      expect(back.goal, isNull);
    });
  });

  group('strength', () {
    test('one-rep max: mean of Epley and Brzycki', () {
      // Epley 100 × (1 + 5/30) = 116.67. Brzycki 100 × 36/32 = 112.5.
      expect(estimateOneRepMax(100, 5), closeTo(114.583, 0.001));
      expect(estimateOneRepMax(100, 1), 100);
      expect(estimateOneRepMax(0, 5), isNull);
      expect(estimateOneRepMax(100, 0), isNull);
    });

    test('reps in reserve count as extra reps', () {
      expect(estimateOneRepMax(80, 8, rir: 2), estimateOneRepMax(80, 10));
    });

    test('load for reps is the inverse of the estimate', () {
      for (var r = 1; r <= 15; r++) {
        final orm = estimateOneRepMax(97.5, r)!;
        expect(loadForReps(orm, r), closeTo(97.5, 1e-9));
      }
    });

    test('rounding never goes heavier', () {
      expect(roundDownToStep(61.9, 2.5), 60);
      expect(roundDownToStep(62.5, 2.5), 62.5);
      expect(roundDownToStep(137, 5), 135);
    });

    test('first test weight scales by level and sex', () {
      expect(firstTestWeight(lift: TestLift.squat, level: Experience.beginner, bodyWeight: 80, female: false), 40);
      expect(
        firstTestWeight(lift: TestLift.bench, level: Experience.intermediate, bodyWeight: 60, female: true),
        closeTo(27, 1e-9), // 60 × 0.75 × 0.6
      );
      expect(adjustAfterTest(0), 0.95);
      expect(adjustAfterTest(2), 1.0);
      expect(adjustAfterTest(5), 1.05);
      expect(adjustAfterTest(8), 1.10);
    });

    test('double progression', () {
      final up = nextSessionSuggestion(
        [const DoneSet(60, 12), const DoneSet(60, 12)],
        low: 8,
        high: 12,
        increment: 2.5,
      )!;
      expect(up.step, NextStep.addLoad);
      expect(up.load, 62.5);
      final reps = nextSessionSuggestion(
        [const DoneSet(60, 12), const DoneSet(60, 10)],
        low: 8,
        high: 12,
        increment: 2.5,
      )!;
      expect(reps.step, NextStep.addReps);
      expect(reps.load, 60);
      final down = nextSessionSuggestion(
        [const DoneSet(60, 9), const DoneSet(60, 6)],
        low: 8,
        high: 12,
        increment: 2.5,
      )!;
      expect(down.step, NextStep.lighten);
      expect(down.load, 55); // 57 rounded down to 2.5
      expect(nextSessionSuggestion(const [], low: 8, high: 12, increment: 2.5), isNull);
    });
  });
}
