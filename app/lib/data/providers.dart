import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
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

/// True until the user has a completed set of [exerciseId] in a saved
/// workout: first-day help shows then (launch review Block 3).
final firstTimeProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, String exerciseId) async =>
      (await ref.watch(workoutRepoProvider).completedSets(exerciseId: exerciseId)).isEmpty,
);

final historyProvider = StreamProvider.autoDispose((ref) => ref.watch(workoutRepoProvider).watchHistory());

final exercisesProvider = StreamProvider.autoDispose((ref) => ref.watch(workoutRepoProvider).watchExercises());

final exerciseProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchExercise(id),
);

final exerciseHistoryProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(workoutRepoProvider).watchExerciseHistory(id),
);

final mealSlotsProvider = StreamProvider.autoDispose((ref) => ref.watch(mealRepoProvider).watchSlots());

final mealDayProvider = StreamProvider.autoDispose.family(
  (ref, String day) => ref.watch(mealRepoProvider).watchDay(day),
);

final foodsProvider = StreamProvider.autoDispose((ref) => ref.watch(mealRepoProvider).watchFoods());

final recentFoodsProvider = StreamProvider.autoDispose((ref) => ref.watch(mealRepoProvider).watchRecentFoods());

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
final programsProvider = StreamProvider((ref) => ref.watch(programRepoProvider).watchAll());

final programProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(programRepoProvider).watch(id),
);

final bodyRepoProvider = Provider((ref) => BodyRepository(ref.watch(databaseProvider), ref.watch(clockProvider)));

final weightsProvider = StreamProvider.autoDispose((ref) => ref.watch(bodyRepoProvider).watchWeights());

/// Countries with their own foods in the bundled list, by ISO code.
const foodCountries = {'IN': 'India'};

/// The phone's region, for food search: on Android the mobile network's
/// country (else the SIM's), then the language setting's country. No
/// location and no permission (owner choice, 2026-10-10; phone test
/// 2026-10-11: an Indian phone set to "English (United States)" read US).
final phoneRegionProvider = FutureProvider<String?>((ref) async {
  try {
    final code = await const MethodChannel('app.reparc/region').invokeMethod<String>('country');
    if (code != null && code.length == 2) return code.toUpperCase();
  } catch (_) {
    // Not Android, or no telephony: use the language setting.
  }
  return WidgetsBinding.instance.platformDispatcher.locale.countryCode?.toUpperCase();
});

/// The country whose foods come first in food search: the user's choice in
/// Me, else the phone's region. Null means no country.
final foodCountryProvider = Provider<String?>((ref) {
  final chosen = ref.watch(currentSettingsProvider).foodCountry;
  if (chosen == 'ALL') return null;
  return chosen ?? ref.watch(phoneRegionProvider).value;
});

/// USDA food list bundled with the app. Loads once; no network.
final foodLibraryProvider = FutureProvider<FoodLibrary>(
  (ref) async => FoodLibrary.parse(await rootBundle.loadString('assets/foods/foods.json')),
);
