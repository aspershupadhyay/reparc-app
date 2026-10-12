import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:pedometer/pedometer.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import '../data/providers.dart';
import '../features/me/health_screen.dart';
import 'health_service.dart';

/// The phone's own step counter (handbook 9.5).
///
/// Health Connect and Apple Health do not tell apps when new steps arrive,
/// and the apps that write steps there do it in batches. The phone's step
/// sensor counts each step as it happens, so it fills the gap between two
/// reads of the health store.
abstract class StepSensor {
  /// Asks for the "Physical activity" (Android) permission. True when
  /// allowed. On iPhone the system asks on first use, so this is true.
  Future<bool> request();

  /// The sensor's running count. The start value means nothing by itself
  /// (on Android it counts from the last restart); only the change counts.
  Stream<int> counts();
}

class PlatformStepSensor implements StepSensor {
  static const _channel = MethodChannel('app.reparc/health');

  @override
  Future<bool> request() async {
    if (!Platform.isAndroid) return true;
    return await _channel.invokeMethod<bool>('requestActivity') ?? false;
  }

  @override
  Stream<int> counts() => Pedometer.stepCountStream.map((e) => e.steps);
}

final stepSensorProvider = Provider<StepSensor>((ref) => PlatformStepSensor());

/// How the phone says the user is moving.
enum Motion { vehicle, bicycle, onFoot, still, unknown }

/// The phone's activity recognition: Google Play services on Android, Core
/// Motion on iPhone. It reads only while RepArc is open (handbook 9.5).
abstract class MotionSource {
  Stream<Motion> motion();
}

class PlatformMotionSource implements MotionSource {
  @override
  Stream<Motion> motion() => ActivityRecognition()
      // Only while the app is open: no service of its own in the background.
      .activityStream(runForegroundService: false)
      // A weak guess is not enough to stop counting.
      .where((e) => e.confidence >= 50)
      .map(
        (e) => switch (e.type) {
          ActivityType.IN_VEHICLE => Motion.vehicle,
          ActivityType.ON_BICYCLE => Motion.bicycle,
          ActivityType.ON_FOOT || ActivityType.WALKING || ActivityType.RUNNING => Motion.onFoot,
          ActivityType.STILL => Motion.still,
          _ => Motion.unknown,
        },
      );
}

final motionSourceProvider = Provider<MotionSource>((ref) => PlatformMotionSource());

/// Today's live steps and whether counting is held because the user is in
/// a vehicle or on a bike.
typedef LiveSteps = ({String day, int? steps, bool held});

/// Today's steps, live.
///
/// The total comes from the health store (exact, with duplicates between
/// phone and watch removed). While RepArc is open, each step the phone's
/// sensor counts after that read is added. When the store is read again,
/// counting starts again from its new total. The number never goes down
/// within a day: the store can lag behind the sensor for a few minutes.
///
/// Road bumps in a car, bus, auto-rickshaw, or on a motorbike, and pedalling
/// on a bike, can look like steps to the sensor. While the phone says the
/// user is in a vehicle or on a bicycle, sensor steps are not added.
class LiveStepsController extends Notifier<LiveSteps> {
  StreamSubscription<int>? _sub;
  StreamSubscription<Motion>? _motion;
  int? _last;
  var _counted = 0;
  var _held = false;

  @override
  LiveSteps build() {
    final s = ref.watch(currentSettingsProvider);
    final stored = ref.watch(healthTodayProvider.select((v) => v.value?.steps));
    final day = dayKey(dayOf(ref.read(clockProvider)()));
    final before = stateOrNull;
    final kept = before != null && before.day == day ? before.steps : null;
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
      _motion?.cancel();
      _motion = null;
    });
    _last = null;
    _counted = 0;
    final start = _best(kept, stored);
    if (stored != null && s.liveSteps && s.health.contains(HealthFeature.steps.name)) {
      _motion = ref.read(motionSourceProvider).motion().listen(
        (m) {
          final held = m == Motion.vehicle || m == Motion.bicycle;
          if (held != _held) {
            _held = held;
            state = (day: state.day, steps: state.steps, held: held);
          }
        },
        // Without activity recognition, steps are counted as before.
        onError: (Object _) {},
      );
      _sub = ref.read(stepSensorProvider).counts().listen(
        (count) {
          final last = _last;
          _last = count;
          if (last == null) return;
          // A restart of the phone resets the sensor to 0.
          final added = count >= last ? count - last : count;
          final today = dayKey(dayOf(ref.read(clockProvider)()));
          if (today != state.day) {
            // Midnight: the next read of the store starts the new day.
            ref.invalidate(healthTodayProvider);
            return;
          }
          if (_held) return;
          _counted += added;
          final now = stored + _counted;
          if (state.steps == null || now > state.steps!) state = (day: today, steps: now, held: _held);
        },
        // No sensor or no permission: the store's total still shows.
        onError: (Object _) {},
      );
    }
    return (day: day, steps: start, held: _held);
  }

  static int? _best(int? a, int? b) => a == null ? b : (b == null || a > b ? a : b);
}

final liveStepsProvider = NotifierProvider.autoDispose<LiveStepsController, LiveSteps>(LiveStepsController.new);
