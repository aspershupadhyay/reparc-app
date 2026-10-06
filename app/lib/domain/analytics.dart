import '../core/dates.dart';
import '../data/database.dart';
import '../data/meal_repository.dart';
import '../data/models.dart';
import '../data/workout_repository.dart';
import 'nutrition.dart';
import 'strength.dart';

/// User progress from saved records (handbook 6.2).
///
/// This is the user's own progress. It is not product-use analytics.
class ProgressSummary {
  ProgressSummary({
    required this.fromDay,
    required this.toDay,
    required this.sessions,
    required this.sets,
    required this.meals,
  });

  final DateTime fromDay;
  final DateTime toDay;

  /// Saved (finished or incomplete) sessions that started in the range.
  final List<SessionSummary> sessions;

  /// Completed sets in those sessions.
  final List<SetRecord> sets;

  /// Meal entries in the range, planned and eaten.
  final List<MealEntry> meals;

  int get dayCount => toDay.difference(fromDay).inDays + 1;

  List<DateTime> get days => [for (var i = 0; i < dayCount; i++) addDays(fromDay, i)];

  DateTime sessionDay(WorkoutSession s) => localDayOfInstant(s.startedAt, s.utcOffsetMinutes);

  Set<String> get trainingDays => {for (final s in sessions) dayKey(sessionDay(s.session))};

  int get completedSets => sets.length;

  /// Sum of recorded reps. Sets without reps are counted in [setsWithoutReps].
  int get totalReps => sets.fold(0, (a, r) => a + (r.set.reps ?? 0));
  int get setsWithoutReps => sets.where((r) => r.set.reps == null).length;

