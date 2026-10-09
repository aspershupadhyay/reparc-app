import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../catalog/catalog.dart';
import '../catalog/model.dart';
import '../muscle_map.dart';
import '../rig/anatomy.dart';
import 'move_groups.dart';

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
      // The source marks a few plain static stretches "expert" (for
      // example Overhead Triceps). Holding a stretch is beginner work.
      'expert' when j['category'] == 'stretching' => Level.beginner,
      'intermediate' => Level.intermediate,
      'expert' => Level.advanced,
      _ => Level.beginner,
    },
    equipment: _equipmentLabel(j['equipment'] as String?, j['id'] as String, j['category'] as String),
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

  /// The one muscle this exercise mainly trains. Picks the delt head,
  /// upper chest, or obliques from the name when the source groups them.
  Muscle get target => targetMuscle(primary.isEmpty ? '' : primary.first, name);

  BodyArea get area => target.area;

  MoveKind get kind => switch (category) {
    'stretching' => MoveKind.stretch,
    'strength' || 'powerlifting' => MoveKind.strength,
    _ => MoveKind.power,
  };

  String get categoryLabel => _cap(category);
}

/// Kind of movement, so stretches and jumps do not crowd strength lists.
enum MoveKind {
  strength('Strength'),
  stretch('Stretch'),
  power('Power & cardio');

  const MoveKind(this.label);
  final String label;
}

/// Equipment groups for the filter. Fewer, clearer choices than the raw
/// source labels.
enum EquipKind {
  bodyweight('Bodyweight'),
  dumbbell('Dumbbell'),
  barbell('Barbell'),
  machine('Machine'),
  cable('Cable'),
  kettlebell('Kettlebell'),
  band('Band'),
  ball('Ball'),
  foamRoll('Foam roll'),
  other('Other');

  const EquipKind(this.label);
  final String label;

  static EquipKind of(String equipment) {
    final e = equipment.toLowerCase();
    if (e.startsWith('bodyweight') ||
        e.startsWith('no equipment') ||
        e.startsWith('pull-up') ||
        e.startsWith('dip bars') ||
        e.startsWith('parallel')) {
      return EquipKind.bodyweight;
    }
    if (e.startsWith('dumbbell') || e.startsWith('one dumbbell') || e.startsWith('plate or dumbbell')) {
      return EquipKind.dumbbell;
    }
    if (e.startsWith('barbell') || e.startsWith('ez bar') || e.startsWith('trap bar')) return EquipKind.barbell;
    if (e.startsWith('machine')) return EquipKind.machine;
    if (e.startsWith('cable')) return EquipKind.cable;
    if (e.startsWith('kettlebell')) return EquipKind.kettlebell;
    if (e.startsWith('band')) return EquipKind.band;
    if (e.startsWith('medicine ball') || e.startsWith('exercise ball')) return EquipKind.ball;
    if (e.startsWith('foam roll')) return EquipKind.foamRoll;
    return EquipKind.other;
  }
}

const _keepCase = {
  'Arnold',
  'Bulgarian',
  'Jefferson',
  'Pallof',
  'Romanian',
  'Russian',
  'Scott',
  'Smith',
  'Turkish',
  'Zottman',
  'Olympic',
};

/// "Barbell Incline Bench Press - Medium Grip" → "Barbell incline bench
/// press – medium grip". Keeps proper names (Romanian, Smith), short
/// capitals (DB, EZ), and words with digits.
String sentenceCase(String name) {
  bool keep(String w) =>
      w.isEmpty ||
      _keepCase.contains(w.replaceAll(RegExp(r'[^A-Za-z]'), '')) ||
      RegExp(r'\d').hasMatch(w) ||
      // Short capitals such as DB and EZ stay. A single "A" is the article:
      // "Over A Bench" → "over a bench".
      (w != 'A' && w.length <= 4 && w == w.toUpperCase() && RegExp(r'[A-Z]').hasMatch(w));
  String part(String w) => keep(w) ? w : w.toLowerCase();
  final words = name.replaceAll(' - ', ' – ').split(' ');
  return [
    for (final (i, w) in words.indexed)
      if (i == 0)
        // "Push-Ups" → "Push-ups": the first letter stays, inner parts follow
        // the same rule as other words.
        [for (final (j, x) in w.split('-').indexed) j == 0 ? x : part(x)].join('-')
      else
        [for (final x in w.split('-')) part(x)].join('-'),
  ].join(' ');
}

