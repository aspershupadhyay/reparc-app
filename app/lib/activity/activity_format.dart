import '../core/format.dart';
import '../domain/track.dart';

/// Distance as a number and a unit for big displays: ('2.31', 'km').
/// Kilometres and miles keep two decimals, as running apps show them.
(String, String) distanceParts(double metres, String unit) => switch (unit) {
  'mi' => ((metres / 1609.344).toStringAsFixed(2), 'mi'),
  'm' => (fmtNum(metres, maxDecimals: 0), 'm'),
  _ => ((metres / 1000).toStringAsFixed(2), 'km'),
};

/// "/km" or "/mi" for pace.
String paceUnit(String unit) => unit == 'mi' ? '/mi' : '/km';

/// Pace for runs and walks, speed for rides: ('5:12', '/km') or
/// ('24.3', 'km/h'). The value is '–' when there is not enough data.
(String, String) paceOrSpeed(ActivityKind kind, {double? secPerKm, double? metresPerSec, required String unit}) {
  final miles = unit == 'mi';
  if (kind.showsSpeed) {
    final v = metresPerSec ?? (secPerKm == null || secPerKm <= 0 ? null : 1000 / secPerKm);
    if (v == null) return ('–', miles ? 'mph' : 'km/h');
    return ((miles ? v * 2.236936 : v * 3.6).toStringAsFixed(1), miles ? 'mph' : 'km/h');
  }
  final s = secPerKm ?? (metresPerSec == null || metresPerSec <= 0 ? null : 1000 / metresPerSec);
  return (fmtPace(s, miles: miles) ?? '–', paceUnit(unit));
}

/// "1:02:15" or "24:05".
String fmtActivityTime(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
