/// Training roadmaps: a weekly plan built from a goal, a level, days per
/// week, and the equipment the user has.
///
/// The generator returns a plain document ([ProgramPlan]) that the user
/// owns and can change: every day, exercise, set, rep, and rest value. The
/// app never edits it again on its own.
///
/// The plans follow common, published training guidance:
/// - Train each muscle about twice a week (Schoenfeld BJ et al., Sports Med
///   2016).
/// - About 10–20 hard sets per muscle a week for size; fewer for beginners
///   (Schoenfeld BJ et al., J Sports Sci 2017; Baz-Valle E et al. 2022).
/// - Stop most sets 1–3 reps short of failure (Refalo MC et al., Sports Med
///   2023), with beginners further from failure.
/// - Warm up with light general movement, then lighter sets of the first
///   lift (McCrary JM et al., Br J Sports Med 2015; Fradkin AJ et al., J
///   Strength Cond Res 2010).
///
/// The text is general coaching for healthy adults, not medical advice.
/// A qualified coach review is still **To confirm** (handbook 4.11).
library;

import 'dart:convert';

enum RoadmapGoal {
  aesthetic(
    'Aesthetic',
    'A lean, balanced look: wide shoulders, full chest and back, strong arms, and a narrow waist.',
  ),
  bodybuilding('Bodybuilding', 'Maximum muscle size across the whole body with high training volume.'),
  strength('Strength', 'Lift heavier on the squat, bench press, deadlift, and overhead press.'),
  calisthenics('Calisthenics', 'Master your body weight: push-ups to dips, rows to pull-ups, squats to pistols.'),
  leanFit('Lean & fit', 'Lose fat and get fitter with full-body strength work and short cardio finishers.');

  const RoadmapGoal(this.label, this.summary);
  final String label;
  final String summary;

  /// Days a week the plan supports.
  List<int> get dayOptions => switch (this) {
    RoadmapGoal.strength => const [2, 3, 4],
    RoadmapGoal.calisthenics => const [2, 3, 4, 5],
    _ => const [2, 3, 4, 5, 6],
  };

  int defaultDays(RoadmapLevel l) => switch ((this, l)) {
    (_, RoadmapLevel.beginner) => 3,
    (RoadmapGoal.bodybuilding, RoadmapLevel.advanced) => 6,
    (RoadmapGoal.aesthetic, RoadmapLevel.advanced) => 5,
    (RoadmapGoal.leanFit, RoadmapLevel.advanced) => 5,
    _ => 4,
  };
}

enum RoadmapLevel {
  beginner('Beginner', 'New to training, or under 6 months of steady work.'),
  intermediate('Intermediate', '6 months to 2 years. Simple plans no longer add weight each week.'),
  advanced('Advanced', 'More than 2 years. Progress is slow and needs more planning.');

  const RoadmapLevel(this.label, this.hint);
  final String label;
  final String hint;
}

enum GymSetup {
  fullGym('Full gym', 'Barbells, racks, cables, machines, and dumbbells'),
  dumbbells('Dumbbells and a bench', 'A pair of dumbbells, a bench, and a pull-up bar'),
  home('Home, no weights', 'Body weight, a resistance band, and a pull-up bar or sturdy table');

  const GymSetup(this.label, this.hint);
  final String label;
  final String hint;
}

/// Where an item sits in a day.
enum ItemKind {
  warmup('Warm-up'),
  main('Main lift'),
  secondary('Second lift'),
  accessory('Extra work'),
  core('Core'),
  finisher('Finisher'),
  cooldown('Cool-down');

  const ItemKind(this.label);
  final String label;
}

/// One exercise, warm-up move, or stretch in a plan day.
class PlanItem {
  const PlanItem({
    required this.kind,
    required this.exerciseId,
    required this.name,
    this.pattern,
    this.sets = 1,
    this.repsLow,
    this.repsHigh,
    this.seconds,
    this.restSec,
    this.rir,
    this.rampUp = false,
    this.note,
  });

  final ItemKind kind;

  /// Coached guide ID (`bench-press`), library ID (`lib:Pushups`), or one
  /// of the user's own exercises (`user:<exercise row id>`, see [userRef]).
  final String exerciseId;
  final String name;

  /// Movement pattern. The app offers alternatives from the same pattern.
  final String? pattern;
  final int sets;
  final int? repsLow;
  final int? repsHigh;

  /// For holds, cardio, and stretches.
  final int? seconds;
  final int? restSec;

  /// Reps to keep in reserve: stop this many reps before failure.
  final int? rir;

  /// Do lighter warm-up sets of this lift first.
  final bool rampUp;
  final String? note;

  /// Sets and reps or time: "3 × 8–12", "10 reps", "2 × 45 s", "5 min".
  String get target {
    if (seconds != null) {
      final t = seconds! >= 60 && seconds! % 60 == 0 ? '${seconds! ~/ 60} min' : '$seconds s';
      return sets > 1 ? '$sets × $t' : t;
    }
    if (repsLow == null) return sets > 1 ? '$sets sets' : '';
    final reps = repsHigh == null || repsHigh == repsLow ? '$repsLow' : '$repsLow–$repsHigh';
    return sets > 1 ? '$sets × $reps' : '$reps reps';
  }

  /// Target, rest, and effort on one line. The roadmap day and the live
  /// workout both show this text.
  String get details => [
    target,
    if (restSec != null && kind != ItemKind.warmup) '${restText(restSec!)} rest',
    if (rir != null) rir == 0 ? 'to failure' : '$rir reps left',
  ].where((s) => s.isNotEmpty).join(' · ');

