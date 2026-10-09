import '../rig/anatomy.dart';
import 'library.dart';

/// The third step of the browse tree: inside one muscle, moves group by
/// the part they stress most, for example the triceps long head.
///
/// A move joins the first group whose words appear in its name. Moves that
/// match no group, and every stretch or jump, fall into the closing groups,
/// so each move shows exactly once.
class MoveGroup {
  const MoveGroup(this.label, this.hint, this.words);

  final String label;

  /// Short words on what this group does, shown under its heading.
  final String hint;
  final List<String> words;

  bool matches(String name) => words.any(name.contains);
}

const muscleGroups = <Muscle, List<MoveGroup>>{
  Muscle.triceps: [
    MoveGroup('Lateral head', 'Pushdowns and kickbacks: arms at your sides', [
      'pushdown',
      'push-down',
      'pressdown',
      'press-down',
      'kickback',
    ]),
    MoveGroup('Long head', 'Arms overhead or angled back: a deep stretch', [
      'overhead',
      'skull',
      'lying',
      'french',
      'extension',
      'tate',
    ]),
    MoveGroup('Heavy presses', 'Close-grip presses and dips: most weight', [
      'press',
      'dip',
      'push-up',
      'pushup',
    ]),
  ],
  Muscle.biceps: [
    MoveGroup('Brachialis', 'Neutral grip curls: thicker arms', [
      'hammer',
      'cross body',
      'cross-body',
      'zottman',
      'pinwheel',
      'brachialis',
    ]),
    MoveGroup('Long head', 'Arms behind the body: the peak', ['incline', 'drag', 'lying']),
    MoveGroup('Short head', 'Arms in front of the body: the inner biceps', [
      'preacher',
      'concentration',
      'spider',
      'scott',
      'wide',
      'machine',
    ]),
    MoveGroup('Standard curls', 'Classic curls: both heads', ['curl']),
  ],
  Muscle.forearms: [
    MoveGroup('Grip', 'Carries and holds: stronger hands', [
      'farmer',
      'hang',
      'pinch',
      'grip',
      'roller',
      'walk',
      'squeeze',
      'hold',
    ]),
    MoveGroup('Wrist extensors', 'Back of the forearm', ['palms-down', 'reverse', 'extension']),
    MoveGroup('Wrist flexors', 'Inside of the forearm', ['wrist curl', 'palms-up']),
  ],
  Muscle.chest: [
    MoveGroup('Presses', 'Push weight away: most size and strength', ['press', 'push-up', 'pushup']),
    MoveGroup('Flyes and pullovers', 'Arms move in an arc: a deep stretch', [
      'fly',
      'flye',
      'crossover',
      'cross over',
      'pec deck',
      'butterfly',
      'pullover',
      'iron cross',
      'around the world',
    ]),
  ],
  Muscle.lowerChest: [
    MoveGroup('Dips', 'Push up between bars: most of the lower chest', ['dip']),
    MoveGroup('Decline presses', 'Push weight away, head lower than hips', ['press', 'push-up', 'pushup']),
    MoveGroup('Flyes and pullovers', 'Arms move in an arc', ['fly', 'flye', 'pullover']),
  ],
  Muscle.upperChest: [
    MoveGroup('Presses', 'Push weight away on an incline', ['press', 'push-up', 'pushup']),
    MoveGroup('Flyes', 'Hug an arc on an incline', ['fly', 'flye', 'crossover']),
  ],
  Muscle.lats: [
    MoveGroup('Pull-ups and pulldowns', 'Pull from overhead', [
      'pull-up',
      'pullup',
      'pull up',
      'chin',
      'climb',
      'pulldown',
      'pull down',
      'muscle up',
      'muscle-up',
    ]),
    MoveGroup('Straight-arm', 'Arms stay long: lats only', ['pullover', 'straight-arm', 'straight arm']),
    MoveGroup('Rows', 'Pull to the hip', ['row']),
  ],
  Muscle.upperBack: [
    MoveGroup('Rows', 'Pull to the chest or ribs', ['row', 'bench pull']),
    MoveGroup('Rear flyes and pulls', 'Squeeze the shoulder blades', ['fly', 'flye', 'pull apart', 'face pull']),
  ],
  Muscle.traps: [
    MoveGroup('Shrugs', 'Lift the shoulders to the ears', ['shrug']),
    MoveGroup('Upright rows and pulls', 'Pull up close to the body', ['upright', 'high pull']),
    MoveGroup('Neck', 'Hold the head still against a push', ['neck']),
  ],
  Muscle.lowerBack: [
    MoveGroup('Back extensions', 'Lift the chest from a bench: low back only', [
      'hyperextension',
      'extension',
      'superman',
    ]),
    MoveGroup('Deadlifts and good mornings', 'Heavy hip hinges', ['deadlift', 'good morning', 'rack pull']),
  ],
  Muscle.frontDelts: [
    MoveGroup('Overhead presses', 'Press up: most weight', ['press', 'push']),
    MoveGroup('Front raises', 'Lift in front: front delt only', ['raise']),
    MoveGroup('Kettlebell and Olympic lifts', 'Fast whole-body lifts', [
      'jerk',
      'snatch',
      'clean',
      'thruster',
      'get-up',
      'jammer',
    ]),
  ],
  Muscle.sideDelts: [
    MoveGroup('Lateral raises', 'Lift out to the side', ['lateral', 'side', 'raise', 'scaption', 'iron cross']),
    MoveGroup('Upright rows', 'Pull up, elbows high', ['upright']),
  ],
  Muscle.rearDelts: [
    MoveGroup('Rear flyes and raises', 'Arms out wide, lean forward', [
      'fly',
      'flye',
      'raise',
      'lateral',
      'pull apart',
    ]),
    MoveGroup('Rows and face pulls', 'Pull to the face, elbows high', ['row', 'face pull']),
    MoveGroup('Rotator cuff', 'Small turns that protect the shoulder', ['rotation']),
  ],
  Muscle.quads: [
    MoveGroup('Squats', 'Both legs, most weight', ['squat']),
    MoveGroup('Lunges and step-ups', 'One leg at a time: balance', ['lunge', 'split', 'step']),
    MoveGroup('Machines', 'Guided path: easy to push hard', ['leg press', 'extension', 'hack', 'sled']),
  ],
  Muscle.hamstrings: [
    MoveGroup('Hip hinges', 'Bend at the hips: stretch under load', [
      'deadlift',
      'good morning',
      'hinge',
      'swing',
      'pull through',
      'hyperextension',
    ]),
    MoveGroup('Leg curls', 'Bend the knee: hamstrings only', ['curl', 'glute ham', 'glute-ham', 'nordic', 'slide']),
    MoveGroup('Olympic lifts', 'Fast pulls from the floor or hang', ['clean', 'snatch']),
  ],
  Muscle.calves: [
    MoveGroup('Seated raises', 'Bent knees: the lower calf', ['seated']),
    MoveGroup('Standing raises', 'Straight knees: the big calf muscle', ['standing', 'donkey', 'calf press', 'raise']),
  ],
  Muscle.glutes: [
    MoveGroup('Thrusts and bridges', 'Push the hips up', ['thrust', 'bridge', 'hip lift', 'butt lift']),
    MoveGroup('Kickbacks', 'One leg back', ['kickback', 'donkey', 'hydrant', 'hip extension', 'leg lift']),
    MoveGroup('Hinges and swings', 'Bend at the hips', ['deadlift', 'swing', 'pull through']),
    MoveGroup('Squats and step-ups', 'Knees and hips together', ['squat', 'step']),
  ],
  Muscle.adductors: [
    MoveGroup('Adduction', 'Squeeze the legs together', ['adduct']),
  ],
  Muscle.abductors: [
    MoveGroup('Abduction', 'Push the legs apart', ['abduct', 'monster', 'walk']),
  ],
  Muscle.abs: [
    MoveGroup('Crunches', 'Curl the spine', [
      'crunch',
      'sit-up',
      'situp',
      'jackknife',
      'pull-in',
      'heel touch',
      'elbow to knee',
      'cocoon',
      'butt-up',
      'bottoms up',
    ]),
    MoveGroup('Bracing', 'Hold still against a pull', ['plank', 'dead bug', 'rollout', 'roller', 'fallout', 'hollow']),
  ],
  Muscle.lowerAbs: [
    MoveGroup('Hanging', 'From a bar: hardest', ['hanging', 'parallel bars']),
    MoveGroup('Floor and bench', 'Lift the legs or curl the hips', ['raise', 'crunch', 'tuck', 'scissor', 'flutter']),
  ],
  Muscle.obliques: [
    MoveGroup('Rotation', 'Twist with control', ['twist', 'wood', 'russian', 'rotation', 'chop']),
    MoveGroup('Anti-rotation', 'Resist a twist', ['pallof', 'side plank', 'side bridge', 'suitcase']),
    MoveGroup('Side bends', 'Bend to the side', ['side bend', 'oblique crunch', 'windmill', 'jackknife']),
  ],
};