/// Maps a library muscle name and exercise name to one target muscle.
Muscle targetMuscle(String primary, String name) {
  final n = name.toLowerCase();
  bool has(List<String> words) => words.any(n.contains);
  return switch (primary.toLowerCase()) {
    'chest' =>
      has(['decline', 'dip'])
          ? Muscle.lowerChest
          : has(['incline'])
          ? Muscle.upperChest
          : Muscle.chest,
    'lats' => Muscle.lats,
    'middle back' => Muscle.upperBack,
    'traps' || 'neck' => Muscle.traps,
    'lower back' => Muscle.lowerBack,
    'shoulders' =>
      has([
            'rear',
            'reverse fl',
            'face pull',
            'pull apart',
            'back fly',
            'bent over',
            'bent-over',
            'external rotation',
            'internal rotation',
          ])
          ? Muscle.rearDelts
          : has(['lateral', 'side', 'upright', 'deltoid raise', 'scaption', 'iron cross', 'cuban'])
          ? Muscle.sideDelts
          : Muscle.frontDelts,
    // Palms-down curls load the forearm (brachioradialis) more than the biceps.
    'biceps' => has(['reverse']) && has(['curl']) ? Muscle.forearms : Muscle.biceps,
    'triceps' => Muscle.triceps,
    'forearms' => Muscle.forearms,
    'quadriceps' => Muscle.quads,
    'hamstrings' => Muscle.hamstrings,
    'calves' => Muscle.calves,
    'adductors' => Muscle.adductors,
    'glutes' => Muscle.glutes,
    'abductors' => Muscle.abductors,
    _ =>
      has([
            'oblique',
            'twist',
            'side bend',
            'side bridge',
            'russian',
            'wood',
            'windmill',
            'side plank',
            'side jackknife',
            'pallof',
          ])
          ? Muscle.obliques
          : has([
              'leg raise',
              'knee raise',
              'knee/hip raise',
              'hip raise',
              'reverse crunch',
              'scissor',
              'leg tuck',
              'tuck crunch',
              'hanging',
              'flutter',
              'leg lift',
            ])
          ? Muscle.lowerAbs
          : Muscle.abs,
  };
}

