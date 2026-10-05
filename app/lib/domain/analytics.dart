import '../core/dates.dart';
import '../data/database.dart';
import '../data/meal_repository.dart';
import '../data/models.dart';
import '../data/workout_repository.dart';
import 'nutrition.dart';

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
