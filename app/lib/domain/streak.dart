import '../core/dates.dart';

/// Workouts a week that keep the streak (launch review Block 3): one less
/// than the plan's days, so one missed day is forgiven, and at least one.
/// Without a plan, one workout a week.
int streakTarget(int? planDaysPerWeek) => planDaysPerWeek == null ? 1 : (planDaysPerWeek - 1).clamp(1, 7);

/// Weeks in a row, Monday to Sunday, with at least [target] workouts.
/// The week of [today] counts once it reaches the target; until then it
/// does not break the streak, because the week is not over.
int weeklyStreak(Iterable<DateTime> workoutDays, {required DateTime today, required int target}) {
  DateTime weekOf(DateTime d) {
    final day = dayOf(d);
    return addDays(day, -(day.weekday - 1));
  }

  final perWeek = <DateTime, int>{};
  for (final d in workoutDays) {
    final w = weekOf(d);
    perWeek[w] = (perWeek[w] ?? 0) + 1;
  }
  var week = weekOf(today);
  var streak = 0;
  if ((perWeek[week] ?? 0) >= target) streak++;
  week = addDays(week, -7);
  while ((perWeek[week] ?? 0) >= target) {
    streak++;
    week = addDays(week, -7);
  }
  return streak;
}