  PlanItem copyWith({
    ItemKind? kind,
    String? exerciseId,
    String? name,
    String? pattern,
    int? sets,
    int? repsLow,
    int? repsHigh,
    int? seconds,
    int? restSec,
    int? rir,
    bool? rampUp,
    String? note,
  }) => PlanItem(
    kind: kind ?? this.kind,
    exerciseId: exerciseId ?? this.exerciseId,
    name: name ?? this.name,
    pattern: pattern ?? this.pattern,
    sets: sets ?? this.sets,
    repsLow: repsLow ?? this.repsLow,
    repsHigh: repsHigh ?? this.repsHigh,
    seconds: seconds ?? this.seconds,
    restSec: restSec ?? this.restSec,
    rir: rir ?? this.rir,
    rampUp: rampUp ?? this.rampUp,
    note: note ?? this.note,
  );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'exerciseId': exerciseId,
    'name': name,
    'pattern': ?pattern,
    'sets': sets,
    'repsLow': ?repsLow,
    'repsHigh': ?repsHigh,
    'seconds': ?seconds,
    'restSec': ?restSec,
    'rir': ?rir,
    if (rampUp) 'rampUp': true,
    'note': ?note,
  };

  factory PlanItem.fromJson(Map<String, Object?> j) => PlanItem(
    kind: ItemKind.values.asNameMap()[j['kind']] ?? ItemKind.accessory,
    exerciseId: j['exerciseId'] as String,
    name: j['name'] as String,
    pattern: j['pattern'] as String?,
    sets: (j['sets'] as num?)?.toInt() ?? 1,
    repsLow: (j['repsLow'] as num?)?.toInt(),
    repsHigh: (j['repsHigh'] as num?)?.toInt(),
    seconds: (j['seconds'] as num?)?.toInt(),
    restSec: (j['restSec'] as num?)?.toInt(),
    rir: (j['rir'] as num?)?.toInt(),
    rampUp: j['rampUp'] == true,
    note: j['note'] as String?,
  );
}

class PlanDay {
  const PlanDay({required this.name, required this.focus, required this.items});
  final String name;
  final String focus;
  final List<PlanItem> items;

  Iterable<PlanItem> get warmup => items.where((i) => i.kind == ItemKind.warmup);
  Iterable<PlanItem> get work => items.where((i) => i.kind != ItemKind.warmup && i.kind != ItemKind.cooldown);
  Iterable<PlanItem> get cooldown => items.where((i) => i.kind == ItemKind.cooldown);

  /// Hard sets in the day, not counting warm-up and cool-down.
  int get workSets => work.fold(0, (a, i) => a + i.sets);

  /// Rough length in minutes: about 40 s per set plus rest, plus warm-up
  /// and cool-down time.
  int get minutes => _minutes(items);

  /// Rough length of the warm-up in minutes.
  int get warmupMinutes => _minutes(warmup);

  static int _minutes(Iterable<PlanItem> items) {
    var s = 0;
    for (final i in items) {
      final perSet = i.seconds ?? 40;
      s += i.sets * perSet + (i.sets - 1).clamp(0, 99) * (i.restSec ?? 0);
      if (i.kind != ItemKind.warmup && i.kind != ItemKind.cooldown) s += i.restSec ?? 0;
      if (i.rampUp) s += 4 * 60;
    }
    return (s / 60).round();
  }

  PlanDay copyWith({String? name, String? focus, List<PlanItem>? items}) =>
      PlanDay(name: name ?? this.name, focus: focus ?? this.focus, items: items ?? this.items);

  Map<String, Object?> toJson() => {
    'name': name,
    'focus': focus,
    'items': [for (final i in items) i.toJson()],
  };

  factory PlanDay.fromJson(Map<String, Object?> j) => PlanDay(
    name: j['name'] as String,
    focus: j['focus'] as String? ?? '',
    items: [for (final i in j['items'] as List) PlanItem.fromJson((i as Map).cast<String, Object?>())],
  );
}

/// Plan item reference for an exercise the user made.
String userRef(String exerciseRowId) => 'user:$exerciseRowId';

/// The exercise row ID in a `user:` reference, or null for built-in IDs.
String? userRefId(String exerciseId) => exerciseId.startsWith('user:') ? exerciseId.substring(5) : null;

/// A plan: one or more training days. Stored as JSON in `programs.plan`.
///
/// A roadmap is a plan the builder made; it has a [goal], [level], and
/// [setup]. A plan the user made, or one that came from an AI app or an
/// older app version, has none of them (handbook 4.12).
class ProgramPlan {
  const ProgramPlan({
    this.goal,
    this.level,
    this.setup,
    required this.days,
    this.weekdays = const [],
    this.progression = '',
    this.deload = '',
    this.showWarmup = true,
    this.showCooldown = true,
    this.showNotes = true,
  });

  static const formatVersion = 1;

  final RoadmapGoal? goal;
  final RoadmapLevel? level;
  final GymSetup? setup;
  final List<PlanDay> days;

  /// Suggested training weekdays, 1 = Monday. The user can change them.
  final List<int> weekdays;

  /// How to add weight or reps over time.
  final String progression;

  /// When and how to take an easier week.
  final String deload;

  /// What the user wants to see on each day.
  final bool showWarmup;
  final bool showCooldown;
  final bool showNotes;

  /// Default name for a built plan: "Strength · Beginner".
  String get title => goal == null ? 'My plan' : [goal!.label, ?level?.label].join(' · ');

  /// "Strength · Beginner · Full gym", or null for a plan without a goal.
  String? get about => goal == null ? null : [title, ?setup?.label].join(' · ');

  ProgramPlan copyWith({
    List<PlanDay>? days,
    List<int>? weekdays,
    bool? showWarmup,
    bool? showCooldown,
    bool? showNotes,
  }) => ProgramPlan(
    goal: goal,
    level: level,
    setup: setup,
    days: days ?? this.days,
    weekdays: weekdays ?? this.weekdays,
    progression: progression,
    deload: deload,
    showWarmup: showWarmup ?? this.showWarmup,
    showCooldown: showCooldown ?? this.showCooldown,
    showNotes: showNotes ?? this.showNotes,
  );

