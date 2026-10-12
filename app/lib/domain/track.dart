import 'dart:math' as math;

/// GPS activities: runs, walks, and rides (handbook 4.14).
///
/// Everything here works from stored points and timestamps, so the numbers
/// are the same live, after a restart, and when a saved activity is opened.
enum ActivityKind {
  run('Run', maxSpeed: 11, movingSpeed: 1.0, maxAccuracy: 20, drift: 3),
  walk('Walk', maxSpeed: 4, movingSpeed: 0.4, maxAccuracy: 20, drift: 1.5),
  ride('Ride', maxSpeed: 25, movingSpeed: 1.5, maxAccuracy: 25, drift: 6);

  const ActivityKind(
    this.label, {
    required this.maxSpeed,
    required this.movingSpeed,
    required this.maxAccuracy,
    required this.drift,
  });

  /// How fast (m/s) the true position can wander from the smoothed one
  /// between fixes: the smoothing filter's process noise.
  final double drift;

  final String label;

  /// Faster than this (m/s) between two fixes is a GPS jump, not movement:
  /// 11 m/s is a 1:31 min/km pace, 25 m/s is 90 km/h.
  final double maxSpeed;

  /// Slower than this (m/s) counts as standing, not moving time.
  final double movingSpeed;

  /// Fixes less precise than this (metres) are not used.
  final double maxAccuracy;

  /// Rides show speed; runs and walks show pace.
  bool get showsSpeed => this == ActivityKind.ride;
}

/// One GPS fix. [segment] grows by one after each pause, so no distance is
/// counted across a pause.
class TrackPoint {
  const TrackPoint({
    required this.at,
    required this.lat,
    required this.lon,
    required this.accuracy,
    this.altitude,
    this.altitudeAccuracy,
    this.segment = 0,
  });

  final DateTime at;
  final double lat;
  final double lon;

  /// Horizontal accuracy in metres (68% radius).
  final double accuracy;
  final double? altitude;
  final double? altitudeAccuracy;
  final int segment;
}

/// Mean earth radius in metres (IUGG).
const _earthRadius = 6371008.8;

/// Great-circle distance in metres.
double haversine(double lat1, double lon1, double lat2, double lon2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * _earthRadius * math.asin(math.min(1, math.sqrt(a)));
}

/// The time to cover one split (a kilometre or a mile).
class TrackSplit {
  const TrackSplit(this.index, this.metres, this.time);

  /// 1 for the first split.
  final int index;

  /// The split's length: the full unit, or less for the last part.
  final double metres;
  final Duration time;
}

class TrackStats {
  const TrackStats({
    required this.distance,
    required this.moving,
    required this.elevationGain,
    required this.maxSpeed,
    required this.splits,
    required this.used,
  });

  /// Metres.
  final double distance;

  /// Time spent moving. Stops at lights and pauses are not counted.
  final Duration moving;

  /// Metres climbed, or null without altitude. GPS altitude is rough, so
  /// this is an estimate.
  final double? elevationGain;

  /// m/s, over at least 10 seconds, or null.
  final double? maxSpeed;

  final List<TrackSplit> splits;

  /// Points that passed the filters: the route to draw.
  final List<TrackPoint> used;

  /// Seconds per kilometre over moving time, or null.
  double? get paceSecPerKm => distance < 10 ? null : moving.inMilliseconds / 1000 / (distance / 1000);

  /// Metres per second over moving time, or null.
  double? get avgSpeed => moving.inSeconds == 0 ? null : distance / (moving.inMilliseconds / 1000);
}

/// Whether [p] is good enough to use after [last], the last point used.
///
/// A fix is dropped when its accuracy is poor, when it is not later than
/// the last one, or when reaching it would need a speed this activity
/// cannot reach (a GPS jump).
bool acceptPoint(TrackPoint p, TrackPoint? last, ActivityKind kind) {
  if (p.accuracy <= 0 || p.accuracy > kind.maxAccuracy) return false;
  if (last == null || last.segment != p.segment) return true;
  final dt = p.at.difference(last.at).inMilliseconds / 1000;
  if (dt <= 0) return false;
  final d = haversine(last.lat, last.lon, p.lat, p.lon);
  return d / dt <= kind.maxSpeed;
}

/// The distance from [a] to [b] that counts. Standing still, GPS wanders a
/// few metres; a step shorter than the two fixes' uncertainty is wander,
/// not movement.
double? countedStep(TrackPoint a, TrackPoint b) {
  final d = haversine(a.lat, a.lon, b.lat, b.lon);
  // The anchor stays put until the user has truly moved, so slow walking
  // still adds up along the route; only wander is left out.
  final noise = math.max(3.0, (a.accuracy + b.accuracy) / 2);
  return d < noise ? null : d;
}