  Map<String, int> get setsByDay {
    final m = <String, int>{};
    for (final r in sets) {
      final k = dayKey(sessionDay(r.session));
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  List<MealEntry> get eatenMeals => meals.where((m) => m.status == MealStatus.eaten).toList();

  Set<String> get mealDays => {for (final m in eatenMeals) m.day};

  NutritionTotals get nutrition => totalsOf(meals.map((m) => m.input));

  Map<String, NutritionTotals> get nutritionByDay {
    final byDay = <String, List<MealEntry>>{};
    for (final m in eatenMeals) {
      (byDay[m.day] ??= []).add(m);
    }
    return byDay.map((k, v) => MapEntry(k, totalsOf(v.map((m) => m.input))));
  }
}

/// A personal record with a named rule (handbook 4.7).
class PersonalRecord {
  const PersonalRecord({required this.rule, required this.source});

  final String rule;

  /// The set that holds the record. The user can open it.
  final SetRecord source;
}

const heaviestLoadRule = 'Heaviest completed load';

/// Highest completed load for each exercise and load unit.
///
/// Each exercise row is one movement and variation, so different variations
/// are never compared. Different units are kept apart and not converted.
/// On a tie, the earliest set holds the record.
List<PersonalRecord> heaviestLoads(List<SetRecord> sets) {
  final best = <(String, String), SetRecord>{};
  for (final r in sets) {
    final load = r.set.load;
    final unit = r.set.loadUnit;
    if (load == null || unit == null || load <= 0) continue;
    final key = (r.exercise.id, unit);
    final current = best[key];
    if (current == null ||
        load > current.set.load! ||
        (load == current.set.load! && r.session.startedAt.isBefore(current.session.startedAt))) {
      best[key] = r;
    }
  }
  final list = best.values.map((r) => PersonalRecord(rule: heaviestLoadRule, source: r)).toList()
    ..sort((a, b) => a.source.exercise.name.toLowerCase().compareTo(b.source.exercise.name.toLowerCase()));
  return list;
}

// ------------------------------------------------------------ Workout stats

/// Exact pounds-to-kilograms factor.
const _kgPerLb = 0.45359237;

/// Sets that count as training: completed and not warm-up sets.
List<SetRecord> workingSets(Iterable<SetRecord> sets) => sets.where((r) => r.set.setType != SetType.warmup).toList();

/// Load × reps over working sets, in kilograms.
///
/// Pounds convert with the exact factor 0.45359237. Sets without a load,
/// reps, or unit are counted in [skipped], never as zero.
class Volume {
  const Volume(this.kg, this.counted, this.skipped);
  final double kg;
  final int counted;
  final int skipped;

  double inUnit(String unit) => unit == 'lb' ? kg / _kgPerLb : kg;
}

Volume volumeOf(Iterable<SetRecord> sets) {
  var kg = 0.0, counted = 0, skipped = 0;
  for (final r in workingSets(sets)) {
    final l = r.set.load, n = r.set.reps, u = r.set.loadUnit;
    if (l == null || n == null || u == null) {
      skipped++;
      continue;
    }
    kg += (u == 'lb' ? l * _kgPerLb : l) * n;
    counted++;
  }
  return Volume(kg, counted, skipped);
}

/// Working sets grouped by a key, for example the target muscle.
Map<K, int> countSetsBy<K>(Iterable<SetRecord> sets, K? Function(SetRecord) key) {
  final m = <K, int>{};
  for (final r in workingSets(sets)) {
    final k = key(r);
    if (k != null) m[k] = (m[k] ?? 0) + 1;
  }
  return m;
}

/// Average per week over a range of [days] days.
double perWeek(int count, int days) => days <= 0 ? 0 : count * 7 / days;

/// Active time of a saved session: end − start − paused time. Null when
/// the session has no end time.
Duration? activeTime(WorkoutSession s) {
  if (s.endedAt == null) return null;
  final d = s.endedAt!.difference(s.startedAt) - Duration(milliseconds: s.pausedMs);
  return d.isNegative ? Duration.zero : d;
}

const bestEstimateRule = 'Best estimated one-rep max (mean of Epley and Brzycki, sets of 1–10 reps)';

/// Estimated one-rep max for one working set, or null when the set cannot
/// give a reliable estimate (no load, no reps, or more than 10 reps).
double? setEstimate(SetRecord r) {
  final l = r.set.load, n = r.set.reps;
  if (l == null || n == null || l <= 0 || n < 1 || n > 10 || r.set.setType == SetType.warmup) return null;
  return estimateOneRepMax(l, n);
}

/// Best estimate per exercise and unit, with the set that holds it.
List<PersonalRecord> bestEstimates(List<SetRecord> sets) {
  final best = <(String, String), (double, SetRecord)>{};
  for (final r in sets) {
    final e = setEstimate(r);
    final u = r.set.loadUnit;
    if (e == null || u == null) continue;
    final key = (r.exercise.id, u);
    final cur = best[key];
    if (cur == null || e > cur.$1 || (e == cur.$1 && r.session.startedAt.isBefore(cur.$2.session.startedAt))) {
      best[key] = (e, r);
    }
  }
  return [for (final v in best.values) PersonalRecord(rule: bestEstimateRule, source: v.$2)]
    ..sort((a, b) => a.source.exercise.name.toLowerCase().compareTo(b.source.exercise.name.toLowerCase()));
}

/// Best estimate per session day for one exercise and unit, oldest first.
/// Days without a usable set are left out, not drawn as zero.
List<(DateTime, double)> estimateTrend(Iterable<SetRecord> sets, {required String exerciseId, required String unit}) {
  final byDay = <DateTime, double>{};
  for (final r in sets) {
    if (r.exercise.id != exerciseId || r.set.loadUnit != unit) continue;
    final e = setEstimate(r);
    if (e == null) continue;
    final d = localDayOfInstant(r.session.startedAt, r.session.utcOffsetMinutes);
    if (e > (byDay[d] ?? 0)) byDay[d] = e;
  }
  final out = byDay.entries.map((e) => (e.key, e.value)).toList()..sort((a, b) => a.$1.compareTo(b.$1));
  return out;
}

/// Volume per Monday-start week, in kg, for weeks that overlap the range.
Map<DateTime, double> weeklyVolume(Iterable<SetRecord> sets) {
  final m = <DateTime, double>{};
  for (final r in workingSets(sets)) {
    final l = r.set.load, n = r.set.reps, u = r.set.loadUnit;
    if (l == null || n == null || u == null) continue;
    final d = localDayOfInstant(r.session.startedAt, r.session.utcOffsetMinutes);
    final week = addDays(d, -(d.weekday - 1));
    m[week] = (m[week] ?? 0) + (u == 'lb' ? l * _kgPerLb : l) * n;
  }
  return m;
}

/// Planned roadmap days in a range: days whose weekday is in [weekdays],
/// from [since] (inclusive).
int plannedDays({required DateTime from, required DateTime to, required List<int> weekdays, DateTime? since}) {
  var n = 0;
  for (var d = from; !d.isAfter(to); d = addDays(d, 1)) {
    if (since != null && d.isBefore(since)) continue;
    if (weekdays.contains(d.weekday)) n++;
  }
  return n;
}

// --------------------------------------------------------------- Meal stats

/// Average of one nutrient over the days that have a value for it.
class DailyAverage {
  const DailyAverage(this.value, this.days);

  /// Null when no day has a value.
  final double? value;

  /// Days that had a value.
  final int days;
}

DailyAverage dailyAverage(Map<String, NutritionTotals> byDay, Nutrient n) {
  final v = [for (final d in byDay.values) d.of(n).value].whereType<double>().toList();
  return DailyAverage(v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length, v.length);
}

/// Days where the nutrient reached [target] (or stayed at or under it for a
/// limit), out of days that have a value.
(int hit, int days) daysOnTarget(Map<String, NutritionTotals> byDay, Nutrient n, double target, {bool limit = false}) {
  var hit = 0, days = 0;
  for (final d in byDay.values) {
    final v = d.of(n).value;
    if (v == null) continue;
    days++;
    if (limit ? v <= target : v >= target) hit++;
  }
  return (hit, days);
}
