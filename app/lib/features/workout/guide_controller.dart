import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/screen_awake.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';
import '../../data/workout_repository.dart';
import '../../domain/guide.dart';
import 'lock_alerts.dart';
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

/// The clip that starts [s]: "Warm-up. Nice and easy.", "Go!" for a
/// ramp-up set, "Last set. Make it count!", or "Set two. Go!".
String setClip(SessionExerciseView e, SetEntry s) {
  final working = e.sets.where((x) => x.setType != SetType.warmup).toList();
  final n = working.indexWhere((x) => x.id == s.id) + 1;
  return switch (s.setType) {
    SetType.warmup => isWarmupMove(e) ? Clips.warmup : Clips.go,
    _ when n == working.length && working.length > 1 => Clips.lastSet,
    _ => Clips.set(n),
  };
}

/// Sets still to do, in session order, skipping skipped exercises.
List<(SessionExerciseView, SetEntry)> openSets(SessionDetail d) => [
  for (final e in d.exercises)
    if (!e.item.skipped)
      for (final s in e.sets)
        if (!s.completed) (e, s),
];

/// Seconds a set lasts before it ends on its own; 0 when the user ends it.
/// A timed set keeps its time. With Finish sets on time, a warm-up move
/// uses the warm-up time and a rep set the set time; both default to about
/// 3 s a rep.
int setTargetSec(SessionExerciseView e, SetEntry s, AppSettings st) {
  if (isTimedSet(s)) return s.targetSec ?? s.durationSec ?? 40;
  if (!st.finishRepSets) return 0;
  int? previousReps() {
    final i = e.sets.indexWhere((x) => x.id == s.id);
    for (var j = i - 1; j >= 0; j--) {
      if (e.sets[j].setType == s.setType && e.sets[j].reps != null) return e.sets[j].reps;
    }
    return null;
  }

  final reps = s.reps ?? rampUpReps(e, s) ?? targetRepsFromNote(e.item.note) ?? previousReps();
  if (isWarmupMove(e)) return st.warmupSec ?? estimateSetSec(reps);
  return st.setSec ?? estimateSetSec(reps);
}

/// Reps of a ramp-up set from the exercise note ("50% × 8, 70% × 5"), or
/// null when [s] is not a ramp-up set.
int? rampUpReps(SessionExerciseView e, SetEntry s) => rampUp(e, s)?.reps;

/// The share and reps of a ramp-up set, or null.
({int percent, int reps})? rampUp(SessionExerciseView e, SetEntry s) {
  if (s.setType != SetType.warmup || isWarmupMove(e)) return null;
  final ramp = e.sets.where((x) => x.setType == SetType.warmup).toList();
  return rampUpFromNote(e.item.note, ramp.indexWhere((x) => x.id == s.id));
}

/// Rest after [done], before [next]. There is no rest between warm-up
/// moves; after the last one comes the user's warm-up rest. A ramp-up set
/// rests 60 s. A working set rests the user's choice, else the plan's,
/// else 90 s.
int restSecFor(SessionExerciseView view, SetEntry done, SessionExerciseView? next, AppSettings st) {
  if (done.setType == SetType.warmup && isWarmupMove(view)) {
    return next != null && isWarmupMove(next) ? 0 : st.warmupRestSec ?? defaultWarmupRestSec;
  }
  if (done.setType == SetType.warmup) return rampUpRestSec;
  return st.restAfterSetSec ?? restFromNote(view.item.note) ?? defaultRestSec;
}

/// Runs set and rest timers, saves measured set and rest times, and speaks
/// cues. By default the whole workout runs on its own: warm-up moves follow
/// each other, each set ends on its time, and the next set starts when the
/// rest ends. The user can turn each part off in Me → Training.
class GuideController extends Notifier<GuideState> {
  Timer? _timer;
  bool _busy = false;

