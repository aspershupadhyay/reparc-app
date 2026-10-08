/// Guided workout rules: set time, rest, and spoken cues (handbook 4.13).
///
/// Pure functions, so the timing can be tested without a clock or audio.
library;

/// Seconds a set takes when the user has not set a time: about 3 s a rep
/// (a controlled lift), from 20 to 90 s. Without reps, 40 s.
int estimateSetSec(int? reps) => reps == null || reps <= 0 ? 40 : (reps * 3).clamp(20, 90);

/// Rest after a warm-up move, before the next move.
const warmupMoveRestSec = 20;

/// Rest after a lighter ramp-up set of a main lift.
const rampUpRestSec = 60;

/// Rest after a working set when neither the plan nor the user set one.
const defaultRestSec = 90;

/// Reps a set aims for, read from an exercise note such as
/// "Target: 3 × 8–12 · 2 min rest". The top of a range is used.
int? targetRepsFromNote(String? note) {
  if (note == null) return null;
  final m = RegExp(r'Target: (?:\d+ × )?(\d+)(?:–(\d+))?(?: reps)?(?: ·|$|\n)').firstMatch(note);
  if (m == null) return null;
  return int.tryParse(m.group(2) ?? m.group(1)!);
}

/// Rest in seconds read from an exercise note: "2 min rest", "1:30 min
/// rest", or "45 s rest". Null when the note has none.
int? restFromNote(String? note) {
  if (note == null) return null;
  final m = RegExp(r'(\d+)(?::(\d{2}))? (min|s) rest').firstMatch(note);
  if (m == null) return null;
  final a = int.parse(m.group(1)!);
  return m.group(3) == 's' ? a : a * 60 + int.parse(m.group(2) ?? '0');
}

/// Voice clip names in `assets/voice/<voice>/`.
abstract final class Clips {
  static const go = 'go';
  static const warmup = 'warmup';
  static const lastSet = 'last_set';
  static const halfway = 'halfway';
  static const time = 'time';
  static const tenLeft = 'ten_left';
  static const countdown = 'countdown';
  static const restOver = 'rest_over';
  static const nextExercise = 'next_exercise';
  static const paused = 'paused';
  static const resumed = 'resumed';
  static const done = 'done';

  static const _rests = [30, 45, 60, 90, 120, 150, 180, 240];

  /// "Set three. Go!" for sets 1–10, else "Go!".
  static String set(int number) => number >= 1 && number <= 10 ? 'set_$number' : go;

  /// "Rest. Ninety seconds." when a clip says that time, else "Rest started."
  static String rest(int seconds) => _rests.contains(seconds) ? 'rest_$seconds' : 'rest';

  /// Every clip name, for checks that the files exist.
  static List<String> get all => [
    for (var i = 1; i <= 10; i++) 'set_$i',
    go,
    warmup,
    lastSet,
    halfway,
    time,
    'rest',
    for (final r in _rests) 'rest_$r',
    tenLeft,
    countdown,
    restOver,
    nextExercise,
    paused,
    resumed,
    done,
  ];
}

/// Cues to say while a set runs, for the step from [before] to [now]
/// seconds into a set of [target] seconds.
List<String> setCues(int before, int now, int target) => [
  if (target >= 30 && before < target ~/ 2 && now >= target ~/ 2 && now < target) Clips.halfway,
  if (before < target && now >= target) Clips.time,
];

/// Cues to say while a rest runs, for the step from [before] to [now]
/// seconds into a rest of [target] seconds. The next set starts at
/// [target]; its own cue says "Set two. Go!".
List<String> restCues(int before, int now, int target) => [
  if (target >= 20 && before < target - 10 && now >= target - 10 && now < target - 3) Clips.tenLeft,
  if (target >= 8 && before < target - 3 && now >= target - 3 && now < target) Clips.countdown,
];
