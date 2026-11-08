import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/clock.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../domain/track.dart';
import '../health/live_steps.dart';
import 'location_source.dart';

/// What the recorder shows besides the saved numbers.
class RecorderState {
  const RecorderState({this.lastFix, this.listening = false, this.lost = false, this.since, this.counting = false});

  /// The newest fix, for the GPS signal line. Not a saved value.
  final TrackPoint? lastFix;

  /// GPS is on for an activity.
  final bool listening;

  /// The GPS stream failed (for example, location was switched off).
  final bool lost;

  /// When GPS was switched on, to show how long it has searched.
  final DateTime? since;

  /// The step sensor counts for this activity.
  final bool counting;

  RecorderState copyWith({TrackPoint? lastFix, bool? listening, bool? lost, bool? counting}) => RecorderState(
    lastFix: lastFix ?? this.lastFix,
    listening: listening ?? this.listening,
    lost: lost ?? this.lost,
    since: since,
    counting: counting ?? this.counting,
  );
}

/// Records GPS activities (handbook 4.14).
///
/// Fixes go to the database every few seconds, so a closed app loses at
/// most those seconds. The numbers on screen are worked out from the saved
/// points, the same way a finished activity is. GPS is off while paused.
class ActivityRecorder extends Notifier<RecorderState> {
  StreamSubscription<TrackPoint>? _sub;
  StreamSubscription<int>? _stepSub;
  Timer? _timer;
  final _buffer = <TrackPoint>[];
  int _steps = 0;
  int? _lastCount;
  String? _id;

  /// How often fixes are saved while recording.
  static const saveEvery = Duration(seconds: 3);

  @override
  RecorderState build() {
    ref.onDispose(_stopGps);
    return const RecorderState();
  }

  /// Asks for location if needed, then starts a new activity. Returns how
  /// the phone answered; nothing starts unless it is [LocationAccess.allowed].
  /// Runs and walks also count steps, so distance can come from steps when
  /// GPS finds no usable fix.
  Future<LocationAccess> start(ActivityKind kind) async {
    final access = await ref.read(locationSourceProvider).ensureAccess();
    if (access != LocationAccess.allowed) return access;
    if (kind != ActivityKind.ride) await ref.read(stepSensorProvider).request();
    final id = await ref.read(activityRepoProvider).start(kind);
    _listen(id, kind, gps: true);
    return access;
  }

  /// Starts a run or walk measured by steps only: no GPS, no route.
  /// False when the step sensor is not allowed; nothing starts then.
  Future<bool> startWithSteps(ActivityKind kind) async {
    assert(kind != ActivityKind.ride, 'Rides have no steps');
    if (!await ref.read(stepSensorProvider).request()) return false;
    final id = await ref.read(activityRepoProvider).start(kind, gps: false);
    _listen(id, kind, gps: false);
    return true;
  }

  /// Picks up a recording after the app restarted. Does nothing if GPS
  /// already runs for it or it is paused.
  Future<void> attach(GpsActivity live) async {
    if (live.status != ActivityStatus.recording || _id == live.id) return;
    // [live] can be a snapshot from before a tap on Pause: check again.
    final now = await ref.read(activityRepoProvider).live();
    if (now == null || now.id != live.id || now.status != ActivityStatus.recording || _id == live.id) return;
    _listen(now.id, now.kind, gps: now.usesGps);
  }

  Future<void> pause() async {
    final id = _id;
    if (id == null) return;
    await _save();
    _stopGps();
    await ref.read(activityRepoProvider).pause(id);
  }

  Future<void> resume(GpsActivity a) async {
    await ref.read(activityRepoProvider).resume(a.id);
    _listen(a.id, a.kind, gps: a.usesGps);
  }

  /// Saves the last fixes and the summary. Returns the activity's ID.
  /// [heightCm] sets the step length for a distance from steps.
  Future<String?> finish(String id, {double? heightCm}) async {
    await _save();
    _stopGps();
    await ref.read(activityRepoProvider).finish(id, heightCm: heightCm);
    return id;
  }

  /// Stops and deletes the activity with its route.
  Future<void> discard(String id) async {
    _buffer.clear();
    _steps = 0;
    _stopGps();
    await ref.read(activityRepoProvider).delete(id);
  }

  void _listen(String id, ActivityKind kind, {required bool gps}) {
    _stopGps();
    _id = id;
    state = RecorderState(listening: gps, since: ref.read(clockProvider)().toUtc());
    if (gps) {
      _sub = ref.read(locationSourceProvider).fixes(kind).listen(
        (p) {
          _buffer.add(p);
          state = state.copyWith(lastFix: p, lost: false);
        },
        onError: (Object _) => state = state.copyWith(lost: true),
      );
    }
    if (kind != ActivityKind.ride) {
      _lastCount = null;
      _stepSub = ref.read(stepSensorProvider).counts().listen(
        (count) {
          final last = _lastCount;
          _lastCount = count;
          if (!state.counting) state = state.copyWith(counting: true);
          // The first value is only the base. A drop means the phone
          // restarted its count.
          if (last == null || count < last) return;
          _steps += count - last;
        },
        // No step sensor, or not allowed: GPS alone measures.
        onError: (Object _) {},
      );
    }
    _timer = Timer.periodic(saveEvery, (_) => unawaited(_save()));
  }

  Future<void> _save() async {
    final id = _id;
    if (id == null) return;
    final repo = ref.read(activityRepoProvider);
    if (_steps > 0) {
      final n = _steps;
      _steps = 0;
      await repo.addSteps(id, n);
    }
    if (_buffer.isEmpty) return;
    final batch = [..._buffer];
    _buffer.clear();
    await repo.addPoints(id, batch);
  }

  void _stopGps() {
    _sub?.cancel();
    _sub = null;
    _stepSub?.cancel();
    _stepSub = null;
    _lastCount = null;
    _timer?.cancel();
    _timer = null;
    _id = null;
    if (ref.mounted) state = state.copyWith(listening: false, counting: false);
  }
}

final recorderProvider = NotifierProvider<ActivityRecorder, RecorderState>(ActivityRecorder.new);

/// How good the GPS signal is, from the newest fix's accuracy.
enum GpsSignal {
  none('Searching for GPS'),
  weak('Weak GPS'),
  good('GPS ready');

  const GpsSignal(this.label);
  final String label;

  static GpsSignal of(TrackPoint? fix, ActivityKind kind, DateTime now) {
    if (fix == null || now.difference(fix.at).inSeconds > 10) return GpsSignal.none;
    return fix.accuracy <= kind.maxAccuracy / 2 ? GpsSignal.good : GpsSignal.weak;
  }
}
