/// Guided workout rules: set time, rest, and spoken cues (handbook 4.13).
///
/// Pure functions, so the timing can be tested without a clock or audio.
library;

import 'voice_names.dart';

/// Seconds a set takes when the user has not set a time: about 3 s a rep
/// (a controlled lift), from 20 to 90 s. Without reps, 40 s.
int estimateSetSec(int? reps) => reps == null || reps <= 0 ? 40 : (reps * 3).clamp(20, 90);

/// Sets a new exercise starts with (owner request 2026-10-08).
const defaultSetCount = 3;

/// Rest after the whole warm-up, when the user has not chosen one. There
/// is no rest between warm-up moves: the next move starts at once.
const defaultWarmupRestSec = 60;

/// Rest after a lighter ramp-up set of a main lift.
const rampUpRestSec = 60;

/// Rest after a working set when neither the plan nor the user set one.
const defaultRestSec = 90;

/// Reps a set aims for, read from an exercise note such as
/// "Target: 3 × 8–12 · 2 min rest". The top of a range is used.
/// A warm-up move's note, "Warm-up · 8 reps · Move slowly.", gives 8.
int? targetRepsFromNote(String? note) {
  if (note == null) return null;
  final m = RegExp(r'Target: (?:\d+ × )?(\d+)(?:–(\d+))?(?: reps)?(?: ·|$|\n)').firstMatch(note);
  if (m != null) return int.tryParse(m.group(2) ?? m.group(1)!);
  final w = RegExp(r'^Warm-up · (\d+) reps').firstMatch(note);
  return w == null ? null : int.parse(w.group(1)!);
}

/// Reps for the ramp-up set at [index] (0 for the first), read from a note
/// such as "Ramp-up sets first: 50% × 8, 70% × 5 of your working weight".
/// Returns the share of the working weight too, or null when the note has
/// no ramp-up line or fewer ramp-up sets.
({int percent, int reps})? rampUpFromNote(String? note, int index) {
  if (note == null || index < 0) return null;
  final line = RegExp(r'Ramp-up sets first: ([^\n]*)').firstMatch(note)?.group(1);
  if (line == null) return null;
  final all = RegExp(r'(\d+)% × (\d+)').allMatches(line).toList();
  if (index >= all.length) return null;
  return (percent: int.parse(all[index].group(1)!), reps: int.parse(all[index].group(2)!));
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

/// How weight changes from one working set to the next.
enum LoadStyle {
  /// The same weight and reps each set (straight sets).
  same,

  /// A little more weight and 2 fewer reps each set (an ascending pyramid).
  pyramid,
}

/// The weight and reps the next working set aims for, after a set of
/// [load] × [reps]. A pyramid adds 2.5 kg (5 lb) and takes off 2 reps,
/// down to 1. Missing values stay missing.
({double? load, int? reps}) nextAim({double? load, int? reps, String? unit, LoadStyle style = LoadStyle.same}) {
  if (style == LoadStyle.same) return (load: load, reps: reps);
  final step = unit == 'lb' ? 5.0 : 2.5;
  return (load: load == null ? null : load + step, reps: reps == null || reps <= 1 ? reps : (reps - 2).clamp(1, reps));
}

/// Voice clip names in `assets/voice/<voice>/`.
abstract final class Clips {
  static const go = 'go';
  static const warmup = 'warmup';
  static const lastSet = 'last_set';
  static const halfway = 'halfway';
  static const time = 'time';
  static const tenLeft = 'ten_left';
  static const three = 'three';
  static const two = 'two';
  static const one = 'one';
  static const restOver = 'rest_over';
  static const nextExercise = 'next_exercise';
  static const paused = 'paused';
  static const resumed = 'resumed';
  static const done = 'done';

  static const _rests = [30, 45, 60, 90, 120, 150, 180, 240];

  /// "Next up: Bench press." for an exercise the voice can name, else null.
  static String? nextUp(String? catalogId) =>
      catalogId != null && spokenExercises.contains(catalogId) ? 'names/${voiceKey(catalogId)}' : null;

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
    three,
    two,
    one,
    restOver,
    nextExercise,
    paused,
    resumed,
    done,
  ];
}

/// Spoken cues the user can turn off one by one (Me → Training).
enum Cue {
  /// "Halfway." in a timed set of 30 s or more.
  halfway,

  /// "Ten seconds." before the end of a rest of 20 s or more.
  tenLeft,

  /// "Three", "Two", "One", a word a second, before the end of a rest or a
  /// timed set of 8 s or more.
  countdown,

  /// "Time! Good set." at the end of a timed set, and "Rest is up." at the
  /// end of a rest.
  end,
}

/// A cue [at] seconds into a set or a rest.
typedef TimedCue = ({int at, String clip});

/// The cues of a timed set of [target] seconds. A [target] of 0 means the
/// user ends the set, so there are none.
List<TimedCue> setPlan(int target, Set<Cue> on) => target <= 0
    ? const []
    : [
        if (on.contains(Cue.halfway) && target >= 30) (at: target ~/ 2, clip: Clips.halfway),
        if (on.contains(Cue.countdown) && target >= 8) ..._countdown(target),
        if (on.contains(Cue.end)) (at: target, clip: Clips.time),
      ];

/// The cues of a rest of [target] seconds. With [autoStart] the next set
/// starts at [target] and its own cue ("Set two. Go!") ends the rest.
List<TimedCue> restPlan(int target, Set<Cue> on, {required bool autoStart}) => [
  if (on.contains(Cue.tenLeft) && target >= 20) (at: target - 10, clip: Clips.tenLeft),
  if (on.contains(Cue.countdown) && target >= 8) ..._countdown(target),
  if (on.contains(Cue.end) && !autoStart) (at: target, clip: Clips.restOver),
];

List<TimedCue> _countdown(int target) => [
  (at: target - 3, clip: Clips.three),
  (at: target - 2, clip: Clips.two),
  (at: target - 1, clip: Clips.one),
];

/// The cue to say for the step from [before] to [now] seconds, or null.
///
/// Only the latest cue crossed is said, and only within 2 s of its time: a
/// late tick, such as after the phone was locked, says nothing stale.
String? cueBetween(List<TimedCue> plan, int before, int now) {
  TimedCue? hit;
  for (final c in plan) {
    if (before < c.at && c.at <= now) hit = c;
  }
  return hit == null || now - hit.at > 2 ? null : hit.clip;
}

/// Clip file name for a catalog ID, as tool/voice/names.py makes it:
/// 'lib:Barbell_Shrug' -> 'lib_barbell_shrug'.
String voiceKey(String catalogId) =>
    catalogId.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