/// Works out distance, moving time, climbing, and splits from raw [points]
/// in time order. [splitMetres] is 1000 for kilometres, 1609.344 for miles.
TrackStats trackStats(List<TrackPoint> points, ActivityKind kind, {double splitMetres = 1000}) {
  final used = <TrackPoint>[];
  var distance = 0.0;
  var movingMs = 0;
  double? gain;
  double? altRef;
  double? maxSpeed;
  final splits = <TrackSplit>[];
  var splitStartMs = 0;
  // The last point that distance was counted to: the anchor.
  TrackPoint? anchor;
  // A 10 s window for the top speed.
  final window = <(int ms, double m)>[];

  void addStep(TrackPoint from, TrackPoint to, double? counted) {
    final step = counted ?? haversine(from.lat, from.lon, to.lat, to.lon);
    if (step <= 0) return;
    // The catch-up to a segment's raw end can take no time at all.
    final ms = math.max(0, to.at.difference(from.at).inMilliseconds);
    // Long gaps (the fix was lost) and slow steps are not moving time.
    final moved = ms > 0 && step / (ms / 1000) >= kind.movingSpeed && ms <= 60000;
    final before = distance;
    distance += step;
    if (moved) movingMs += ms;

    // Splits: the moving time at which each full unit was reached, found
    // by sharing this step's time out along its length.
    var crossed = (before / splitMetres).floor() + 1;
    while (distance >= crossed * splitMetres) {
      final part = (crossed * splitMetres - before) / step;
      final at = (movingMs - (moved ? ms : 0)) + (moved ? (ms * part).round() : 0);
      splits.add(TrackSplit(crossed, splitMetres, Duration(milliseconds: at - splitStartMs)));
      splitStartMs = at;
      crossed++;
    }

    // Top speed over at least 10 seconds. A segment's catch-up to its raw
    // end makes up a few metres of smoothing lag at once: not a sprint.
    if (counted == null) return;
    window.add((to.at.millisecondsSinceEpoch, distance));
    while (window.length > 2 && window.last.$1 - window[1].$1 >= 10000) {
      window.removeAt(0);
    }
    final span = (window.last.$1 - window.first.$1) / 1000;
    if (span >= 10) {
      final v = (window.last.$2 - window.first.$2) / span;
      if (v <= kind.maxSpeed && (maxSpeed == null || v > maxSpeed!)) maxSpeed = v;
    }
  }

  // Smoothing: a Kalman filter on position. Each fix pulls the estimate in
  // proportion to how precise it is, against how far the user could have
  // moved since the last one. Raw GPS zig-zags a few metres side to side,
  // which adds about 10% to a walk.
  double? fLat, fLon;
  var fVar = 0.0;
  TrackPoint? raw;
  // The raw fix behind each smoothed one. A segment ends at its raw last
  // fix: the smoothed track trails a few metres behind a moving user.
  final rawOf = <TrackPoint, TrackPoint>{};

  for (final p0 in points) {
    final rawLast = raw;
    if (!acceptPoint(p0, rawLast, kind)) continue;
    raw = p0;
    if (fLat == null || rawLast == null || rawLast.segment != p0.segment) {
      fLat = p0.lat;
      fLon = p0.lon;
      fVar = p0.accuracy * p0.accuracy;
    } else {
      final dt = p0.at.difference(rawLast.at).inMilliseconds / 1000;
      fVar += dt * kind.drift * kind.drift;
      final k = fVar / (fVar + p0.accuracy * p0.accuracy);
      fLat = fLat + k * (p0.lat - fLat);
      fLon = fLon! + k * (p0.lon - fLon);
      fVar = (1 - k) * fVar;
    }
    final p = TrackPoint(
      at: p0.at,
      lat: fLat,
      lon: fLon,
      accuracy: math.sqrt(fVar),
      altitude: p0.altitude,
      altitudeAccuracy: p0.altitudeAccuracy,
      segment: p0.segment,
    );
    final last = used.isEmpty ? null : used.last;
    used.add(p);
    rawOf[p] = p0;

    // Climbing with a 3 m dead band, from fixes with a usable altitude.
    final alt = p.altitude;
    if (alt != null && (p.altitudeAccuracy == null || p.altitudeAccuracy! <= 15)) {
      gain ??= 0;
      final ref = altRef;
      if (ref == null) {
        altRef = alt;
      } else if (alt > ref + 3) {
        gain += alt - ref;
        altRef = alt;
      } else if (alt < ref - 3) {
        altRef = alt;
      }
    }

    if (anchor == null || anchor.segment != p.segment) {
      // A pause (or the start): finish the last segment first.
      if (anchor != null && last != null) addStep(anchor, rawOf[last]!, null);
      anchor = p;
      window.clear();
      continue;
    }
    final step = countedStep(anchor, p);
    if (step == null) continue;
    addStep(anchor, p, step);
    anchor = p;
  }
  // The finish: the last few metres up to the last fix count too.
  if (anchor != null && used.isNotEmpty && used.last.segment == anchor.segment) {
    addStep(anchor, rawOf[used.last]!, null);
  }

  final rest = distance - splits.length * splitMetres;
  if (rest >= 10) {
    splits.add(TrackSplit(splits.length + 1, rest, Duration(milliseconds: movingMs - splitStartMs)));
  }
  return TrackStats(
    distance: distance,
    moving: Duration(milliseconds: movingMs),
    elevationGain: gain,
    maxSpeed: maxSpeed,
    splits: splits,
    used: used,
  );
}

/// Pace as "5:07" (per km or mile), or null.
String? fmtPace(double? secPerKm, {bool miles = false}) {
  if (secPerKm == null || !secPerKm.isFinite || secPerKm <= 0) return null;
  final s = (miles ? secPerKm * 1.609344 : secPerKm).round();
  if (s >= 60 * 60) return null;
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

/// Pace over the last [window] of moving: the pace the runner sees now.
double? currentPace(List<TrackPoint> used, {Duration window = const Duration(seconds: 30)}) {
  if (used.length < 2) return null;
  final last = used.last;
  var metres = 0.0;
  var i = used.length - 1;
  while (i > 0 && last.at.difference(used[i - 1].at) <= window && used[i - 1].segment == last.segment) {
    metres += haversine(used[i - 1].lat, used[i - 1].lon, used[i].lat, used[i].lon);
    i--;
  }
  final secs = last.at.difference(used[i].at).inMilliseconds / 1000;
  if (metres < 20 || secs < 5) return null;
  return secs / (metres / 1000);
}
