/// Local calendar day helpers.
///
/// The app stores a local day key (yyyy-MM-dd) with each meal entry. It
/// stores UTC instants plus the UTC offset for workout sessions. This keeps
/// the user's day view stable when the device time zone changes.
DateTime dayOf(DateTime local) => DateTime(local.year, local.month, local.day);

String dayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime parseDayKey(String key) {
  final p = key.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p[2]);
}

DateTime addDays(DateTime day, int n) => DateTime(day.year, day.month, day.day + n);

/// Local day of an instant that was recorded with [offsetMinutes].
DateTime localDayOfInstant(DateTime utc, int offsetMinutes) {
  final shifted = utc.toUtc().add(Duration(minutes: offsetMinutes));
  return DateTime(shifted.year, shifted.month, shifted.day);
}