  Map<String, Object?> toJson() => {
    'formatVersion': formatVersion,
    'goal': ?goal?.name,
    'level': ?level?.name,
    'setup': ?setup?.name,
    'weekdays': weekdays,
    'progression': progression,
    'deload': deload,
    'showWarmup': showWarmup,
    'showCooldown': showCooldown,
    'showNotes': showNotes,
    'days': [for (final d in days) d.toJson()],
  };

  String encode() => jsonEncode(toJson());

  factory ProgramPlan.fromJson(Map<String, Object?> j) => ProgramPlan(
    goal: RoadmapGoal.values.asNameMap()[j['goal']],
    level: RoadmapLevel.values.asNameMap()[j['level']],
    setup: GymSetup.values.asNameMap()[j['setup']],
    weekdays: [for (final d in (j['weekdays'] as List? ?? const [])) (d as num).toInt()],
    progression: j['progression'] as String? ?? '',
    deload: j['deload'] as String? ?? '',
    showWarmup: j['showWarmup'] != false,
    showCooldown: j['showCooldown'] != false,
    showNotes: j['showNotes'] != false,
    days: [for (final d in j['days'] as List) PlanDay.fromJson((d as Map).cast<String, Object?>())],
  );

  static ProgramPlan decode(String s) => ProgramPlan.fromJson((jsonDecode(s) as Map).cast<String, Object?>());
}

/// An exercise choice: ID and display name.
typedef Ex = (String id, String name);

/// Movement patterns with one choice for each equipment setup.
///
/// Order: full gym, dumbbells, home. A "lib:" ID is from the bundled photo
/// library; other IDs are coached guides.
const patterns = <String, (Ex, Ex, Ex)>{
  'squat': (
    ('back-squat', 'Back squat'),
    ('goblet-squat', 'Goblet squat'),
    ('lib:Bodyweight_Squat', 'Bodyweight squat'),
  ),
  'hinge': (
    ('romanian-deadlift', 'Romanian deadlift'),
    ('lib:Stiff-Legged_Dumbbell_Deadlift', 'Dumbbell stiff-leg deadlift'),
    ('lib:Hyperextensions_With_No_Hyperextension_Bench', 'Floor back extension'),
  ),
  'deadlift': (
    ('deadlift', 'Deadlift'),
    ('lib:Stiff-Legged_Dumbbell_Deadlift', 'Dumbbell stiff-leg deadlift'),
    ('lib:Single_Leg_Glute_Bridge', 'Single-leg glute bridge'),
  ),
  'lunge': (
    ('split-squat', 'Split squat'),
    ('split-squat', 'Split squat'),
    ('lib:Bodyweight_Walking_Lunge', 'Walking lunge'),
  ),
  'quadPress': (
    ('lib:Leg_Press', 'Leg press'),
    ('lib:Dumbbell_Step_Ups', 'Dumbbell step-up'),
    ('lib:Step-up_with_Knee_Raise', 'Step-up'),
  ),
  'quadIso': (
    ('leg-extension', 'Leg extension'),
    ('lib:Dumbbell_Rear_Lunge', 'Dumbbell reverse lunge'),
    ('lib:Bodyweight_Walking_Lunge', 'Walking lunge'),
  ),
  'legCurl': (
    ('lying-leg-curl', 'Lying leg curl'),
    ('lib:Single_Leg_Glute_Bridge', 'Single-leg glute bridge'),
    ('lib:Single_Leg_Glute_Bridge', 'Single-leg glute bridge'),
  ),
  'hipThrust': (
    ('hip-thrust', 'Barbell hip thrust'),
    ('glute-bridge', 'Glute bridge'),
    ('glute-bridge', 'Glute bridge'),
  ),
  'calf': (('calf-raise', 'Calf raise'), ('calf-raise', 'Calf raise'), ('calf-raise', 'Calf raise')),
  'hPress': (
    ('bench-press', 'Bench press'),
    ('lib:Dumbbell_Bench_Press', 'Dumbbell bench press'),
    ('push-up', 'Push-up'),
  ),
  'inclinePress': (
    ('lib:Barbell_Incline_Bench_Press_-_Medium_Grip', 'Incline bench press'),
    ('incline-db-press', 'Incline dumbbell press'),
    ('lib:Push-Ups_With_Feet_Elevated', 'Feet-up push-up'),
  ),
  'chestFly': (
    ('cable-crossover', 'Cable crossover'),
    ('db-fly', 'Dumbbell fly'),
    ('lib:Push-Up_Wide', 'Wide push-up'),
  ),
  'dip': (('dip-chest', 'Chest dip'), ('lib:Bench_Dips', 'Bench dip'), ('lib:Bench_Dips', 'Bench dip')),
  'vPress': (
    ('overhead-press', 'Overhead press'),
    ('seated-db-press', 'Seated dumbbell press'),
    ('lib:Handstand_Push-Ups', 'Pike or wall handstand push-up'),
  ),
  'lateral': (
    ('lateral-raise', 'Lateral raise'),
    ('lateral-raise', 'Lateral raise'),
    ('lib:Lateral_Raise_-_With_Bands', 'Band lateral raise'),
  ),
  'rearDelt': (
    ('face-pull', 'Face pull'),
    ('rear-delt-fly', 'Rear delt fly'),
    ('lib:Band_Pull_Apart', 'Band pull-apart'),
  ),
  'vPull': (('lat-pulldown', 'Lat pulldown'), ('pull-up', 'Pull-up'), ('pull-up', 'Pull-up')),
  'hPull': (
    ('barbell-row', 'Barbell row'),
    ('lib:One-Arm_Dumbbell_Row', 'One-arm dumbbell row'),
    ('lib:Inverted_Row', 'Inverted row'),
  ),
  'cableRow': (
    ('seated-cable-row', 'Seated cable row'),
    ('lib:One-Arm_Dumbbell_Row', 'One-arm dumbbell row'),
    ('lib:Inverted_Row', 'Inverted row'),
  ),
  'shrug': (
    ('lib:Barbell_Shrug', 'Barbell shrug'),
    ('lib:Dumbbell_Shrug', 'Dumbbell shrug'),
    ('lib:Scapular_Pull-Up', 'Scapular pull-up'),
  ),
  'biceps': (
    ('barbell-curl', 'Barbell curl'),
    ('lib:Dumbbell_Bicep_Curl', 'Dumbbell curl'),
    ('lib:Chin-Up', 'Chin-up'),
  ),
  'hammer': (('hammer-curl', 'Hammer curl'), ('hammer-curl', 'Hammer curl'), ('lib:Chin-Up', 'Chin-up')),
  'triceps': (
    ('triceps-pushdown', 'Triceps pushdown'),
    ('lib:Lying_Dumbbell_Tricep_Extension', 'Lying dumbbell extension'),
    ('lib:Push-Ups_-_Close_Triceps_Position', 'Close-grip push-up'),
  ),
  'tricepsOverhead': (
    ('overhead-triceps', 'Overhead triceps extension'),
    ('overhead-triceps', 'Overhead triceps extension'),
    ('lib:Body_Tricep_Press', 'Bodyweight triceps press'),
  ),
  'forearm': (
    ('lib:Farmers_Walk', 'Farmer\'s walk'),
    ('lib:Palms-Up_Dumbbell_Wrist_Curl_Over_A_Bench', 'Dumbbell wrist curl'),
    ('lib:Wrist_Circles', 'Wrist circles'),
  ),
  'plank': (('plank', 'Plank'), ('plank', 'Plank'), ('plank', 'Plank')),
  'coreFlex': (
    ('hanging-knee-raise', 'Hanging knee raise'),
    ('hanging-knee-raise', 'Hanging knee raise'),
    ('lib:Reverse_Crunch', 'Reverse crunch'),
  ),
  'coreRot': (
    ('pallof-press', 'Pallof press'),
    ('russian-twist', 'Russian twist'),
    ('pallof-press', 'Pallof press (band)'),
  ),
  'deadBug': (('dead-bug', 'Dead bug'), ('dead-bug', 'Dead bug'), ('dead-bug', 'Dead bug')),
  'conditioning': (
    ('kettlebell-swing', 'Kettlebell swing'),
    ('lib:Mountain_Climbers', 'Mountain climbers'),
    ('lib:Mountain_Climbers', 'Mountain climbers'),
  ),
  'cardio': (
    ('lib:Rowing_Stationary', 'Rowing machine'),
    ('lib:Rope_Jumping', 'Jump rope'),
    ('lib:Rope_Jumping', 'Jump rope or brisk march'),
  ),
};

