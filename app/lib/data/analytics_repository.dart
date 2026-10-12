import '../core/dates.dart';
import '../domain/analytics.dart';
import 'database.dart';
import 'meal_repository.dart';
import 'watch.dart';
import 'workout_repository.dart';

class AnalyticsRepository {
  AnalyticsRepository(this.db, this.workouts, this.meals);

  final AppDatabase db;
  final WorkoutRepository workouts;
  final MealRepository meals;

  Stream<ProgressSummary> watchRange(DateTime fromDay, DateTime toDay) => watchTables(
    db,
    [db.workoutSessions, db.sessionExercises, db.setEntries, db.exercises, db.mealEntries],
    () => load(fromDay, toDay),
  );

  Future<ProgressSummary> load(DateTime fromDay, DateTime toDay) async {
    // Read one extra day on each side, then filter by the day the session
    // was recorded in. Time zones can move an instant across a day line.
    final fromUtc = addDays(fromDay, -1).toUtc();
    final toUtc = addDays(toDay, 2).toUtc();
    bool inRange(DateTime day) => !day.isBefore(fromDay) && !day.isAfter(toDay);
    DateTime dayOf(WorkoutSession s) => localDayOfInstant(s.startedAt, s.utcOffsetMinutes);

    final sessions = (await workouts.sessionSummaries(
      fromUtc: fromUtc,
      toUtc: toUtc,
    )).where((s) => inRange(dayOf(s.session))).toList();
    final sets = (await workouts.completedSets(
      fromUtc: fromUtc,
      toUtc: toUtc,
    )).where((r) => inRange(dayOf(r.session))).toList();
    final mealEntries = await meals.entriesInRange(dayKey(fromDay), dayKey(toDay));
    return ProgressSummary(fromDay: fromDay, toDay: toDay, sessions: sessions, sets: sets, meals: mealEntries);
  }

  Stream<List<PersonalRecord>> watchRecords() => watchTables(
    db,
    [db.workoutSessions, db.sessionExercises, db.setEntries, db.exercises],
    workouts.heaviestLoadRecords,
  );
}
