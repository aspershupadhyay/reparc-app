import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/workout_repository.dart';
import '../../domain/guide.dart';
import 'voice.dart';

enum GuidePhase { idle, set, rest }

/// What the guided workout is doing now. Set timing lives in memory; rest
/// lives on the session row, so it survives a restart (handbook 4.13).
class GuideState {
  const GuideState({this.phase = GuidePhase.idle, this.setId, this.startedAt, this.targetSec = 0, this.label = ''});

  final GuidePhase phase;

  /// The set being done now.
  final String? setId;
  final DateTime? startedAt;

  /// Set time the voice counts to.
  final int targetSec;

  /// "Bench press · set 2 of 4".
  final String label;

  GuideState copyWith({GuidePhase? phase, int? targetSec}) => GuideState(
    phase: phase ?? this.phase,
    setId: setId,
    startedAt: startedAt,
    targetSec: targetSec ?? this.targetSec,
    label: label,
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

/// Runs set and rest timers on their own, saves measured set and rest
/// times, and speaks cues. The user can turn it off in Me → Training.
class GuideController extends Notifier<GuideState> {
  Timer? _timer;
  bool _busy = false;
  int _lastSet = 0;
  int _lastRest = -1;
  int? _pausedAt;
  bool _wasPaused = false;

  WorkoutRepository get _repo => ref.read(workoutRepoProvider);
  DateTime get _now => ref.read(clockProvider)().toUtc();

  @override
  GuideState build() {
    ref.onDispose(() => _timer?.cancel());
    return const GuideState();
  }

  /// Starts the one-second ticker. Called by the app shell.
  void attach() => _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => unawaited(tick()));

  void _say(String clip) => ref.read(voicePlayerProvider).say(ref.read(currentSettingsProvider).voice, clip);

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
    final timed = s.setType == SetType.timed || (s.durationSec != null && s.reps == null);
    final reps = s.reps ?? targetRepsFromNote(e.item.note) ?? _previousReps(e, s);
    final target = timed ? (s.durationSec ?? 40) : (settings.setSec ?? estimateSetSec(reps));
    final working = e.sets.where((x) => x.setType != SetType.warmup).toList();
    final n = working.indexWhere((x) => x.id == s.id) + 1;
    final last = _lastDone(d);
    if (last != null && last.$1.item.id != e.item.id) _say(Clips.nextExercise);
    _say(switch (s.setType) {
      SetType.warmup => Clips.warmup,
      _ when n == working.length && working.length > 1 => Clips.lastSet,
      _ => Clips.set(n),
    });
    _lastSet = 0;
    _pausedAt = null;
    state = GuideState(
      phase: GuidePhase.set,
      setId: s.id,
      startedAt: _now,
      targetSec: target,
      label: s.setType == SetType.warmup
          ? '${e.exercise.name} · warm-up'
          : '${e.exercise.name} · set $n of ${working.length}',
    );
  }

  /// Ends the set being done now: saves the measured time, marks it done,
  /// and starts the rest.
  Future<void> finishSet() async {
    final id = state.setId;
    if (state.phase != GuidePhase.set || id == null) return;
    final elapsed = _setElapsed();
    final d = await _loadLive();
    final set = d?.exercises.expand((e) => e.sets).where((s) => s.id == id).firstOrNull;
    if (d == null || set == null) {
      state = const GuideState();
      return;
    }
    final timed = set.setType == SetType.timed || (set.durationSec != null && set.reps == null);
    // A measured time is a real value. A time the user typed is kept.
    if (timed || set.durationSec == null) {
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
    if (state.phase == GuidePhase.set) state = state.copyWith(targetSec: state.targetSec + seconds);
  }

  /// Stops guiding until the user starts a set again.
  Future<void> stop() async {
    final live = await _repo.liveSession();
    if (live?.restStartedAt != null) await _repo.stopRest(live!.id);
    state = const GuideState();
  }

  Future<void> _afterSet(String sessionId, SetEntry done) async {
    final d = await _repo.loadSession(sessionId);
    if (d == null) return;
    final next = nextSet(d);
    if (next == null) {
      _say(Clips.done);
      state = const GuideState();
      return;
    }
    final view = d.exercises.firstWhere((e) => e.sets.any((s) => s.id == done.id));
    final rest = switch (done.setType) {
      SetType.warmup when view.sets.every((s) => s.setType == SetType.warmup) => warmupMoveRestSec,
      SetType.warmup => rampUpRestSec,
      _ => restFromNote(view.item.note) ?? ref.read(currentSettingsProvider).restAfterSetSec ?? defaultRestSec,
    };
    await _repo.startRest(sessionId, rest);
    if (done.setType != SetType.warmup || rest >= 30) _say(Clips.rest(rest));
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
      if (live == null) {
        if (state.phase != GuidePhase.idle) state = const GuideState();
        return;
      }
      if (!settings.guideOn) return;
      final paused = live.status == SessionStatus.paused;
      if (paused != _wasPaused) {
        _wasPaused = paused;
        _say(paused ? Clips.paused : Clips.resumed);
        if (state.phase == GuidePhase.set) {
          if (paused) {
            _pausedAt = _setElapsed();
          } else if (_pausedAt != null) {
            state = GuideState(
              phase: GuidePhase.set,
              setId: state.setId,
              startedAt: _now.subtract(Duration(seconds: _pausedAt!)),
              targetSec: state.targetSec,
              label: state.label,
            );
            _pausedAt = null;
          }
        }
      }
      if (paused) return;
      if (state.phase == GuidePhase.set) {
        final t = _setElapsed();
        for (final c in setCues(_lastSet, t, state.targetSec)) {
          _say(c);
        }
        _lastSet = t;
        if (t >= state.targetSec && settings.autoFinishSets) await finishSet();
        return;
      }
      if (live.restStartedAt != null && live.restTargetSec != null) {
        final t = _now.difference(live.restStartedAt!).inSeconds;
        if (_lastRest < 0) _lastRest = t;
        for (final c in restCues(_lastRest, t, live.restTargetSec!)) {
          _say(c);
        }
        _lastRest = t;
        if (state.phase != GuidePhase.rest) state = const GuideState(phase: GuidePhase.rest);
        if (t >= live.restTargetSec!) {
          _lastRest = -1;
          await startSet();
        }
      }
    } finally {
      _busy = false;
    }
  }

  int _setElapsed() =>
      _pausedAt ?? (state.startedAt == null ? 0 : _now.difference(state.startedAt!).inSeconds.clamp(0, 86400));

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