/// Calisthenics progressions: one step for each level.
const skillLadders = <String, (Ex, Ex, Ex)>{
  'cPush': (
    ('lib:Incline_Push-Up', 'Incline push-up'),
    ('push-up', 'Push-up'),
    ('lib:Single-Arm_Push-Up', 'One-arm push-up (assisted)'),
  ),
  'cDip': (
    ('lib:Bench_Dips', 'Bench dip'),
    ('lib:Dips_-_Triceps_Version', 'Parallel bar dip'),
    ('lib:Ring_Dips', 'Ring dip'),
  ),
  'cVPush': (
    ('lib:Push-Ups_With_Feet_Elevated', 'Feet-up push-up'),
    ('lib:Handstand_Push-Ups', 'Pike push-up to wall handstand push-up'),
    ('lib:Handstand_Push-Ups', 'Wall handstand push-up'),
  ),
  'cPull': (
    ('lib:Band_Assisted_Pull-Up', 'Band-assisted pull-up'),
    ('pull-up', 'Pull-up'),
    ('lib:Weighted_Pull_Ups', 'Weighted pull-up'),
  ),
  'cChin': (('lib:Scapular_Pull-Up', 'Scapular pull-up'), ('lib:Chin-Up', 'Chin-up'), ('lib:Muscle_Up', 'Muscle-up')),
  'cRow': (
    ('lib:Inverted_Row', 'Inverted row (high bar)'),
    ('lib:Inverted_Row', 'Inverted row (low bar)'),
    ('lib:Inverted_Row_with_Straps', 'Feet-up ring row'),
  ),
  'cSquat': (
    ('lib:Bodyweight_Squat', 'Bodyweight squat'),
    ('lib:Single-Leg_High_Box_Squat', 'Single-leg box squat'),
    ('lib:Kettlebell_Pistol_Squat', 'Pistol squat'),
  ),
  'cLunge': (
    ('lib:Bodyweight_Walking_Lunge', 'Walking lunge'),
    ('split-squat', 'Split squat (body weight)'),
    ('lib:Suspended_Split_Squat', 'Rear-foot-up split squat'),
  ),
  'cHinge': (
    ('glute-bridge', 'Glute bridge'),
    ('lib:Single_Leg_Glute_Bridge', 'Single-leg glute bridge'),
    ('lib:Natural_Glute_Ham_Raise', 'Nordic curl'),
  ),
  'cCore': (
    ('dead-bug', 'Dead bug'),
    ('hanging-knee-raise', 'Hanging knee raise'),
    ('lib:Hanging_Leg_Raise', 'Hanging leg raise'),
  ),
  'cHold': (('plank', 'Plank'), ('plank', 'Plank'), ('lib:Hanging_Pike', 'Hanging pike')),
  'calf': (
    ('calf-raise', 'Calf raise'),
    ('calf-raise', 'Single-leg calf raise'),
    ('calf-raise', 'Single-leg calf raise, slow'),
  ),
};

/// One planned slot before the generator picks sets and reps.
typedef _Slot = (String pattern, ItemKind kind);

const _m = ItemKind.main, _s = ItemKind.secondary, _a = ItemKind.accessory, _c = ItemKind.core, _f = ItemKind.finisher;

