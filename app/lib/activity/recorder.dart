import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../domain/track.dart';
import 'location_source.dart';

/// What the recorder shows besides the saved numbers.
class RecorderState {
  const RecorderState({this.lastFix, this.listening = false, this.lost = false});

  /// The newest fix, for the GPS signal line. Not a saved value.
  final TrackPoint? lastFix;

  /// GPS is on for an activity.
  final bool listening;

  /// The GPS stream failed (for example, location was switched off).
  final bool lost;

  RecorderState copyWith({TrackPoint? lastFix, bool? listening, bool? lost}) => RecorderState(
    lastFix: lastFix ?? this.lastFix,
    listening: listening ?? this.listening,
    lost: lost ?? this.lost,
  );
}

/// Records GPS activities (handbook 4.14).
///
/// Fixes go to the database every few seconds, so a closed app loses at
/// most those seconds. The numbers on screen are worked out from the saved
/// points, the same way a finished activity is. GPS is off while paused.
class ActivityRecorder extends Notifier<RecorderState> {
  StreamSubscription<TrackPoint>? _sub;
  Timer? _timer;
  final _buffer = <TrackPoint>[];
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
  Future<LocationAccess> start(ActivityKind kind) async {
    final access = await ref.read(locationSourceProvider).ensureAccess();
    if (access != LocationAccess.allowed) return access;
    final id = await ref.read(activityRepoProvider).start(kind);
    _listen(id, kind);
    return access;
  }

  /// Picks up a recording after the app restarted. Does nothing if GPS
  /// already runs for it or it is paused.
  Future<void> attach(GpsActivity live) async {
    if (live.status != ActivityStatus.recording || _id == live.id) return;
    // [live] can be a snapshot from before a tap on Pause: check again.
    final now = await ref.read(activityRepoProvider).live();
    if (now == null || now.id != live.id || now.status != ActivityStatus.recording || _id == live.id) return;
    _listen(now.id, now.kind);
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
    _listen(a.id, a.kind);
  }

  /// Saves the last fixes and the summary. Returns the activity's ID.
  Future<String?> finish(String id) async {
    await _save();
    _stopGps();
    await ref.read(activityRepoProvider).finish(id);
    return id;
  }

  /// Stops and deletes the activity with its route.
  Future<void> discard(String id) async {
    _buffer.clear();
    _stopGps();
    await ref.read(activityRepoProvider).delete(id);
  }

  void _listen(String id, ActivityKind kind) {
    _stopGps();
    _id = id;
    state = const RecorderState(listening: true);
    _sub = ref.read(locationSourceProvider).fixes(kind).listen(
      (p) {
        _buffer.add(p);
        state = state.copyWith(lastFix: p, lost: false);
      },
      onError: (Object _) => state = state.copyWith(lost: true),
    );
    _timer = Timer.periodic(saveEvery, (_) => unawaited(_save()));
  }

  Future<void> _save() async {
    final id = _id;
    if (id == null || _buffer.isEmpty) return;
    final batch = [..._buffer];
    _buffer.clear();
    await ref.read(activityRepoProvider).addPoints(id, batch);
  }

  void _stopGps() {
    _sub?.cancel();
    _sub = null;
    _timer?.cancel();
    _timer = null;
    _id = null;
    if (ref.mounted) state = state.copyWith(listening: false);
  }
}

final recorderProvider = NotifierProvider<ActivityRecorder, RecorderState>(ActivityRecorder.new);

/// How good the GPS signal is, from the newest fix's accuracy.
enum GpsSignal {
  none('Finding GPS'),
  weak('Weak GPS'),
  good('Good GPS');

  const GpsSignal(this.label);
  final String label;

  static GpsSignal of(TrackPoint? fix, ActivityKind kind, DateTime now) {
    if (fix == null || now.difference(fix.at).inSeconds > 10) return GpsSignal.none;
    return fix.accuracy <= kind.maxAccuracy / 2 ? GpsSignal.good : GpsSignal.weak;
  }
}