  /// The last time the lock-screen alerts told the user a set starts. A
  /// set that should have started on its own while the app was away, at or
  /// before this time, is caught up on return, so the record matches what
  /// the alerts said.
  DateTime? _coveredUntil;
  int _lastSet = 0;
  int _lastRest = -1;
  bool? _wasPaused;

  /// "Next exercise." was said during this rest.
  bool _toldNext = false;

  /// The app is off screen (phone locked or another app in front). Then
  /// the lock-screen alerts speak, and the live voice stays quiet, so a cue
  /// is never said twice.
  bool _away = false;
  AppLifecycleListener? _life;

  WorkoutRepository get _repo => ref.read(workoutRepoProvider);
  DateTime get _now => ref.read(clockProvider)().toUtc();

  @override
  GuideState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _life?.dispose();
      ScreenAwake.hold('workout', false);
    });
    // The running set is saved, so it survives the app being closed. The
    // first call is the empty start state; saving it would wipe the set
    // that restore() is about to bring back.
    listenSelf((prev, next) {
      if (prev != null) unawaited(_save(next));
    });
    return const GuideState();
  }

  /// Starts the one-second ticker. Called by the app shell.
  void attach() {
    if (_timer != null) return;
    ref.read(voicePlayerProvider).preload(ref.read(currentSettingsProvider).voice);
    // Alerts set before the app was closed are stale now: the app speaks
    // again, and sets new ones when it next goes off screen.
    unawaited(ref.read(lockAlertsProvider).clear());
    unawaited(restore());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(tick()));
    _life ??= AppLifecycleListener(onStateChange: lifecycleChanged);
  }

  /// Settings key of the running set and [_coveredUntil].
  static const _savedKey = 'guide.running';

  Future<void> _save([GuideState? next]) async {
    final g = next ?? state;
    final m = {
      if (g.phase == GuidePhase.set && g.setId != null && g.startedAt != null) ...{
        'setId': g.setId,
        'startedAt': g.startedAt!.toUtc().toIso8601String(),
        'target': g.targetSec,
        'label': g.label,
      },
      if (_coveredUntil != null) 'covered': _coveredUntil!.toUtc().toIso8601String(),
    };
    try {
      await ref.read(settingsRepoProvider).set(_savedKey, m.isEmpty ? null : jsonEncode(m));
    } catch (_) {
      // Saving the set clock must never stop the workout.
    }
  }

  /// Brings back the set that was running when the app was closed, so a
  /// timed set ends at its time and the workout goes on. Public so tests
  /// can drive it.
  Future<void> restore() async {
    final raw = await ref.read(settingsRepoProvider).read(_savedKey);
    if (raw == null) return;
    Map<String, Object?> m;
    try {
      m = (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      return;
    }
    _coveredUntil = DateTime.tryParse(m['covered'] as String? ?? '')?.toUtc();
    final live = await _repo.liveSession();
    if (live == null) {
      _coveredUntil = null;
      await _save();
      return;
    }
    final start = DateTime.tryParse(m['startedAt'] as String? ?? '')?.toUtc();
    final d = await _repo.loadSession(live.id);
    final set = d?.exercises.expand((e) => e.sets).where((x) => x.id == m['setId']).firstOrNull;
    if (set == null || set.completed || start == null || state.phase != GuidePhase.idle) return;
    final pausedAt = live.status == SessionStatus.paused ? live.pausedAt : null;
    state = GuideState(
      phase: GuidePhase.set,
      setId: set.id,
      startedAt: start,
      targetSec: (m['target'] as num?)?.toInt() ?? 0,
      label: m['label'] as String? ?? '',
      pausedSec: pausedAt?.toUtc().difference(start).inSeconds.clamp(0, 86400),
    );
    // Cues that passed while the app was closed are not said.
    _lastSet = state.elapsedAt(_now);
  }

  /// Hands the cues to the lock screen when the app goes off screen, and
  /// takes them back when it returns. Public so tests can drive it.
  Future<void> lifecycleChanged(AppLifecycleState s) async {
    final away = s == AppLifecycleState.hidden || s == AppLifecycleState.paused || s == AppLifecycleState.detached;
    if (away == _away) return;
    _away = away;
    if (away) {
      _voice.silence();
      await _scheduleAway();
    } else {
      await ref.read(lockAlertsProvider).clear();
      // Cues that passed while away are not said again.
      _lastRest = -1;
      _lastSet = state.elapsedAt(_now);
    }
  }

  VoicePlayer get _voice => ref.read(voicePlayerProvider);
  void _say(String clip, {bool now = false}) {
    if (_away) return;
    _voice.say(ref.read(currentSettingsProvider).voice, clip, now: now);
  }

  /// Starts the next set that is not done, now or at [at] (an automatic
  /// start that was due while the app was busy or away). A late start says
  /// nothing, so no stale cue plays.
  Future<void> startSet({DateTime? at}) async {
    final live = await _repo.liveSession();
    if (live == null) return;
    final d = await _repo.loadSession(live.id);
    final next = d == null ? null : nextSet(d);
    if (d == null || next == null) {
      state = const GuideState();
      return;
    }
    if (at == null) _coveredUntil = null;
    final start = at ?? _now;
    final quiet = _now.difference(start).inSeconds > 2;
    if (live.restStartedAt != null) await _repo.stopRest(live.id);
    await _saveRestTaken(d, start);
    final (e, s) = next;
    final settings = ref.read(currentSettingsProvider);
    final target = setTargetSec(e, s, settings);
    final last = _lastDone(d);
    if (!quiet) {
      // The first cue cuts off any cue from the rest, such as "Ten seconds".
      var first = true;
      if (!_toldNext && last != null && last.$1.item.id != e.item.id) {
        _say(Clips.nextUp(e.exercise.catalogId) ?? Clips.nextExercise, now: true);
        first = false;
      }
      _say(setClip(e, s), now: first);
    }
    _toldNext = false;
    _lastSet = 0;
    _lastRest = -1;
    state = GuideState(
      phase: GuidePhase.set,
      setId: s.id,
      startedAt: start,
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
    final target = state.targetSec;
    // A set that ran out ends at its set time, not when the app saw it (a
    // late tick, or the phone locked); its rest starts there too.
    final timed = onTime && target > 0 && state.startedAt != null;
    final late = timed && elapsed > target + 2;
    final endAt = timed ? state.startedAt!.add(Duration(seconds: target)) : _now;
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
      final measured = onTime && target > 0 && elapsed > target ? target : elapsed;
      await _repo.updateSet(id, SetEntriesCompanion(durationSec: Value(measured)));
    }
    await _repo.setCompleted(id, true, at: endAt);
    unawaited(HapticFeedback.mediumImpact());
    await _afterSet(d.session.id, set, endedAt: endAt, quiet: late);
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

  Future<void> _afterSet(String sessionId, SetEntry done, {DateTime? endedAt, bool quiet = false}) async {
    final d = await _repo.loadSession(sessionId);
    if (d == null) return;
    _toldNext = false;
    final next = nextSet(d);
    if (next == null) {
      // The workout is not saved yet. "Workout complete" plays when the user
      // finishes it.
      state = const GuideState();
      return;
    }
    final settings = ref.read(currentSettingsProvider);
    final view = d.exercises.firstWhere((e) => e.sets.any((s) => s.id == done.id));
    final fresh = view.sets.firstWhere((s) => s.id == done.id);
    await _fillNext(view, fresh, next, settings);
    final rest = restSecFor(view, fresh, next.$1, settings);
    final from = endedAt ?? _now;
    if (rest <= 0) {
      // Warm-up moves follow each other with no rest.
      if (settings.autoStartSets) {
        await startSet(at: from);
      } else {
        state = const GuideState();
      }
      return;
    }
    await _repo.startRest(sessionId, rest, from: from);
    if (!quiet) _say(Clips.rest(rest));
    // Ask once, in context: the first guided rest is when the alerts help.
    if (settings.lockAlerts && !settings.restAlertAsked) {
      await ref.read(settingsRepoProvider).setRestAlertAsked();
      unawaited(ref.read(lockAlertsProvider).askPermission());
    }
    _lastRest = _now.difference(from).inSeconds;
    state = const GuideState(phase: GuidePhase.rest);
  }

  /// Fills the next working set of the same exercise from the set just
  /// done, so the user does not type it again: the same weight and reps,
  /// or, with a pyramid, a little more weight and fewer reps. Only an empty
  /// set is filled, and it is not marked done.
  Future<void> _fillNext(
    SessionExerciseView view,
    SetEntry done,
    (SessionExerciseView, SetEntry) next,
    AppSettings settings,
  ) async {
    final (nv, ns) = next;
    if (nv.item.id != view.item.id || done.setType == SetType.warmup || ns.setType == SetType.warmup) return;
    if (ns.load != null || ns.reps != null || (done.load == null && done.reps == null)) return;
    final aim = nextAim(load: done.load, reps: done.reps, unit: done.loadUnit, style: settings.loadStyle);
    await _repo.updateSet(
      ns.id,
      SetEntriesCompanion(
        load: Value(aim.load),
        loadUnit: Value(aim.load == null ? null : done.loadUnit ?? settings.loadUnit),
        reps: Value(aim.reps),
      ),
    );
  }

  int _restFor(SessionExerciseView view, SetEntry done, SessionExerciseView? next) =>
      restSecFor(view, done, next, ref.read(currentSettingsProvider));

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
      if (live == null) {
        _wasPaused = null;
        if (_coveredUntil != null) {
          _coveredUntil = null;
          await _save();
        }
        if (state.phase != GuidePhase.idle) state = const GuideState();
        return;
      }
      if (!settings.guideOn) return;
      final paused = live.status == SessionStatus.paused;
      _pauseChanged(paused);
      if (paused) return;
      // Each step may end a set or start the next one. Steps that were due
      // while the app was away are caught up here, one after another.
      var moved = false;
      for (var i = 0; i < 200; i++) {
        if (!await _step(settings)) break;
        moved = true;
      }
      if (moved && _away) await _scheduleAway(cardOnly: true);
    } finally {
      _busy = false;
    }
  }

  /// One step of the set or rest. Returns true when it moved on: a set
  /// ended or the next set started.
  Future<bool> _step(AppSettings settings) async {
    if (state.phase == GuidePhase.set) {
      final t = state.elapsedAt(_now);
      final c = cueBetween(setPlan(state.targetSec, settings.cues), _lastSet, t);
      if (c != null) {
        _say(c);
        _haptic(c);
      }
      _lastSet = t;
      // Only a set with a set time ends on its own (a timed set, or a rep
      // set with Finish sets on time on).
      if (state.targetSec > 0 && t >= state.targetSec) {
        await finishSet(onTime: true);
        return true;
      }
      return false;
    }
    final live = await _repo.liveSession();
    if (live == null || live.restStartedAt == null || live.restTargetSec == null) return false;
    return _restStep(live, settings);
  }

  Future<bool> _restStep(WorkoutSession live, AppSettings settings) async {
    final target = live.restTargetSec!;
    final autoStart = settings.autoStartSets;
    final t = _now.difference(live.restStartedAt!).inSeconds;
    // After a restart, cues already passed are not said again.
    if (_lastRest < 0) _lastRest = t;
    final before = _lastRest;
    final c = cueBetween(restPlan(target, settings.cues, autoStart: autoStart), before, t);
    _lastRest = t;
    if (state.phase != GuidePhase.rest) state = const GuideState(phase: GuidePhase.rest);
    if (c != null) {
      _say(c);
      _haptic(c);
      if (c == Clips.tenLeft) await _tellNextExercise(live.id);
    }
    // Start on its own as the rest ends. A rest that ended long ago waits
    // for the user, unless the lock-screen alerts already told the user
    // that set started.
    if (!autoStart || t < target) return false;
    final end = live.restStartedAt!.add(Duration(seconds: target));
    final onTime = before < target && t - target <= 3;
    final told = _coveredUntil != null && !end.isAfter(_coveredUntil!);
    if (!onTime && !told) return false;
    if (onTime && !_away) unawaited(HapticFeedback.heavyImpact());
    await startSet(at: end);
    return true;
  }

  void _haptic(String clip) {
    if (_away) return;
    if (clip == Clips.three || clip == Clips.two || clip == Clips.one) unawaited(HapticFeedback.selectionClick());
    if (clip == Clips.restOver || clip == Clips.time) unawaited(HapticFeedback.heavyImpact());
  }

  /// Sets the lock-screen cues for what happens while the app is away: the
  /// cues left in this set or rest and, when sets end and start on their
  /// own, every set and rest after it, as far as their times are known. On
  /// Android a quiet card shows the live clock. Brief cues (countdown, ten
  /// seconds, halfway) need on-time alerts; without them Android may
  /// deliver late, so only the start and end cues are set. With [cardOnly]
  /// only the card is refreshed, so a cue that is playing is not cut off.
  Future<void> _scheduleAway({bool cardOnly = false}) async {
    final settings = ref.read(currentSettingsProvider);
    final live = await _repo.liveSession();
    if (live == null || !settings.guideOn || !settings.lockAlerts) return;
    final d = await _repo.loadSession(live.id);
    if (d == null) return;
    final alerts = ref.read(lockAlertsProvider);
    final exact = cardOnly || await alerts.onTime();
    final now = _now;
    final cues = <AlertCue>[];
    void add(DateTime start, List<TimedCue> plan, String label, String body) {
      for (final c in plan) {
        final at = start.add(Duration(seconds: c.at));
        final brief = !_keyClips.contains(c.clip);
        if (!at.isAfter(now) || (brief && !exact)) continue;
        cues.add(AlertCue(at: at, clip: c.clip, title: _cueTitle(c.clip, label), body: body, brief: brief));
      }
    }

    String nextLine((SessionExerciseView, SetEntry)? n) =>
        n == null ? 'Last set done' : 'Next: ${describeSet(n.$1, n.$2)}';
    final open = openSets(d);
    LiveCard card;
    // The chain: [t] is when the next step starts. After a set ([prev]) a
    // rest comes first; after a rest, the set at [i] starts.
    DateTime? t;
    (SessionExerciseView, SetEntry)? prev;
    var i = 0;
    var afterRest = false;
    if (live.status == SessionStatus.paused) {
      card = LiveCard(title: 'Workout paused', body: live.name);
    } else if (state.phase == GuidePhase.set && state.startedAt != null) {
      final start = state.startedAt!;
      final target = state.targetSec;
      i = open.indexWhere((x) => x.$2.id == state.setId);
      if (target > 0 && i >= 0) {
        final end = start.add(Duration(seconds: target));
        add(start, setPlan(target, settings.cues), state.label, state.label);
        card = LiveCard(title: state.label, body: 'Set time', countdownTo: end);
        prev = open[i];
        i++;
        t = end;
      } else {
        card = LiveCard(title: state.label, body: 'Tap Set done when you finish', countUpFrom: start);
      }
    } else if (live.restStartedAt != null && live.restTargetSec != null) {
      final next = open.firstOrNull;
      final end = live.restStartedAt!.add(Duration(seconds: live.restTargetSec!));
      add(
        live.restStartedAt!,
        _restCues(live.restTargetSec!, settings, newExercise: _isNewExercise(_lastDone(d), next)),
        'Rest',
        nextLine(next),
      );
      card = LiveCard(title: 'Rest', body: nextLine(next), countdownTo: end);
      t = end;
      afterRest = true;
    } else {
      final next = open.firstOrNull;
      card = LiveCard(title: live.name, body: next == null ? 'Every set is done' : nextLine(next));
    }
    if (cardOnly) {
      await alerts.showCard(card);
      return;
    }

    var covered = _coveredUntil;
    while (t != null && i < open.length && cues.length < _maxCues && t.difference(now) < _horizon) {
      final next = open[i];
      if (!afterRest) {
        final rest = _restFor(prev!.$1, prev.$2, next.$1);
        if (rest > 0) {
          add(t, _restCues(rest, settings, newExercise: _isNewExercise(prev, next)), 'Rest', nextLine(next));
          t = t.add(Duration(seconds: rest));
        }
        afterRest = true;
        continue;
      }
      if (!settings.autoStartSets) break;
      final label = describeSet(next.$1, next.$2);
      if (t.isAfter(now)) {
        cues.add(AlertCue(at: t, clip: setClip(next.$1, next.$2), title: label, body: 'Set started'));
      }
      covered = t;
      final target = setTargetSec(next.$1, next.$2, settings);
      if (target <= 0) break;
      add(t, setPlan(target, settings.cues), label, label);
      t = t.add(Duration(seconds: target));
      prev = next;
      i++;
      afterRest = false;
    }
    _coveredUntil = covered;
    await _save();
    await alerts.show(cues, voice: settings.voice, card: card);
  }

  /// Cues that start or end a set or a rest. They play even without
  /// on-time alerts, and they stay on screen longer.
  static final _keyClips = {
    Clips.time,
    Clips.restOver,
    Clips.warmup,
    Clips.go,
    Clips.lastSet,
    Clips.nextExercise,
    for (var n = 1; n <= 10; n++) Clips.set(n),
  };

  /// At most this many alerts are set at once. Android allows 500 for an
  /// app; fewer keeps setting them quick.
  static const _maxCues = 150;

  /// Alerts are set this far ahead.
  static const _horizon = Duration(hours: 2);

  /// Rest cues for the lock screen. With sets that start on their own, the
  /// set's own cue ends the rest. "Next exercise." plays 7 s before the end
  /// when the next set is on another exercise.
  List<TimedCue> _restCues(int rest, AppSettings settings, {required bool newExercise}) {
    final plan = restPlan(rest, settings.cues, autoStart: settings.autoStartSets);
    if (!newExercise || rest < 20) return plan;
    return [...plan, (at: rest - 7, clip: Clips.nextExercise)]..sort((a, b) => a.at.compareTo(b.at));
  }

  static bool _isNewExercise((SessionExerciseView, SetEntry)? a, (SessionExerciseView, SetEntry)? b) =>
      a != null && b != null && a.$1.item.id != b.$1.item.id;

  static String _cueTitle(String clip, String label) => switch (clip) {
    Clips.nextExercise => 'Next exercise coming up',
    Clips.halfway => 'Halfway · $label',
    Clips.tenLeft => '10 seconds left',
    Clips.three => '3',
    Clips.two => '2',
    Clips.one => '1',
    Clips.time => 'Time! Set done',
    Clips.restOver => 'Rest is up',
    _ => label,
  };

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
  Future<void> _saveRestTaken(SessionDetail d, DateTime start) async {
    final last = _lastDone(d);
    if (last == null || last.$2.restSec != null) return;
    final rest = start.difference(last.$2.completedAt!).inSeconds;
    if (rest > 0 && rest < 30 * 60) {
      await _repo.updateSet(last.$2.id, SetEntriesCompanion(restSec: Value(rest)));
    }
  }
}

final guideProvider = NotifierProvider<GuideController, GuideState>(GuideController.new);