/// Hand-picked "start here" exercises for each muscle, best first. They
/// mix equipment so every gym has at least one. Coached guides lead.
const essentials = <Muscle, List<String>>{
  Muscle.upperChest: [
    'incline-db-press',
    'lib:Barbell_Incline_Bench_Press_-_Medium_Grip',
    'lib:Incline_Cable_Flye',
    'lib:Push-Ups_With_Feet_Elevated',
  ],
  Muscle.chest: ['bench-press', 'push-up', 'lib:Dumbbell_Bench_Press', 'cable-crossover', 'db-fly'],
  Muscle.lowerChest: [
    'dip-chest',
    'lib:Decline_Barbell_Bench_Press',
    'lib:Decline_Dumbbell_Bench_Press',
    'lib:Decline_Dumbbell_Flyes',
  ],
  Muscle.lats: ['pull-up', 'lat-pulldown', 'lib:Chin-Up', 'lib:Straight-Arm_Pulldown', 'lib:Band_Assisted_Pull-Up'],
  Muscle.upperBack: [
    'barbell-row',
    'seated-cable-row',
    'lib:One-Arm_Dumbbell_Row',
    'lib:Inverted_Row',
  ],
  Muscle.traps: ['lib:Dumbbell_Shrug', 'lib:Barbell_Shrug', 'lib:Cable_Shrugs', 'lib:Standing_Dumbbell_Upright_Row'],
  Muscle.lowerBack: [
    'lib:Hyperextensions_Back_Extensions',
    'lib:Hyperextensions_With_No_Hyperextension_Bench',
    'lib:Rack_Pulls',
  ],
  Muscle.frontDelts: ['overhead-press', 'seated-db-press', 'lib:Arnold_Dumbbell_Press', 'lib:Front_Dumbbell_Raise'],
  Muscle.sideDelts: [
    'lateral-raise',
    'lib:Cable_Seated_Lateral_Raise',
    'lib:Lateral_Raise_-_With_Bands',
    'lib:One-Arm_Incline_Lateral_Raise',
  ],
  Muscle.rearDelts: ['face-pull', 'rear-delt-fly', 'lib:Reverse_Machine_Flyes', 'lib:Band_Pull_Apart'],
  Muscle.biceps: [
    'barbell-curl',
    'hammer-curl',
    'lib:Dumbbell_Bicep_Curl',
    'lib:Incline_Dumbbell_Curl',
    'lib:Preacher_Curl',
  ],
  Muscle.triceps: [
    'triceps-pushdown',
    'overhead-triceps',
    'skull-crusher',
    'lib:Close-Grip_Barbell_Bench_Press',
    'lib:Push-Ups_-_Close_Triceps_Position',
  ],
  Muscle.forearms: [
    'lib:Farmers_Walk',
    'lib:Palms-Up_Dumbbell_Wrist_Curl_Over_A_Bench',
    'lib:Palms-Down_Dumbbell_Wrist_Curl_Over_A_Bench',
    'lib:Reverse_Barbell_Curl',
  ],
  Muscle.quads: ['back-squat', 'goblet-squat', 'split-squat', 'lib:Leg_Press', 'leg-extension', 'lib:Bodyweight_Squat'],
  Muscle.hamstrings: [
    'romanian-deadlift',
    'lying-leg-curl',
    'lib:Seated_Leg_Curl',
    'lib:Stiff-Legged_Dumbbell_Deadlift',
  ],
  Muscle.calves: ['calf-raise', 'lib:Seated_Calf_Raise', 'lib:Standing_Dumbbell_Calf_Raise'],
  Muscle.adductors: ['lib:Thigh_Adductor', 'lib:Band_Hip_Adductions'],
  Muscle.glutes: [
    'hip-thrust',
    'glute-bridge',
    'kettlebell-swing',
    'lib:Single_Leg_Glute_Bridge',
  ],
  Muscle.abductors: ['lib:Thigh_Abductor', 'lib:Monster_Walk'],
  Muscle.abs: ['plank', 'dead-bug', 'lib:Cable_Crunch', 'lib:Barbell_Ab_Rollout_-_On_Knees', 'lib:Crunches'],
  Muscle.lowerAbs: [
    'hanging-knee-raise',
    'lib:Reverse_Crunch',
    'lib:Flat_Bench_Lying_Leg_Raise',
    'lib:Bent-Knee_Hip_Raise',
  ],
  Muscle.obliques: ['pallof-press', 'russian-twist', 'lib:Side_Bridge', 'lib:Oblique_Crunches_-_On_The_Floor'],
};

/// Gym shorthand and plain words, and what they mean in the library.
const searchAliases = <String, List<String>>{
  'bi': ['bicep'],
  'bis': ['bicep'],
  'tri': ['tricep'],
  'tris': ['tricep'],
  'pec': ['chest'],
  'pecs': ['chest'],
  'delt': ['shoulder', 'delt'],
  'delts': ['shoulder', 'delt'],
  'quad': ['quad'],
  'ham': ['hamstring'],
  'hammy': ['hamstring'],
  'hammies': ['hamstring'],
  'bum': ['glute'],
  'butt': ['glute'],
  'booty': ['glute'],
  'six': ['abs', 'abdominal'],
  'sixpack': ['abs', 'abdominal'],
  'stomach': ['abs', 'abdominal', 'oblique'],
  'belly': ['abs', 'abdominal', 'oblique'],
  'core': ['abs', 'abdominal', 'oblique', 'core'],
  'trap': ['traps', 'shrug'],
  'neck': ['neck', 'traps'],
  'lat': ['lats'],
  'lats': ['lats'],
  'wing': ['lats'],
  'grip': ['forearm', 'grip'],
  'db': ['dumbbell'],
  'dbs': ['dumbbell'],
  'bb': ['barbell'],
  'kb': ['kettlebell'],
  'kbs': ['kettlebell'],
  'ez': ['ez bar', 'ez-bar'],
  'bw': ['bodyweight'],
  'rdl': ['romanian deadlift'],
  'ohp': ['overhead press', 'military press', 'shoulder press'],
  'skullcrusher': ['skull'],
  'skullcrushers': ['skull'],
  'pushup': ['push-up', 'pushup'],
  'pushups': ['push-up', 'pushup'],
  'pullup': ['pull-up', 'pullup'],
  'pullups': ['pull-up', 'pullup'],
  'chinup': ['chin-up', 'chin'],
  'situp': ['sit-up', 'situp'],
};

