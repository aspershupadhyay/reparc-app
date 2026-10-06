import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog.dart';
import '../catalog/model.dart';

/// Prefix for library exercise IDs saved in `exercises.catalogId`.
const libraryPrefix = 'lib:';

/// One exercise from the bundled photo library.
///
/// Source: Free Exercise DB, public domain (Unlicense). Built by
/// `tool/exercise_library/build.py`. Each entry has a start and an end photo.
class LibraryExercise {
  const LibraryExercise({
    required this.id,
    required this.name,
    required this.category,
    required this.level,
    required this.equipment,
    required this.force,
    required this.mechanic,
    required this.primary,
    required this.secondary,
    required this.steps,
  });

  factory LibraryExercise.fromJson(Map<String, dynamic> j) => LibraryExercise(
    id: j['id'] as String,
    name: j['name'] as String,
    category: j['category'] as String,
    level: switch (j['level']) {
      'intermediate' => Level.intermediate,
      'expert' => Level.advanced,
      _ => Level.beginner,
    },
    equipment: _equipmentLabel(j['equipment'] as String?),
    force: j['force'] as String?,
    mechanic: j['mechanic'] as String?,
    primary: [for (final m in j['primary'] as List) _cap(m as String)],
    secondary: [for (final m in j['secondary'] as List) _cap(m as String)],
    steps: [for (final s in j['steps'] as List) s as String],
  );

  /// Stable source ID, for example `Barbell_Squat`. Never change it.
  final String id;
  final String name;

  /// strength, stretching, plyometrics, cardio, and so on.
  final String category;
  final Level level;
  final String equipment;
  final String? force;
  final String? mechanic;
  final List<String> primary;
  final List<String> secondary;
  final List<String> steps;

  /// ID saved on the exercise row that logs this entry.
  String get catalogId => '$libraryPrefix$id';

  String get startPhoto => 'assets/exercises/img/${id}_0.webp';
  String get endPhoto => 'assets/exercises/img/${id}_1.webp';

  BodyArea get area => areaForMuscle(primary.isEmpty ? '' : primary.first);

  String get categoryLabel => _cap(category);
}

/// Groups a library muscle name into one of the app's body areas.
BodyArea areaForMuscle(String m) => switch (m.toLowerCase()) {
  'chest' => BodyArea.chest,
  'lats' || 'middle back' || 'lower back' || 'traps' => BodyArea.back,
  'shoulders' || 'neck' => BodyArea.shoulders,
  'biceps' || 'triceps' || 'forearms' => BodyArea.arms,
  'quadriceps' || 'calves' || 'adductors' || 'abductors' => BodyArea.legs,
  'glutes' || 'hamstrings' => BodyArea.glutes,
  _ => BodyArea.core,
};

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _equipmentLabel(String? e) => switch (e) {
  null => 'No equipment',
  'body only' => 'Bodyweight',
  'e-z curl bar' => 'EZ bar',
  'kettlebells' => 'Kettlebell',
  _ => _cap(e),
};

/// Library photos for coached exercises. Coached text stays our own; only
/// the photos come from the library.
const coachedPhotos = <String, String>{
  'barbell-curl': 'Barbell_Curl',
  'hammer-curl': 'Hammer_Curls',
  'triceps-pushdown': 'Triceps_Pushdown',
  'overhead-triceps': 'Cable_Rope_Overhead_Triceps_Extension',
  'skull-crusher': 'EZ-Bar_Skullcrusher',
  'pull-up': 'Pullups',
  'barbell-row': 'Bent_Over_Barbell_Row',
  'deadlift': 'Barbell_Deadlift',
  'lat-pulldown': 'Wide-Grip_Lat_Pulldown',
  'seated-cable-row': 'Seated_Cable_Rows',
  'bench-press': 'Barbell_Bench_Press_-_Medium_Grip',
  'incline-db-press': 'Incline_Dumbbell_Press',
  'push-up': 'Pushups',
  'db-fly': 'Dumbbell_Flyes',
  'dip-chest': 'Dips_-_Chest_Version',
  'cable-crossover': 'Cable_Crossover',
  'plank': 'Plank',
  'dead-bug': 'Dead_Bug',
  'hanging-knee-raise': 'Hanging_Leg_Raise',
  'pallof-press': 'Pallof_Press',
  'russian-twist': 'Russian_Twist',
  'hip-thrust': 'Barbell_Hip_Thrust',
  'glute-bridge': 'Butt_Lift_Bridge',
  'romanian-deadlift': 'Romanian_Deadlift',
  'kettlebell-swing': 'One-Arm_Kettlebell_Swings',
  'lying-leg-curl': 'Lying_Leg_Curls',
  'back-squat': 'Barbell_Squat',
  'goblet-squat': 'Goblet_Squat',
  'split-squat': 'Split_Squat_with_Dumbbells',
  'leg-extension': 'Leg_Extensions',
  'calf-raise': 'Standing_Calf_Raises',
  'overhead-press': 'Standing_Military_Press',
  'lateral-raise': 'Side_Lateral_Raise',
  'seated-db-press': 'Dumbbell_Shoulder_Press',
  'face-pull': 'Face_Pull',
  'rear-delt-fly': 'Seated_Bent-Over_Rear_Delt_Raise',
};

