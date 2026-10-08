import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/screen_awake.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';
import '../../data/workout_repository.dart';
import '../../domain/guide.dart';
import 'rest_alert.dart';
import 'voice.dart';

enum GuidePhase { idle, set, rest }

/// What the guided workout is doing now. Set timing lives in memory; rest
/// lives on the session row, so it survives a restart (handbook 4.13).
class GuideState {
  const GuideState({
    this.phase = GuidePhase.idle,
    this.setId,
    this.startedAt,
    this.targetSec = 0,
    this.label = '',
    this.pausedSec,
  });

  final GuidePhase phase;

  /// The set being done now.
  final String? setId;
  final DateTime? startedAt;

  /// Set time the set ends on. 0 means the user ends the set.
  final int targetSec;

  /// "Bench press · set 2 of 4".
  final String label;

  /// Set time when the workout was paused, frozen until it goes on.
  final int? pausedSec;

  /// Seconds into the set being done now.
  int elapsedAt(DateTime now) =>
      pausedSec ?? (startedAt == null ? 0 : now.difference(startedAt!).inSeconds.clamp(0, 86400));

  GuideState copyWith({int? targetSec, DateTime? startedAt, int? Function()? pausedSec}) => GuideState(
    phase: phase,
    setId: setId,
    startedAt: startedAt ?? this.startedAt,
    targetSec: targetSec ?? this.targetSec,
    label: label,
    pausedSec: pausedSec == null ? this.pausedSec : pausedSec(),
  );
}

/// The next set to do: the first set that is not done, in a non-skipped
/// exercise, in session order.
(SessionExerciseView, SetEntry)? nextSet(SessionDetail d) {
  for (final e in d.exercises) {
    if (e.item.skipped) continue;
    for (final s in e.sets) {
      if (!s.completed) return (e, s);
    }
  }
  return null;
}

/// True for a set that is done for a time, such as a plank, not for reps.
bool isTimedSet(SetEntry s) =>
    s.setType == SetType.timed || ((s.targetSec != null || s.durationSec != null) && s.reps == null);

/// True when every set of the exercise is a warm-up: a warm-up move, not
/// the lighter ramp-up sets of a main lift.
bool isWarmupMove(SessionExerciseView e) => e.sets.every((s) => s.setType == SetType.warmup);

/// "Bench press · set 2 of 4", or "Bench press · warm-up".
String describeSet(SessionExerciseView e, SetEntry s) {
  if (s.setType == SetType.warmup) return '${e.exercise.name} · warm-up';
  final working = e.sets.where((x) => x.setType != SetType.warmup).toList();
  return '${e.exercise.name} · set ${working.indexWhere((x) => x.id == s.id) + 1} of ${working.length}';
}

/// Runs set and rest timers, saves measured set and rest times, and speaks
/// cues. The user starts each set and ends each rep set; the guide only
/// does that on its own when the user turns it on in Me → Training.
class GuideController extends Notifier<GuideState> {
  Timer? _timer;
  bool _busy = false;
  int _lastSet = 0;
  int _lastRest = -1;
  bool? _wasPaused;

  /// "Next exercise." was said during this rest.
  bool _toldNext = false;

  /// When the rest alert is set to fire. Null when none is set.
  DateTime? _alertAt;

  WorkoutRepository get _repo => ref.read(workoutRepoProvider);
  DateTime get _now => ref.read(clockProvider)().toUtc();

  @override
  GuideState build() {
    ref.onDispose(() {
      _timer?.cancel();
      ScreenAwake.hold('workout', false);
    });
    return const GuideState();
  }

