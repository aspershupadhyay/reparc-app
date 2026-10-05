/// Session and rest time from stored timestamps.
///
/// The app does not count ticks. It calculates time from saved instants, so
/// the values stay correct after a lock, a background period, or a restart.
Duration sessionElapsed({
  required DateTime startedAt,
  required DateTime? endedAt,
  required DateTime? pausedAt,
  required int pausedMs,
  required DateTime now,
}) {
  final end = endedAt ?? pausedAt ?? now;
  final d = end.difference(startedAt) - Duration(milliseconds: pausedMs);
  return d.isNegative ? Duration.zero : d;
}

/// Remaining rest time, or null when no rest timer runs.
///
/// The value can be negative when the user rests longer than the target.
Duration? restRemaining({
  required DateTime? restStartedAt,
  required int? restTargetSec,
  required DateTime now,
}) {
  if (restStartedAt == null || restTargetSec == null) return null;
  return restStartedAt.add(Duration(seconds: restTargetSec)).difference(now);
}