/// The words of [query], each with the texts that can match it. A plural
/// "s" is dropped so "curls" also finds "curl".
List<List<String>> searchTerms(String query) => [
  for (final w in query.toLowerCase().split(RegExp(r'\s+')))
    if (w.isNotEmpty) searchAliases[w] ?? [if (w.length > 3 && w.endsWith('s')) w.substring(0, w.length - 1) else w],
];

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// One word for "no equipment": the source uses both "body only" and none.
/// Its "other" label covers 122 moves; most need a known item, so the name
/// picks it. What stays "Other" is rare kit.
String _equipmentLabel(String? e, String id, String category) {
  switch (e) {
    case null || 'body only':
      return 'Bodyweight';
    case 'e-z curl bar':
      return 'EZ bar';
    case 'kettlebells':
      return 'Kettlebell';
    case 'other':
      return _otherEquipment(id.toLowerCase(), category);
    default:
      return _cap(e);
  }
}

String _otherEquipment(String id, String category) {
  bool has(List<String> words) => words.any(id.contains);
  if (has(['smr'])) return 'Foam roll';
  if (has(['ab_roller'])) return 'Ab wheel';
  if (has(['farmers'])) return 'Farmer handles or dumbbells';
  if (has(['trap_bar'])) return 'Trap bar';
  if (has(['sledgehammer'])) return 'Sledgehammer, tyre';
  if (has(['sled', 'prowler'])) return 'Sled';
  if (has(['suspended', 'straps'])) return 'Suspension straps';
  if (has(['ring_dips'])) return 'Rings';
  if (has(['dips', 'parallel_bar'])) return 'Dip bars';
  if (has(['chin', 'pull-up', 'pull_up', 'muscle_up', 'hang', 'otis', 'rocky'])) return 'Pull-up bar';
  if (has(['plate', 'svend'])) return 'Weight plate';
  if (has(['chain'])) return 'Chains';
  if (has(['battling_ropes'])) return 'Battle ropes';
  if (has(['rope_climb'])) return 'Climbing rope';
  if (has(['rope_jumping'])) return 'Jump rope';
  if (has(['box'])) return 'Box';
  if (has(['cone', 'hurdle'])) return 'Cones or hurdles';
  if (has(['hyperextensions'])) return 'Back extension bench';
  if (has(['wrist_roller'])) return 'Wrist roller';
  if (has(['band'])) return 'Band';
  if (has(['harness'])) return 'Neck harness';
  if (has(['heavy_bag'])) return 'Heavy bag';
  if (has(['balance_board'])) return 'Balance board';
  if (has(['bicycling'])) return 'Bike';
  if (has([
    'atlas',
    'axle',
    'car_deadlift',
    'circus',
    'conans',
    'keg',
    'log_lift',
    'rickshaw',
    'sandbag',
    'tire',
    'yoke',
  ])) {
    return 'Strongman gear';
  }
  if (has(['chair'])) return 'Chair';
  if (has(['bench', 'platform', 'stairs', 'weighted'])) return 'Other';
  // Stretches, hops, and sprints left here need only the body.
  return category == 'stretching' || category == 'plyometrics' || category == 'cardio' ? 'Bodyweight' : 'Other';
}

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

  /// Coached names are written in sentence case. Library names come in
  /// Title Case, so they are shown in the same case (visual review,
  /// 2026-10-09).
  String get name => coached?.name ?? sentenceCase(library!.name);

  /// The muscle this movement mainly trains. Browse groups by it.
  Muscle get target => coached?.primary.first ?? library!.target;
  BodyArea get area => target.area;
  MoveKind get kind => library?.kind ?? MoveKind.strength;
  EquipKind get equipKind => EquipKind.of(equipment);
  Set<Muscle> get helpers {
    if (coached != null) return coached!.secondary;
    final t = target;
    return {
      for (final m in library!.secondary)
        if (targetMuscle(m, name) != t) targetMuscle(m, name),
    };
  }

  String get equipment => coached?.equipment ?? library!.equipment;
  Level get level => coached?.level ?? library!.level;
  String get catalogId => coached?.id ?? library!.catalogId;
  (String, String)? get photos =>
      coached != null ? coachedPhotoPaths(coached!.id) : (library!.startPhoto, library!.endPhoto);
  String get route => coached != null ? '/workout/guide/${coached!.id}' : '/workout/move/${library!.id}';
  String get muscles => coached != null ? coached!.primary.map((m) => m.label).join(', ') : library!.primary.join(', ');

  /// Lower-case text used for search: name, equipment, area, target muscle,
  /// its group (for example "long head"), and the source muscle names.
  String get searchText =>
      '$name $equipment ${equipKind.label} ${area.label} ${target.label} ${groupOf(this).label} '
              '${coached?.primary.map((m) => m.label).join(' ') ?? library!.primary.join(' ')}'
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
    byCatalogId = {for (final m in all) m.catalogId: m};
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

  /// Every movement by the ID a plan or a saved exercise uses.
  late final Map<String, Move> byCatalogId;

  /// Every hand-picked "start here" move, for search ranking.
  late final Set<String> essentialIds = {for (final ids in essentials.values) ...ids};

  /// Moves that match every word of [query], best first.
  ///
  /// Gym shorthand works ("bi", "tris", "db", "rdl"). Best first means: the
  /// name holds every word, then coached guides and "start here" picks, then
  /// names that start with the first word, then shorter names, which are
  /// usually the basic form of a movement.
  List<Move> search(String query, {Iterable<Move>? within}) {
    final words = searchTerms(query);
    if (words.isEmpty) return [...within ?? moves];
    final hits = [
      for (final m in within ?? moves)
        if (words.every((alts) => alts.any(m.searchText.contains))) m,
    ];
    int rank(Move m) {
      final name = m.name.toLowerCase();
      final inName = words.every((alts) => alts.any(name.contains));
      final starts = words.first.any(name.startsWith);
      final picked = m.coached != null || essentialIds.contains(m.catalogId);
      return (inName ? 0 : 4) + (picked ? 0 : 2) + (starts ? 0 : 1);
    }

    final ranks = {for (final m in hits) m: rank(m)};
    return hits..sort((a, b) {
      final r = ranks[a]!.compareTo(ranks[b]!);
      return r != 0 ? r : a.name.length.compareTo(b.name.length);
    });
  }

  /// Hand-picked starting exercises for [m] that exist in this build.
  List<Move> essentialsFor(Muscle m) => [
    for (final id in essentials[m] ?? const <String>[]) ?byCatalogId[id],
  ];

  /// Equipment groups in use, in filter order.
  late final List<EquipKind> equipKinds = [
    for (final k in EquipKind.values)
      if (moves.any((m) => m.equipKind == k)) k,
  ];

  /// Library entry for a saved `catalogId`, if it is a library ID.
  LibraryExercise? forCatalogId(String? catalogId) =>
      catalogId != null && catalogId.startsWith(libraryPrefix) ? byId[catalogId.substring(libraryPrefix.length)] : null;
}

/// The bundled library. It loads once from the app's assets; no network.
final libraryProvider = FutureProvider<ExerciseLibrary>(
  (ref) async => ExerciseLibrary.parse(await rootBundle.loadString('assets/exercises/library.json')),
);

/// Body area for any saved exercise row's `catalogId`.
BodyArea? areaForCatalogId(String? catalogId, ExerciseLibrary? lib) => targetForCatalogId(catalogId, lib)?.area;

/// Target muscle for any saved exercise row's `catalogId`.
Muscle? targetForCatalogId(String? catalogId, ExerciseLibrary? lib) =>
    catalogById[catalogId]?.primary.first ?? lib?.forCatalogId(catalogId)?.target;

/// Screen that explains a saved exercise's `catalogId`, or null. Uses the
/// top-level routes so it also opens above the live workout.
String? guideRouteFor(String? catalogId) {
  if (catalogId == null) return null;
  if (catalogId.startsWith(libraryPrefix)) return '/learn/move/${catalogId.substring(libraryPrefix.length)}';
  return catalogById.containsKey(catalogId) ? '/learn/guide/$catalogId' : null;
}