/// Day templates. Each name maps to a focus and its slots.
const _templates = <String, (String, List<_Slot>)>{
  // Muscle and look: full body
  'Full body A': (
    'Squat, push, pull',
    [('squat', _m), ('hPress', _m), ('hPull', _s), ('legCurl', _a), ('lateral', _a), ('triceps', _a), ('plank', _c)],
  ),
  'Full body B': (
    'Hinge, press, pull-down',
    [('hinge', _m), ('vPress', _m), ('vPull', _s), ('lunge', _a), ('rearDelt', _a), ('biceps', _a), ('coreFlex', _c)],
  ),
  'Full body C': (
    'Legs, upper chest, row',
    [
      ('quadPress', _m),
      ('inclinePress', _m),
      ('cableRow', _s),
      ('hipThrust', _a),
      ('lateral', _a),
      ('hammer', _a),
      ('coreRot', _c),
    ],
  ),
  // Upper and lower
  'Upper A': (
    'Chest and back, heavier',
    [('hPress', _m), ('hPull', _m), ('vPress', _s), ('vPull', _s), ('lateral', _a), ('biceps', _a), ('triceps', _a)],
  ),
  'Lower A': (
    'Squat focus',
    [('squat', _m), ('hinge', _s), ('lunge', _a), ('legCurl', _a), ('calf', _a), ('plank', _c)],
  ),
  'Upper B': (
    'Upper chest, back width, arms',
    [
      ('inclinePress', _m),
      ('vPull', _m),
      ('cableRow', _s),
      ('chestFly', _a),
      ('rearDelt', _a),
      ('hammer', _a),
      ('tricepsOverhead', _a),
    ],
  ),
  'Lower B': (
    'Hinge and glute focus',
    [('deadlift', _m), ('quadPress', _s), ('hipThrust', _a), ('quadIso', _a), ('calf', _a), ('coreFlex', _c)],
  ),
  // Push, pull, legs
  'Push': (
    'Chest, shoulders, triceps',
    [
      ('hPress', _m),
      ('inclinePress', _s),
      ('vPress', _s),
      ('lateral', _a),
      ('chestFly', _a),
      ('triceps', _a),
      ('tricepsOverhead', _a),
    ],
  ),
  'Pull': (
    'Back, rear shoulders, biceps',
    [('vPull', _m), ('hPull', _s), ('cableRow', _s), ('rearDelt', _a), ('shrug', _a), ('biceps', _a), ('hammer', _a)],
  ),
  'Legs': (
    'Quads, hamstrings, glutes, calves',
    [('squat', _m), ('hinge', _s), ('quadPress', _a), ('legCurl', _a), ('quadIso', _a), ('calf', _a), ('coreFlex', _c)],
  ),
  // Aesthetic: shoulders and arms day
  'Shoulders & arms': (
    'Width and arm size',
    [
      ('vPress', _m),
      ('lateral', _s),
      ('rearDelt', _a),
      ('biceps', _a),
      ('triceps', _a),
      ('hammer', _a),
      ('tricepsOverhead', _a),
    ],
  ),
  // Strength
  'Squat + bench': ('Heavy squat and bench', [('squat', _m), ('hPress', _m), ('hPull', _s), ('plank', _c)]),
  'Deadlift + press': (
    'Heavy deadlift and overhead press',
    [('deadlift', _m), ('vPress', _m), ('vPull', _s), ('coreFlex', _c)],
  ),
  'Squat + bench (light)': (
    'Lighter squat, more bench',
    [('squat', _m), ('hPress', _m), ('hinge', _s), ('cableRow', _a), ('triceps', _a)],
  ),
  'Bench + press': (
    'Upper body strength',
    [('hPress', _m), ('vPress', _s), ('hPull', _s), ('triceps', _a), ('rearDelt', _a)],
  ),
  'Squat + hinge': ('Lower body strength', [('squat', _m), ('hinge', _s), ('lunge', _a), ('plank', _c)]),
  'Press + bench volume': (
    'Overhead strength and bench volume',
    [('vPress', _m), ('hPress', _s), ('vPull', _s), ('biceps', _a), ('tricepsOverhead', _a)],
  ),
  'Deadlift + squat volume': (
    'Deadlift strength and squat volume',
    [('deadlift', _m), ('squat', _s), ('legCurl', _a), ('coreFlex', _c)],
  ),
  // Lean and fit
  'Strength circuit A': (
    'Full body + finisher',
    [('squat', _m), ('hPress', _m), ('hPull', _m), ('hinge', _a), ('plank', _c), ('conditioning', _f)],
  ),
  'Strength circuit B': (
    'Full body + finisher',
    [('lunge', _m), ('vPress', _m), ('vPull', _m), ('hipThrust', _a), ('coreRot', _c), ('conditioning', _f)],
  ),
  'Strength circuit C': (
    'Full body + finisher',
    [
      ('deadlift', _m),
      ('inclinePress', _m),
      ('cableRow', _m),
      ('quadPress', _a),
      ('deadBug', _c),
      ('conditioning', _f),
    ],
  ),
  'Cardio + core': ('Steady cardio and core', [('cardio', _f), ('plank', _c), ('coreRot', _c), ('deadBug', _c)]),
  // Calisthenics
  'Skills A': ('Pull, push, legs', [('cPull', _m), ('cPush', _m), ('cSquat', _s), ('cRow', _a), ('cCore', _c)]),
  'Skills B': ('Dip, chin, hinge', [('cDip', _m), ('cChin', _m), ('cHinge', _s), ('cVPush', _a), ('cHold', _c)]),
  'Skills C': (
    'Overhead push, row, single leg',
    [('cVPush', _m), ('cRow', _m), ('cLunge', _s), ('cPush', _a), ('cCore', _c)],
  ),
  'Upper skills': (
    'Pull-ups, dips, push-ups',
    [('cPull', _m), ('cDip', _m), ('cRow', _s), ('cPush', _s), ('cCore', _c)],
  ),
  'Lower skills': (
    'Squats, lunges, hinge',
    [('cSquat', _m), ('cHinge', _s), ('cLunge', _s), ('calf', _a), ('cHold', _c)],
  ),
  'Upper skills B': (
    'Overhead push, chin-ups',
    [('cVPush', _m), ('cChin', _m), ('cRow', _s), ('cDip', _s), ('cCore', _c)],
  ),
  'Lower skills B': (
    'Single-leg strength',
    [('cLunge', _m), ('cSquat', _s), ('cHinge', _s), ('calf', _a), ('cCore', _c)],
  ),
  'Skill practice': ('Handstand and pull-up skill, easy reps', [('cVPush', _s), ('cChin', _s), ('cHold', _c)]),
};