/// Photo paths for a coached exercise, or null if it has none.
(String, String)? coachedPhotoPaths(String coachedId) {
  final id = coachedPhotos[coachedId];
  return id == null ? null : ('assets/exercises/img/${id}_0.webp', 'assets/exercises/img/${id}_1.webp');
}

/// One row in a mixed list: a coached guide or a library entry.
///
/// Library entries that a coached guide covers are left out, so each
/// movement shows once.
class Move {
  const Move.coached(ExerciseDef this.coached) : library = null;
  const Move.library(LibraryExercise this.library) : coached = null;

  final ExerciseDef? coached;
  final LibraryExercise? library;

  String get name => coached?.name ?? library!.name;
  BodyArea get area => coached?.area ?? library!.area;
  String get equipment => coached?.equipment ?? library!.equipment;
  Level get level => coached?.level ?? library!.level;
  String get catalogId => coached?.id ?? library!.catalogId;
  (String, String)? get photos =>
      coached != null ? coachedPhotoPaths(coached!.id) : (library!.startPhoto, library!.endPhoto);
  String get route => coached != null ? '/workout/guide/${coached!.id}' : '/workout/move/${library!.id}';
  String get muscles => coached != null ? coached!.primary.map((m) => m.label).join(', ') : library!.primary.join(', ');

  /// Lower-case text used for search.
  String get searchText =>
      '$name $equipment ${area.label} ${coached?.primary.map((m) => m.label).join(' ') ?? library!.primary.join(' ')}'
          .toLowerCase();
}

class ExerciseLibrary {
  ExerciseLibrary(List<LibraryExercise> items)
    : items = List.unmodifiable(items),
      byId = {for (final e in items) e.id: e} {
    final covered = coachedPhotos.values.toSet();
    final all = <Move>[
      for (final c in catalog) Move.coached(c),
      for (final e in items)
        if (!covered.contains(e.id)) Move.library(e),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    moves = List.unmodifiable(all);
  }

  factory ExerciseLibrary.parse(String json) {
    final root = jsonDecode(json) as Map<String, dynamic>;
    return ExerciseLibrary([
      for (final e in root['exercises'] as List) LibraryExercise.fromJson(e as Map<String, dynamic>),
    ]);
  }

  final List<LibraryExercise> items;
  final Map<String, LibraryExercise> byId;

  /// Every movement once, sorted by name.
  late final List<Move> moves;

  /// Equipment labels in use, most common first.
  late final List<String> equipment = () {
    final count = <String, int>{};
    for (final m in moves) {
      count[m.equipment] = (count[m.equipment] ?? 0) + 1;
    }
    return count.keys.toList()..sort((a, b) => count[b]!.compareTo(count[a]!));
  }();

  /// Library entry for a saved `catalogId`, if it is a library ID.
  LibraryExercise? forCatalogId(String? catalogId) =>
      catalogId != null && catalogId.startsWith(libraryPrefix) ? byId[catalogId.substring(libraryPrefix.length)] : null;
}

/// The bundled library. It loads once from the app's assets; no network.
final libraryProvider = FutureProvider<ExerciseLibrary>(
  (ref) async => ExerciseLibrary.parse(await rootBundle.loadString('assets/exercises/library.json')),
);

/// Body area for any saved exercise row's `catalogId`.
BodyArea? areaForCatalogId(String? catalogId, ExerciseLibrary? lib) =>
    catalogById[catalogId]?.area ?? lib?.forCatalogId(catalogId)?.area;

/// Screen that explains a saved exercise's `catalogId`, or null. Uses the
/// top-level routes so it also opens above the live workout.
String? guideRouteFor(String? catalogId) {
  if (catalogId == null) return null;
  if (catalogId.startsWith(libraryPrefix)) return '/learn/move/${catalogId.substring(libraryPrefix.length)}';
  return catalogById.containsKey(catalogId) ? '/learn/guide/$catalogId' : null;
}