  /// Starts the one-second ticker. Called by the app shell.
  void attach() {
    if (_timer != null) return;
    ref.read(voicePlayerProvider).preload(ref.read(currentSettingsProvider).voice);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(tick()));
  }

  VoicePlayer get _voice => ref.read(voicePlayerProvider);
  void _say(String clip, {bool now = false}) => _voice.say(ref.read(currentSettingsProvider).voice, clip, now: now);

  /// Starts the next set that is not done.
  Future<void> startSet() async {
    final live = await _repo.liveSession();
    if (live == null) return;
    final d = await _repo.loadSession(live.id);
    final next = d == null ? null : nextSet(d);
    if (d == null || next == null) {
      state = const GuideState();
      return;
    }
    if (live.restStartedAt != null) await _repo.stopRest(live.id);
    await _saveRestTaken(d);
    final (e, s) = next;
    final settings = ref.read(currentSettingsProvider);
    final target = switch (isTimedSet(s)) {
      true => s.targetSec ?? s.durationSec ?? 40,
      false when settings.finishRepSets =>
        settings.setSec ?? estimateSetSec(s.reps ?? targetRepsFromNote(e.item.note) ?? _previousReps(e, s)),
      false => 0,
    };
    final working = e.sets.where((x) => x.setType != SetType.warmup).toList();
    final n = working.indexWhere((x) => x.id == s.id) + 1;
    final last = _lastDone(d);
    // The first cue cuts off any cue from the rest, such as "Ten seconds".
    var first = true;
    if (!_toldNext && last != null && last.$1.item.id != e.item.id) {
      _say(Clips.nextUp(e.exercise.catalogId) ?? Clips.nextExercise, now: true);
      first = false;
    }
    _say(switch (s.setType) {
      SetType.warmup => isWarmupMove(e) ? Clips.warmup : Clips.go,
      _ when n == working.length && working.length > 1 => Clips.lastSet,
      _ => Clips.set(n),
    }, now: first);
    _toldNext = false;
    _lastSet = 0;
    _lastRest = -1;
    state = GuideState(
      phase: GuidePhase.set,
      setId: s.id,
      startedAt: _now,
      targetSec: target,
      label: describeSet(e, s),
      pausedSec: live.status == SessionStatus.paused ? 0 : null,
    );
  }

  /// Ends the set being done now: saves the measured time, marks it done,
  /// and starts the rest. [onTime] is true when the set time ran out.
  Future<void> finishSet({bool onTime = false}) async {
    final id = state.setId;
    if (state.phase != GuidePhase.set || id == null) return;
    final elapsed = state.elapsedAt(_now);
    final d = await _loadLive();
    final set = d?.exercises.expand((e) => e.sets).where((s) => s.id == id).firstOrNull;
    if (d == null || set == null) {
      state = const GuideState();
      return;
    }
    // Save only a measured time. A timed set that ran out was held for its
    // time. A rep set that ran out was not measured: its end is a guess.
    // A time the user typed on a rep set is kept.
    if (isTimedSet(set) || (!onTime && set.durationSec == null)) {
      await _repo.updateSet(id, SetEntriesCompanion(durationSec: Value(elapsed)));
    }
    await _repo.setCompleted(id, true);
    unawaited(HapticFeedback.mediumImpact());
    await _afterSet(d.session.id, set);
  }

  /// Called when the user ticks a set in the list while the guide is on.
  Future<void> completeFromRow(SetEntry s) async {
    if (state.phase == GuidePhase.set && state.setId == s.id) return finishSet();
    await _repo.setCompleted(s.id, true);
    final d = await _loadLive();
    if (d != null) await _afterSet(d.session.id, s);
  }

  /// Skips the rest and starts the next set now.
  Future<void> skipRest() => startSet();

  /// Gives the set being done more time.
  void addTime(int seconds) {
    if (state.phase == GuidePhase.set && state.targetSec > 0) {
      state = state.copyWith(targetSec: state.targetSec + seconds);
    }
  }

  /// Gives the rest more time. The cues follow the new end.
  Future<void> addRest(int seconds) async {
    final live = await _repo.liveSession();
    if (live?.restStartedAt == null) return;
    await _repo.setRestTarget(live!.id, (live.restTargetSec ?? 0) + seconds);
  }

  /// Stops the set timer or the rest. The guide waits until the user starts
  /// a set again.
  Future<void> stop() async {
    _voice.silence();
    final live = await _repo.liveSession();
    if (live?.restStartedAt != null) await _repo.stopRest(live!.id);
    state = const GuideState();
  }

  /// Pauses or continues the workout, its set timer, and its rest.
  Future<void> setPaused(String sessionId, bool paused) async {
    paused ? await _repo.pause(sessionId) : await _repo.resume(sessionId);
    _pauseChanged(paused);
  }

  /// Says the workout is saved. Called when the user finishes it.
  void workoutSaved() => _say(Clips.done, now: true);

  void _pauseChanged(bool paused) {
    final was = _wasPaused;
    _wasPaused = paused;
    // The first look only learns the state, so a restart says nothing.
    if (was == null || was == paused) return;
    if (ref.read(currentSettingsProvider).guideOn) _say(paused ? Clips.paused : Clips.resumed, now: true);
    if (state.phase != GuidePhase.set) return;
    if (paused && state.pausedSec == null) {
      state = state.copyWith(pausedSec: () => state.elapsedAt(_now));
    } else if (!paused && state.pausedSec != null) {
      state = state.copyWith(
        startedAt: _now.subtract(Duration(seconds: state.pausedSec!)),
        pausedSec: () => null,
      );
    }
  }

  Future<void> _afterSet(String sessionId, SetEntry done) async {
    final d = await _repo.loadSession(sessionId);
    if (d == null) return;
    _toldNext = false;
    if (nextSet(d) == null) {
      // The workout is not saved yet. "Workout complete" plays when the user
      // finishes it.
      state = const GuideState();
      return;
    }
    final view = d.exercises.firstWhere((e) => e.sets.any((s) => s.id == done.id));
    final rest = switch (done.setType) {
      SetType.warmup when isWarmupMove(view) => warmupMoveRestSec,
      SetType.warmup => rampUpRestSec,
      _ => restFromNote(view.item.note) ?? ref.read(currentSettingsProvider).restAfterSetSec ?? defaultRestSec,
    };
    await _repo.startRest(sessionId, rest);
    if (done.setType != SetType.warmup || rest >= 30) _say(Clips.rest(rest));
    // Ask once, in context: the first guided rest is when the alert helps.
    final settings = ref.read(currentSettingsProvider);
    if (settings.restAlert && !settings.restAlertAsked) {
      await ref.read(settingsRepoProvider).setRestAlertAsked();
      unawaited(ref.read(restAlertsProvider).askPermission());
    }
    _lastRest = 0;
    state = const GuideState(phase: GuidePhase.rest);
  }

  /// One step of the timers. Public so tests can drive it.
  Future<void> tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final settings = ref.read(currentSettingsProvider);
      final live = await _repo.liveSession();
      // The screen stays on while the guide runs a live workout, so cues
      // play on time. It goes off when the workout ends.
      ScreenAwake.hold('workout', live != null && settings.guideOn);
      await _syncRestAlert(live, settings);
      if (live == null) {
        _wasPaused = null;
        if (state.phase != GuidePhase.idle) state = const GuideState();
        return;
      }
      if (!settings.guideOn) return;
      final paused = live.status == SessionStatus.paused;
      _pauseChanged(paused);
      if (paused) return;
      if (state.phase == GuidePhase.set) {
        final t = state.elapsedAt(_now);
        for (final c in setCues(_lastSet, t, state.targetSec)) {
          _say(c);
        }
        _lastSet = t;
        // Only a set with a set time ends on its own (a timed set, or a rep
        // set with Finish rep sets on time on).
        if (state.targetSec > 0 && t >= state.targetSec) await finishSet(onTime: true);
        return;
      }
      if (live.restStartedAt != null && live.restTargetSec != null) {
        await _restStep(live, settings.autoStartSets);
      }
    } finally {
      _busy = false;
    }
  }

  /// Keeps the one rest alert in step with the rest: set while a rest runs,
  /// moved when the rest changes, removed on pause, stop, or a new set.
  /// With the app open, the voice says the end, so the alert is removed
  /// just before it.
  Future<void> _syncRestAlert(WorkoutSession? live, AppSettings settings) async {
    DateTime? want;
    if (live != null &&
        settings.guideOn &&
        settings.restAlert &&
        live.status == SessionStatus.active &&
        live.restStartedAt != null &&
        live.restTargetSec != null) {
      final end = live.restStartedAt!.add(Duration(seconds: live.restTargetSec!));
      final open = WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      if (end.difference(_now) > (open ? const Duration(seconds: 2) : Duration.zero)) want = end;
    }
    if (want == _alertAt) return;
    _alertAt = want;
    final alerts = ref.read(restAlertsProvider);
    if (want == null) return alerts.cancel();
    final d = await _repo.loadSession(live!.id);
    final next = d == null ? null : nextSet(d);
    await alerts.schedule(
      want,
      title: 'Rest over',
      body: next == null ? 'Time for the next set.' : 'Next: ${describeSet(next.$1, next.$2)}',
    );
  }

  Future<void> _restStep(WorkoutSession live, bool autoStart) async {
    final target = live.restTargetSec!;
    final t = _now.difference(live.restStartedAt!).inSeconds;
    // After a restart, cues already passed are not said again.
    if (_lastRest < 0) _lastRest = t;
    final before = _lastRest;
    final cues = restCues(before, t, target, countdown: autoStart);
    _lastRest = t;
    if (state.phase != GuidePhase.rest) state = const GuideState(phase: GuidePhase.rest);
    for (final c in cues) {
      _say(c);
      if (c == Clips.tenLeft) await _tellNextExercise(live.id);
      if (c == Clips.three || c == Clips.two || c == Clips.one) unawaited(HapticFeedback.selectionClick());
      if (c == Clips.restOver) unawaited(HapticFeedback.heavyImpact());
    }
    // Start on its own only as the rest ends. A rest that ended long ago,
    // such as before a restart, waits for the user.
    if (autoStart && before < target && t >= target && t - target <= 3) {
      unawaited(HapticFeedback.heavyImpact());
      await startSet();
    }
  }

  /// Says "Next exercise." before the rest ends when the next set is on
  /// another exercise, so the set cue itself plays at the start.
  Future<void> _tellNextExercise(String sessionId) async {
    final d = await _repo.loadSession(sessionId);
    final next = d == null ? null : nextSet(d);
    final last = d == null ? null : _lastDone(d);
    if (next == null || last == null || last.$1.item.id == next.$1.item.id) return;
    _say(Clips.nextUp(next.$1.exercise.catalogId) ?? Clips.nextExercise);
    _toldNext = true;
  }

  Future<SessionDetail?> _loadLive() async {
    final live = await _repo.liveSession();
    return live == null ? null : _repo.loadSession(live.id);
  }

  static int? _previousReps(SessionExerciseView e, SetEntry s) {
    final i = e.sets.indexWhere((x) => x.id == s.id);
    for (var j = i - 1; j >= 0; j--) {
      if (e.sets[j].setType != SetType.warmup && e.sets[j].reps != null) return e.sets[j].reps;
    }
    return null;
  }

  static (SessionExerciseView, SetEntry)? _lastDone(SessionDetail d) {
    (SessionExerciseView, SetEntry)? best;
    for (final e in d.exercises) {
      for (final s in e.sets) {
        if (s.completedAt == null) continue;
        if (best == null || s.completedAt!.isAfter(best.$2.completedAt!)) best = (e, s);
      }
    }
    return best;
  }

  /// Saves the rest the user really took on the last done set, when no rest
  /// was recorded there yet.
  Future<void> _saveRestTaken(SessionDetail d) async {
    final last = _lastDone(d);
    if (last == null || last.$2.restSec != null) return;
    final rest = _now.difference(last.$2.completedAt!).inSeconds;
    if (rest > 0 && rest < 30 * 60) {
      await _repo.updateSet(last.$2.id, SetEntriesCompanion(restSec: Value(rest)));
    }
  }
}

final guideProvider = NotifierProvider<GuideController, GuideState>(GuideController.new);