List<String> _split(RoadmapGoal g, int days, RoadmapLevel l) => switch (g) {
  RoadmapGoal.strength => switch (days) {
    2 => ['Squat + bench', 'Deadlift + press'],
    3 => ['Squat + bench', 'Deadlift + press', 'Squat + bench (light)'],
    _ => ['Bench + press', 'Squat + hinge', 'Press + bench volume', 'Deadlift + squat volume'],
  },
  RoadmapGoal.calisthenics => switch (days) {
    2 => ['Skills A', 'Skills B'],
    3 => ['Skills A', 'Skills B', 'Skills C'],
    4 => ['Upper skills', 'Lower skills', 'Upper skills B', 'Lower skills B'],
    _ => ['Upper skills', 'Lower skills', 'Skill practice', 'Upper skills B', 'Lower skills B'],
  },
  RoadmapGoal.leanFit => switch (days) {
    2 => ['Strength circuit A', 'Strength circuit B'],
    3 => ['Strength circuit A', 'Strength circuit B', 'Strength circuit C'],
    4 => ['Strength circuit A', 'Cardio + core', 'Strength circuit B', 'Strength circuit C'],
    5 => ['Strength circuit A', 'Cardio + core', 'Strength circuit B', 'Cardio + core', 'Strength circuit C'],
    _ => [
      'Strength circuit A',
      'Cardio + core',
      'Strength circuit B',
      'Cardio + core',
      'Strength circuit C',
      'Cardio + core',
    ],
  },
  RoadmapGoal.aesthetic => switch (days) {
    2 => ['Full body A', 'Full body B'],
    3 => ['Full body A', 'Full body B', 'Full body C'],
    4 => ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
    5 => ['Upper A', 'Lower A', 'Shoulders & arms', 'Upper B', 'Lower B'],
    _ => ['Push', 'Pull', 'Legs', 'Shoulders & arms', 'Upper B', 'Lower B'],
  },
  RoadmapGoal.bodybuilding => switch (days) {
    2 => ['Full body A', 'Full body B'],
    3 => l == RoadmapLevel.beginner ? ['Full body A', 'Full body B', 'Full body C'] : ['Push', 'Pull', 'Legs'],
    4 => ['Upper A', 'Lower A', 'Upper B', 'Lower B'],
    5 => ['Upper A', 'Lower A', 'Push', 'Pull', 'Legs'],
    _ => ['Push', 'Pull', 'Legs', 'Push', 'Pull', 'Legs'],
  },
};

/// Sets, reps, rest (s), and reps in reserve for one slot.
typedef _Dose = (int sets, int low, int high, int rest, int rir);

_Dose _dose(RoadmapGoal g, RoadmapLevel l, ItemKind k) {
  final lv = l.index; // 0 beginner, 1 intermediate, 2 advanced
  final rir = [3, 2, 1][lv];
  // At least 3 working sets on every exercise (owner request 2026-10-08).
  int sets(List<int> s) => s[lv] < 3 ? 3 : s[lv];
  return switch ((g, k)) {
    (RoadmapGoal.strength, ItemKind.main) => (sets([3, 4, 5]), lv == 0 ? 5 : 3, 5, 180, rir),
    (RoadmapGoal.strength, ItemKind.secondary) => (sets([2, 3, 3]), 5, 8, 150, rir),
    (RoadmapGoal.strength, _) => (sets([2, 3, 3]), 8, 12, 90, 2),
    (RoadmapGoal.calisthenics, ItemKind.main) => (sets([3, 4, 5]), 5, 10, 120, rir),
    (RoadmapGoal.calisthenics, ItemKind.secondary) => (sets([3, 3, 4]), 6, 12, 90, rir),
    (RoadmapGoal.calisthenics, _) => (sets([2, 3, 3]), 8, 15, 60, 2),
    (RoadmapGoal.leanFit, ItemKind.main) => (sets([2, 3, 3]), 8, 12, 75, rir),
    (RoadmapGoal.leanFit, _) => (sets([2, 2, 3]), 12, 15, 60, 2),
    (_, ItemKind.main) => (sets([3, 3, 4]), 6, 10, 150, rir),
    (_, ItemKind.secondary) => (sets([2, 3, 4]), 8, 12, 120, rir),
    (RoadmapGoal.bodybuilding, _) => (sets([2, 3, 4]), 10, 15, 75, lv == 2 ? 0 : rir.clamp(1, 2)),
    (_, _) => (sets([2, 3, 3]), 10, 15, 75, rir.clamp(1, 2)),
  };
}

Ex _pick(String pattern, GymSetup setup, RoadmapLevel level) {
  final ladder = skillLadders[pattern];
  if (ladder != null) {
    return [ladder.$1, ladder.$2, ladder.$3][level.index];
  }
  // Most beginners cannot do a full pull-up yet. Everyone else does the
  // pull-up, in any setup.
  if (pattern == 'vPull') {
    if (level != RoadmapLevel.beginner) return ('pull-up', 'Pull-up');
    return setup == GymSetup.fullGym
        ? ('lat-pulldown', 'Lat pulldown')
        : ('lib:Band_Assisted_Pull-Up', 'Band-assisted pull-up');
  }
  final p = patterns[pattern]!;
  return [p.$1, p.$2, p.$3][setup.index];
}