/// Closing groups that every muscle shares.
const otherStrength = MoveGroup('More moves', 'Other ways to train it', []);
const stretchGroup = MoveGroup('Stretches', 'For range of motion. Not for size', []);
const powerGroup = MoveGroup('Power and cardio', 'Jumps, throws, and conditioning', []);

/// The group [m] belongs to inside its target muscle.
MoveGroup groupOf(Move m) {
  if (m.kind == MoveKind.stretch) return stretchGroup;
  if (m.kind == MoveKind.power) return powerGroup;
  final name = m.name.toLowerCase();
  for (final g in muscleGroups[m.target] ?? const <MoveGroup>[]) {
    if (g.matches(name)) return g;
  }
  return otherStrength;
}

/// Groups for [muscle] in display order, with the moves in each. Empty
/// groups are left out.
List<(MoveGroup, List<Move>)> groupMoves(Muscle muscle, Iterable<Move> moves) {
  final order = [...?muscleGroups[muscle], otherStrength, stretchGroup, powerGroup];
  final by = <MoveGroup, List<Move>>{};
  for (final m in moves) {
    (by[groupOf(m)] ??= []).add(m);
  }
  return [
    for (final g in order)
      if (by[g] case final list?) (g, list),
  ];
}

/// Moves that can stand in for [current]: same target muscle and kind,
/// best first. Best means the same group (the same job for the muscle),
/// then different equipment (the usual reason to swap: the rack is taken),
/// then hand-picked moves, then shorter names.
List<Move> swapsFor(ExerciseLibrary lib, Move current) {
  final group = groupOf(current);
  final list = [
    for (final m in lib.moves)
      if (m.target == current.target && m.kind == current.kind && m.catalogId != current.catalogId) m,
  ];
  int rank(Move m) =>
      (groupOf(m) == group ? 0 : 4) +
      (m.equipKind != current.equipKind ? 0 : 2) +
      (m.coached != null || lib.essentialIds.contains(m.catalogId) ? 0 : 1);
  final ranks = {for (final m in list) m: rank(m)};
  return list..sort((a, b) {
    final r = ranks[a]!.compareTo(ranks[b]!);
    return r != 0 ? r : a.name.length.compareTo(b.name.length);
  });
}
