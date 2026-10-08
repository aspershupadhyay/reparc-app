import 'dart:async';

import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen on while any feature needs it. Each feature holds its
/// own reason, so one feature that stops does not turn the screen off for
/// another.
abstract final class ScreenAwake {
  static final _reasons = <String>{};

  /// Holds or releases the screen for [reason].
  static void hold(String reason, bool on) {
    final before = _reasons.isNotEmpty;
    on ? _reasons.add(reason) : _reasons.remove(reason);
    final after = _reasons.isNotEmpty;
    if (before == after) return;
    try {
      unawaited(WakelockPlus.toggle(enable: after).catchError((_) {}));
    } catch (_) {
      // No wakelock on this platform. The app still works.
    }
  }
}
