/// Strength maths: estimated one-rep max, working weights, first test
/// weights, and the next-session suggestion.
///
/// These are estimates. They are less accurate above about 10 reps and they
/// vary between people. The app labels them as estimates.
library;

import 'dart:math' as math;

/// Estimated one-rep max from one set.
///
/// Uses the mean of the Epley and Brzycki formulas, which agree closely up
/// to 10 reps. [rir] (reps in reserve) adds the reps the lifter could still
/// do, so a hard set of 8 with 2 left counts as 10.
///
/// Sources: Epley B. Poundage chart, 1985. Brzycki M. JOPERD 1993;64(1):88-90.
/// Helms ER et al. Strength Cond J 2016 (reps in reserve).
double? estimateOneRepMax(double load, int reps, {int rir = 0}) {
  if (load <= 0 || reps <= 0 || rir < 0) return null;
  final r = reps + rir;
  if (r == 1) return load;
  if (r >= 37) return null;
  final epley = load * (1 + r / 30);
  final brzycki = load * 36 / (37 - r);
  return (epley + brzycki) / 2;
}

/// True when an estimate from [reps] is reliable enough to show without a
/// strong warning.
bool estimateIsReliable(int reps) => reps >= 1 && reps <= 10;

/// Load for [reps] hard reps from a one-rep max. Inverse of
/// [estimateOneRepMax], so the two round-trip.
double loadForReps(double oneRepMax, int reps) {
  if (reps <= 1) return oneRepMax;
  final epley = 1 + reps / 30;
  final brzycki = 36 / (37 - reps);
  // Solve (L*epley + L*brzycki) / 2 = 1RM for L.
  return oneRepMax * 2 / (epley + brzycki);
}

/// Rounds a load down to the next step the user can load, so a suggestion
/// is never heavier than the maths. Kg bars use 2.5, lb bars use 5.
double roundDownToStep(double load, double step) => step <= 0 ? load : (load / step + 1e-9).floorToDouble() * step;

double defaultStep(String unit) => unit == 'lb' ? 5 : 2.5;

/// Rep ranges by training goal, with a typical share of one-rep max.
///
/// Source: Schoenfeld BJ et al., J Strength Cond Res 2021 (loading
/// recommendations across the repetition continuum).
enum RepGoal {
  strength('Strength', 3, 5, 'Heavy. 3–5 reps, long rest (3–5 min).'),
  muscle('Muscle size', 8, 12, 'Moderate. 8–12 reps, 1.5–3 min rest.'),
  endurance('Endurance', 15, 20, 'Light. 15–20 reps, short rest (under 1 min).');

  const RepGoal(this.label, this.low, this.high, this.hint);
  final String label;
  final int low;
  final int high;
  final String hint;
}

/// Experience levels for first test weights.
enum Experience {
  beginner('Beginner', 'New, or under 6 months of steady training'),
  intermediate('Intermediate', '6 months to 2 years of steady training'),
  advanced('Advanced', 'More than 2 years of steady training');

  const Experience(this.label, this.hint);
  final String label;
  final String hint;
}

/// Lifts with a first-test-weight guide.
enum TestLift {
  squat('Back squat', lower: true, perHand: false, ratios: (0.5, 1.0, 1.4)),
  deadlift('Deadlift', lower: true, perHand: false, ratios: (0.6, 1.25, 1.7)),
  bench('Bench press', lower: false, perHand: false, ratios: (0.4, 0.75, 1.05)),
  overhead('Overhead press', lower: false, perHand: false, ratios: (0.25, 0.5, 0.65)),
  row('Barbell row', lower: false, perHand: false, ratios: (0.35, 0.6, 0.8)),
  dbPress('Dumbbell press (each hand)', lower: false, perHand: true, ratios: (0.1, 0.2, 0.28)),
  curl('Dumbbell curl (each hand)', lower: false, perHand: true, ratios: (0.06, 0.12, 0.16)),
  legPress('Leg press', lower: true, perHand: false, ratios: (0.8, 1.6, 2.4));

  const TestLift(this.label, {required this.lower, required this.perHand, required this.ratios});
  final String label;
  final bool lower;
  final bool perHand;

  /// Share of body weight for a first set of about 10 easy reps, by level.
  /// These are cautious starting guesses, not strength standards.
  final (double, double, double) ratios;
}

/// A cautious first weight for a set of about 10 reps with 2–3 reps left.
///
/// Women start at 60% (upper body) or 75% (lower body) of the ratio, to
/// reflect average differences in muscle mass. Then the user adjusts with
/// the reps-left test in [adjustAfterTest].
double firstTestWeight({
  required TestLift lift,
  required Experience level,
  required double bodyWeight,
  required bool female,
}) {
  final r = switch (level) {
    Experience.beginner => lift.ratios.$1,
    Experience.intermediate => lift.ratios.$2,
    Experience.advanced => lift.ratios.$3,
  };
  final sexFactor = female ? (lift.lower ? 0.75 : 0.6) : 1.0;
  return bodyWeight * r * sexFactor;
}

/// What to do after a test set aimed at 10 reps, from the reps the user
/// felt they had left. Returns the multiplier for the next set.
///
/// 0–1 left: 5% lighter. 2–3 left: keep it. 4–5 left: 5% heavier.
/// 6 or more: 10% heavier.
double adjustAfterTest(int repsLeft) {
  if (repsLeft <= 1) return 0.95;
  if (repsLeft <= 3) return 1.0;
  if (repsLeft <= 5) return 1.05;
  return 1.10;
}

/// One completed working set for progression.
class DoneSet {
  const DoneSet(this.load, this.reps);
  final double load;
  final int reps;
}

enum NextStep { addLoad, addReps, lighten }

class Suggestion {
  const Suggestion(this.step, this.load, this.reason);
  final NextStep step;
  final double load;
  final String reason;
}

/// Double progression: add reps inside the range, then add load.
///
/// - Every set reached the top of the range: add [increment].
/// - Any set fell below the bottom: drop about 5% (rounded down).
/// - Otherwise keep the load and try one more rep per set.
///
/// Uses the heaviest load of the last session's working sets.
Suggestion? nextSessionSuggestion(
  List<DoneSet> lastSession, {
  required int low,
  required int high,
  required double increment,
}) {
  final sets = lastSession.where((s) => s.load > 0 && s.reps > 0).toList();
  if (sets.isEmpty) return null;
  final top = sets.map((s) => s.load).reduce(math.max);
  final atTop = sets.where((s) => s.load == top).toList();
  if (atTop.every((s) => s.reps >= high)) {
    return Suggestion(NextStep.addLoad, top + increment, 'You hit $high reps on every set. Add $increment.');
  }
  if (atTop.any((s) => s.reps < low)) {
    final lighter = roundDownToStep(top * 0.95, increment);
    return Suggestion(NextStep.lighten, lighter, 'A set fell under $low reps. Go a little lighter.');
  }
  return Suggestion(NextStep.addReps, top, 'Keep the weight. Try for one more rep on each set.');
}
