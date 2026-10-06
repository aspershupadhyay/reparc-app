import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../domain/meal_plan.dart';
import 'analytics_repository.dart';
import 'body_repository.dart';
import 'data_controls.dart';
import 'database.dart';
import 'meal_repository.dart';
import 'program_repository.dart';
import 'settings_repository.dart';
import 'workout_repository.dart';

/// The open local database. `main` overrides this provider.
final databaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('Override databaseProvider'));

final workoutRepoProvider = Provider(
  (ref) => WorkoutRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final mealRepoProvider = Provider(
  (ref) => MealRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final settingsRepoProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));

final dataControlsProvider = Provider(
  (ref) => DataControls(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final settingsProvider = StreamProvider<AppSettings>((ref) => ref.watch(settingsRepoProvider).watch());

/// Settings, or defaults while they load.
final currentSettingsProvider = Provider<AppSettings>(
  (ref) => ref.watch(settingsProvider).value ?? const AppSettings(),
);

final liveSessionProvider = StreamProvider((ref) => ref.watch(workoutRepoProvider).watchLiveSession());

final sessionProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchSession(id),
);

final historyProvider = StreamProvider.autoDispose((ref) => ref.watch(workoutRepoProvider).watchHistory());

final exercisesProvider = StreamProvider.autoDispose((ref) => ref.watch(workoutRepoProvider).watchExercises());

final exerciseProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchExercise(id),
);

final exerciseHistoryProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchExerciseHistory(id),
);

final templatesProvider = StreamProvider.autoDispose((ref) => ref.watch(workoutRepoProvider).watchTemplates());

final templateProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchTemplate(id),
);

final mealSlotsProvider = StreamProvider.autoDispose((ref) => ref.watch(mealRepoProvider).watchSlots());

final mealDayProvider = StreamProvider.autoDispose.family(
  (ref, String day) => ref.watch(mealRepoProvider).watchDay(day),
);

final foodsProvider = StreamProvider.autoDispose((ref) => ref.watch(mealRepoProvider).watchFoods());

final analyticsRepoProvider = Provider(
  (ref) => AnalyticsRepository(
    ref.watch(databaseProvider),
    ref.watch(workoutRepoProvider),
    ref.watch(mealRepoProvider),
  ),
);

final progressProvider = StreamProvider.autoDispose.family(
  (ref, (DateTime, DateTime) range) => ref.watch(analyticsRepoProvider).watchRange(range.$1, range.$2),
);

final recordsProvider = StreamProvider.autoDispose((ref) => ref.watch(analyticsRepoProvider).watchRecords());

final catalogExerciseProvider = StreamProvider.autoDispose.family(
  (ref, String catalogId) => ref.watch(workoutRepoProvider).watchCatalogExercise(catalogId),
);

final mealRangeProvider = StreamProvider.autoDispose.family(
  (ref, (String, String) range) => ref.watch(mealRepoProvider).watchRange(range.$1, range.$2),
);

final programRepoProvider = Provider(
  (ref) => ProgramRepository(ref.watch(databaseProvider), ref.watch(clockProvider)),
);

final activeProgramProvider = StreamProvider((ref) => ref.watch(programRepoProvider).watchActive());

final programProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(programRepoProvider).watch(id),
);

final bodyRepoProvider = Provider((ref) => BodyRepository(ref.watch(databaseProvider), ref.watch(clockProvider)));

final weightsProvider = StreamProvider.autoDispose((ref) => ref.watch(bodyRepoProvider).watchWeights());

/// USDA food list bundled with the app. Loads once; no network.
final foodLibraryProvider = FutureProvider<FoodLibrary>(
  (ref) async => FoodLibrary.parse(await rootBundle.loadString('assets/foods/foods.json')),
);
