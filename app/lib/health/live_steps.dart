import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Today's steps, live.
///
/// The total comes from the health store (exact, with duplicates between
/// phone and watch removed). While RepArc is open, each step the phone's
/// sensor counts after that read is added. When the store is read again,
/// counting starts again from its new total. The number never goes down
/// within a day: the store can lag behind the sensor for a few minutes.
class LiveStepsController extends Notifier<({String day, int? steps})> {
  StreamSubscription<int>? _sub;
  int? _base;

  @override
  ({String day, int? steps}) build() {
    final s = ref.watch(currentSettingsProvider);
    final stored = ref.watch(healthTodayProvider.select((v) => v.value?.steps));
    final day = dayKey(dayOf(ref.read(clockProvider)()));
    final before = stateOrNull;
    final kept = before != null && before.day == day ? before.steps : null;
    ref.onDispose(() {
      _sub?.cancel();
      _sub = null;
    });
    _base = null;
    final start = _best(kept, stored);
    if (stored != null && s.liveSteps && s.health.contains(HealthFeature.steps.name)) {
      _sub = ref.read(stepSensorProvider).counts().listen(
        (count) {
          final base = _base ??= count;
          // A restart of the phone resets the sensor to 0.
          if (count < base) _base = count;
          final today = dayKey(dayOf(ref.read(clockProvider)()));
          if (today != state.day) {
            // Midnight: the next read of the store starts the new day.
            ref.invalidate(healthTodayProvider);
            return;
          }
          final now = stored + (count - _base!);
          if (state.steps == null || now > state.steps!) state = (day: today, steps: now);
        },
        // No sensor or no permission: the store's total still shows.
        onError: (Object _) {},
      );
    }
    return (day: day, steps: start);
  }

  static int? _best(int? a, int? b) => a == null ? b : (b == null || a > b ? a : b);
}

final liveStepsProvider = NotifierProvider.autoDispose<LiveStepsController, ({String day, int? steps})>(
  LiveStepsController.new,
);