PlanItem _work(String pattern, ItemKind kind, RoadmapGoal g, RoadmapLevel l, GymSetup setup) {
  final (id, name) = _pick(pattern, setup, l);
  if (pattern == 'cardio') {
    return PlanItem(
      kind: kind,
      exerciseId: id,
      name: name,
      pattern: pattern,
      seconds: [20, 25, 30][l.index] * 60,
      note: 'Steady pace. You can talk in short sentences.',
    );
  }
  if (pattern == 'conditioning') {
    return PlanItem(
      kind: kind,
      exerciseId: id,
      name: name,
      pattern: pattern,
      sets: [5, 6, 8][l.index],
      seconds: 30,
      restSec: 30,
      note: '30 s hard, 30 s easy. Keep good form.',
    );
  }
  if (pattern == 'plank' || (pattern == 'cHold' && l != RoadmapLevel.advanced)) {
    return PlanItem(
      kind: kind,
      exerciseId: id,
      name: name,
      pattern: pattern,
      sets: 3,
      seconds: [30, 45, 60][l.index],
      restSec: 60,
    );
  }
  final (sets, low, high, rest, rir) = _dose(g, l, kind);
  return PlanItem(
    kind: kind,
    exerciseId: id,
    name: name,
    pattern: pattern,
    sets: sets,
    repsLow: low,
    repsHigh: high,
    restSec: rest,
    rir: rir,
  );
}

bool _isLower(List<_Slot> slots) =>
    slots
        .where(
          (s) =>
              const {'squat', 'hinge', 'deadlift', 'lunge', 'quadPress', 'cSquat', 'cLunge', 'cHinge'}.contains(s.$1),
        )
        .length >=
    slots.length / 2;

/// Warm-up: 5 minutes of easy cardio, then 3–4 moves for the joints the
/// day uses. Ramp-up sets of the first lift are marked on that lift.
List<PlanItem> _warmup(bool lower, GymSetup setup) {
  final cardio = switch (setup) {
    GymSetup.fullGym => ('lib:Recumbent_Bike', 'Easy bike or rower'),
    GymSetup.dumbbells => ('lib:Rope_Jumping', 'Easy jump rope or brisk walk'),
    GymSetup.home => ('lib:Rope_Jumping', 'March or jog on the spot'),
  };
  final moves = lower
      ? const [
          ('lib:Worlds_Greatest_Stretch', 'World\'s greatest stretch', 5, 'Each side. Slow.'),
          ('lib:Groiners', 'Groiners', 8, 'Each side.'),
          ('lib:Standing_Hip_Circles', 'Hip circles', 8, 'Each direction.'),
          ('lib:Bodyweight_Squat', 'Bodyweight squat', 10, 'Easy. Full depth you can control.'),
        ]
      : const [
          ('lib:Arm_Circles', 'Arm circles', 10, 'Small to big, both directions.'),
          ('lib:Band_Pull_Apart', 'Band pull-apart', 15, 'Light band. Squeeze the shoulder blades.'),
          ('lib:Dynamic_Chest_Stretch', 'Dynamic chest stretch', 10, 'Open the arms wide, then hug.'),
          ('lib:Cat_Stretch', 'Cat-cow', 8, 'Move the whole spine slowly.'),
        ];
  return [
    PlanItem(
      kind: ItemKind.warmup,
      exerciseId: cardio.$1,
      name: cardio.$2,
      seconds: 300,
      note: 'Get warm and a little out of breath.',
    ),
    for (final (id, name, reps, note) in moves)
      PlanItem(kind: ItemKind.warmup, exerciseId: id, name: name, repsLow: reps, note: note),
  ];
}

List<PlanItem> _cooldown(bool lower) => lower
    ? const [
        PlanItem(
          kind: ItemKind.cooldown,
          exerciseId: 'lib:Kneeling_Hip_Flexor',
          name: 'Kneeling hip flexor stretch',
          seconds: 45,
          note: 'Each side.',
        ),
        PlanItem(
          kind: ItemKind.cooldown,
          exerciseId: 'lib:Hamstring_Stretch',
          name: 'Hamstring stretch',
          seconds: 45,
          note: 'Each side.',
        ),
      ]
    : const [
        PlanItem(
          kind: ItemKind.cooldown,
          exerciseId: 'lib:Chest_And_Front_Of_Shoulder_Stretch',
          name: 'Chest and shoulder stretch',
          seconds: 45,
        ),
        PlanItem(kind: ItemKind.cooldown, exerciseId: 'lib:Childs_Pose', name: 'Child\'s pose', seconds: 60),
      ];

const _weekdays = {
  2: [1, 4],
  3: [1, 3, 5],
  4: [1, 2, 4, 5],
  5: [1, 2, 3, 5, 6],
  6: [1, 2, 3, 4, 5, 6],
};

String _progression(RoadmapGoal g, RoadmapLevel l) => switch ((g, l)) {
  (RoadmapGoal.strength, RoadmapLevel.beginner) =>
    'Add weight every session while form stays clean: 2.5 kg (5 lb) on upper lifts, 5 kg (10 lb) on squat and '
        'deadlift. If you miss reps twice in a row, take 10% off and build back up.',
  (RoadmapGoal.strength, _) =>
    'Add weight each week, not each session. When all sets hit the top reps with 1–2 reps left, add 2.5–5 kg. '
        'Use the calculator to set loads from your best recent set.',
  (RoadmapGoal.calisthenics, _) =>
    'Stay on a step until you can do every set at the top of the rep range with good form. Then move to the '
        'next step of the same movement (swap the exercise in the day).',
  (RoadmapGoal.leanFit, _) =>
    'Each week add one rep or a little weight to the strength work. Make the finisher a little harder: one more '
        'round, or a faster pace. Pair this with the eating targets in Meal.',
  (_, RoadmapLevel.beginner) =>
    'Double progression: stay at one weight until you hit the top of the rep range on every set, then add the '
        'smallest step (2.5 kg / 5 lb). Most beginners can add weight every week.',
  (_, _) =>
    'Double progression with 1–2 reps left in the tank. Add sets to lagging muscles before adding new '
        'exercises. Change an exercise only when it stops progressing for 3–4 weeks.',
};

