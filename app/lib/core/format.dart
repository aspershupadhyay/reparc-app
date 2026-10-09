import 'package:intl/intl.dart';

/// Text shown for a value the user has not recorded.
///
/// A missing value is never shown as zero (handbook 7.3).
const missingText = '—';

/// Screen-reader text for a missing value.
const missingLabel = 'not recorded';

String fmtNum(num? value, {int maxDecimals = 1}) {
  if (value == null) return missingText;
  final f = NumberFormat.decimalPatternDigits(decimalDigits: 0)
    ..maximumFractionDigits = maxDecimals
    ..minimumFractionDigits = 0;
  return f.format(value);
}

String fmtWithUnit(num? value, String? unit, {int maxDecimals = 1}) {
  if (value == null) return missingText;
  final n = fmtNum(value, maxDecimals: maxDecimals);
  return unit == null || unit.isEmpty ? n : '$n $unit';
}

/// Semantics label for a value with a unit.
String speakWithUnit(num? value, String? unit) {
  if (value == null) return missingLabel;
  return fmtWithUnit(value, unit, maxDecimals: 2);
}

/// Formats a duration as m:ss or h:mm:ss.
String fmtClock(Duration d) {
  final neg = d.isNegative;
  final abs = d.abs();
  final h = abs.inHours;
  final m = abs.inMinutes.remainder(60);
  final s = abs.inSeconds.remainder(60);
  final ss = s.toString().padLeft(2, '0');
  final body = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
  return neg ? '-$body' : body;
}

String speakDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  final parts = <String>[
    if (h > 0) '$h hour${h == 1 ? '' : 's'}',
    if (m > 0) '$m minute${m == 1 ? '' : 's'}',
    if (h == 0) '$s second${s == 1 ? '' : 's'}',
  ];
  return parts.join(' ');
}

/// Joins short facts with " · " so a line never starts with the dot, and a
/// short fact such as "15 sets" or "~48 min" never splits across lines.
/// Longer parts (a muscle list) can still wrap at their own spaces.
String metaLine(Iterable<String> parts) =>
    parts.where((x) => x.isNotEmpty).map((x) => x.length <= 14 ? x.replaceAll(' ', '\u00A0') : x).join('\u00A0· ');

String fmtDayLong(DateTime d) => DateFormat('EEEE, d MMMM y').format(d);
String fmtDayShort(DateTime d) => DateFormat('EEE d MMM').format(d);
String fmtDayMonth(DateTime d) => DateFormat('d MMM').format(d);
String fmtTime(DateTime d) => DateFormat.jm().format(d);
String fmtDateTime(DateTime d) => DateFormat('d MMM y, HH:mm').format(d);

/// Parses a decimal from user text. Returns null for empty text.
///
/// Accepts a comma as the decimal mark. Returns [double.nan] for text that
/// is not a number, so the caller can show a validation error.
double? parseDecimal(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t) ?? double.nan;
}

int? parseWhole(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  return int.tryParse(t) ?? -1;
}