String _deload(RoadmapLevel l) => switch (l) {
  RoadmapLevel.beginner =>
    'No planned easy week. If you feel run down for a week, or progress stops twice in a row, do one week with '
        'half the sets and the same weights.',
  RoadmapLevel.intermediate => 'Every 6–8 weeks, do one easy week: half the sets, same weights, more reps left.',
  RoadmapLevel.advanced =>
    'Every 4–6 weeks, do one easy week: half the sets and about 10% lighter. Then start the next block a '
        'little heavier.',
};

/// Builds a roadmap. [days] must be one of [RoadmapGoal.dayOptions].
ProgramPlan buildProgram({
  required RoadmapGoal goal,
  required RoadmapLevel level,
  required GymSetup setup,
  int? days,
}) {
  final n = days ?? goal.defaultDays(level);
  if (!goal.dayOptions.contains(n)) throw ArgumentError.value(days, 'days', 'Not supported for ${goal.label}');
  final names = _split(goal, n, level);
  final counts = <String, int>{};
  final out = <PlanDay>[];
  for (final name in names) {
    final (focus, slots) = _templates[name]!;
    var items = <PlanItem>[];
    for (final (pattern, kind) in slots) {
      items.add(_work(pattern, kind, goal, level, setup));
    }
    // Beginners: fewer extras so sessions stay near an hour.
    if (level == RoadmapLevel.beginner && goal != RoadmapGoal.strength) {
      var extras = items.where((i) => i.kind == ItemKind.accessory).length;
      items = [
        for (final i in items)
          if (i.kind != ItemKind.accessory || extras-- > 2) i,
      ];
    }
    // Ramp up into the first loaded main lift of the day. Ramp-up sets are
    // shares of a working weight, so body-weight moves do not get them.
    final first = setup == GymSetup.home
        ? -1
        : items.indexWhere(
            (i) =>
                i.kind == ItemKind.main &&
                i.seconds == null &&
                i.pattern != 'vPull' &&
                !skillLadders.containsKey(i.pattern),
          );
    if (first >= 0) items[first] = items[first].copyWith(rampUp: true);
    final lower = _isLower(slots);
    final label = counts.update(name, (c) => c + 1, ifAbsent: () => 1) > 1 ? '$name 2' : name;
    out.add(
      PlanDay(name: label, focus: focus, items: [..._warmup(lower, setup), ...items, ..._cooldown(lower)]),
    );
  }
  return ProgramPlan(
    goal: goal,
    level: level,
    setup: setup,
    days: out,
    weekdays: _weekdays[n]!,
    progression: _progression(goal, level),
    deload: _deload(level),
  );
}

/// Exercises the user can swap in for [item]: the same pattern in every
/// equipment setup, and every step of a skill ladder.
List<Ex> alternativesFor(PlanItem item) {
  // Older saved roadmaps call the pull-up slot 'pullUp'.
  final p = item.pattern == 'pullUp' ? 'vPull' : item.pattern;
  if (p == null) return const [];
  final row = patterns[p] ?? skillLadders[p];
  if (row == null) return const [];
  final seen = <String>{};
  return [
    for (final e in [row.$1, row.$2, row.$3])
      if (seen.add(e.$1)) e,
  ];
}

/// Warm-up sets before the first working set, as shares of the working
/// weight: about 50% × 8, 70% × 5, 85% × 3. Beginners skip the heaviest.
/// A plan without a level uses the full three.
List<(double share, int reps)> rampUpSets(RoadmapLevel? level) =>
    level == RoadmapLevel.beginner ? const [(0.5, 8), (0.7, 5)] : const [(0.5, 8), (0.7, 5), (0.85, 3)];

/// The ramp-up sets as text: "50% × 8, 70% × 5".
String rampUpText(RoadmapLevel? level) => rampUpSets(level).map((r) => '${(r.$1 * 100).round()}% × ${r.$2}').join(', ');

/// Rest as text: "45 s", "2 min", "1:30 min".
String restText(int seconds) => seconds < 60
    ? '$seconds s'
    : seconds % 60 == 0
    ? '${seconds ~/ 60} min'
    : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')} min';

/// Hard sets each pattern gets in a week, for checking balance.
Map<String, int> weeklySetsByPattern(ProgramPlan plan) {
  final m = <String, int>{};
  for (final d in plan.days) {
    for (final i in d.work) {
      if (i.pattern == null) continue;
      m[i.pattern!] = (m[i.pattern!] ?? 0) + i.sets;
    }
  }
  return m;
}

/// One exercise of a plan from an older app version (schema v4 and before),
/// or from an AI proposal.
typedef SimpleItem = ({String exerciseId, String name, int? sets, int? reps});

/// A one-day plan made from a list of exercises with optional targets.
///
/// A missing target stays missing: the item gets one set and no reps, which
/// starts as one empty set, as before.
PlanDay simpleDay(String name, List<SimpleItem> items, {String focus = ''}) => PlanDay(
  name: name,
  focus: focus,
  items: [
    for (final i in items)
      PlanItem(
        kind: ItemKind.accessory,
        exerciseId: i.exerciseId,
        name: i.name,
        sets: i.sets == null || i.sets! < 1 ? 1 : i.sets!,
        repsLow: i.reps,
        repsHigh: i.reps,
      ),
  ],
);

/// An empty day for a plan the user makes.
PlanDay emptyDay(int number) => PlanDay(name: 'Day $number', focus: '', items: const []);
