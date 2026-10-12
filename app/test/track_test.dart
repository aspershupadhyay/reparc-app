import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/domain/track.dart';

/// Metres per degree of latitude on the mean earth sphere.
const _mPerDeg = 6371008.8 * pi / 180;

void main() {
  final t0 = DateTime.utc(2026, 3, 2, 6);

  // A straight line north from Bengaluru at [speed] m/s, one fix a second.
  List<TrackPoint> line({
    required int seconds,
    required double speed,
    double accuracy = 5,
    int startSecond = 0,
    double startMetres = 0,
    int segment = 0,
    double Function(int s)? altitude,
  }) => [
    for (var s = 0; s <= seconds; s++)
      TrackPoint(
        at: t0.add(Duration(seconds: startSecond + s)),
        lat: 12.97 + (startMetres + s * speed) / _mPerDeg,
        lon: 77.59,
        accuracy: accuracy,
        altitude: altitude?.call(s),
        segment: segment,
      ),
  ];

  test('a steady 3 km run: distance, moving time, pace, and km splits', () {
    final s = trackStats(line(seconds: 1000, speed: 3), ActivityKind.run);
    expect(s.distance, closeTo(3000, 1));
    expect(s.moving.inSeconds, 1000);
    expect(fmtPace(s.paceSecPerKm), '5:33');
    // Smoothing lags by about a second, which can move a second between
    // splits; the total stays exact.
    for (final x in s.splits) {
      expect(x.time.inSeconds, closeTo(333, 1));
    }
    expect(s.maxSpeed, closeTo(3, 0.01));
  });

  test('standing still, GPS wander adds no distance and no moving time', () {
    final rnd = Random(1);
    final points = [
      for (var s = 0; s < 600; s++)
        TrackPoint(
          at: t0.add(Duration(seconds: s)),
          lat: 12.97 + (rnd.nextDouble() - 0.5) * 6 / _mPerDeg,
          lon: 77.59 + (rnd.nextDouble() - 0.5) * 6 / _mPerDeg,
          accuracy: 8,
        ),
    ];
    final s = trackStats(points, ActivityKind.walk);
    expect(s.distance, lessThan(15), reason: '10 minutes of wander within ±3 m');
    expect(s.moving.inSeconds, lessThan(30));
  });

  test('a GPS jump and imprecise fixes are dropped', () {
    final points = line(seconds: 200, speed: 3);
    points[100] = TrackPoint(at: points[100].at, lat: points[100].lat + 500 / _mPerDeg, lon: 77.59, accuracy: 5);
    points[150] = TrackPoint(at: points[150].at, lat: points[150].lat, lon: 77.59 + 0.01, accuracy: 60);
    final s = trackStats(points, ActivityKind.run);
    expect(s.distance, closeTo(600, 1));
    expect(s.used, hasLength(199));
  });

  test('no distance is counted across a pause', () {
    final first = line(seconds: 100, speed: 3);
    // After the pause the runner starts 2 km away (a bus ride).
    final second = line(seconds: 100, speed: 3, startSecond: 400, startMetres: 2300, segment: 1);
    final s = trackStats([...first, ...second], ActivityKind.run);
    expect(s.distance, closeTo(600, 1));
    expect(s.moving.inSeconds, 200);
  });

  test('a ride at car speed in town is kept; a car on the highway is a jump', () {
    expect(trackStats(line(seconds: 100, speed: 12), ActivityKind.ride).distance, closeTo(1200, 1));
    expect(trackStats(line(seconds: 100, speed: 30), ActivityKind.ride).distance, 0);
    expect(trackStats(line(seconds: 100, speed: 12), ActivityKind.run).distance, 0);
  });

  test('climbing counts real height and ignores altitude noise', () {
    final rnd = Random(3);
    // 60 m of climbing over 600 s, with ±1.5 m of noise on every fix.
    final s = trackStats(
      line(seconds: 600, speed: 2, altitude: (t) => 900 + t * 0.1 + (rnd.nextDouble() - 0.5) * 3),
      ActivityKind.walk,
    );
    expect(s.elevationGain, closeTo(60, 6));
    final flat = trackStats(
      line(seconds: 600, speed: 2, altitude: (t) => 900 + (rnd.nextDouble() - 0.5) * 3),
      ActivityKind.walk,
    );
    expect(flat.elevationGain, lessThan(3));
  });

  test('mile splits and the last part', () {
    final s = trackStats(line(seconds: 1200, speed: 3), ActivityKind.run, splitMetres: 1609.344);
    expect(s.splits, hasLength(3));
    expect(s.splits[0].time.inSeconds, closeTo(536, 1));
    expect(s.splits.last.metres, closeTo(3600 - 2 * 1609.344, 1));
    expect(fmtPace(s.paceSecPerKm, miles: true), '8:56');
  });

  test('current pace follows the last 30 seconds', () {
    final points = [
      ...line(seconds: 300, speed: 2.5),
      ...line(seconds: 60, speed: 4, startSecond: 301, startMetres: 752.5),
    ];
    expect(fmtPace(currentPace(points)), '4:10');
    expect(currentPace(points.take(1).toList()), isNull);
  });

  test('a noisy 1 km walk measures within 3 percent', () {
    for (final seed in [1, 2, 3, 4, 5]) {
      final rnd = Random(seed);
      double noise() => (rnd.nextDouble() + rnd.nextDouble() - 1) * 4;
      final points = [
        for (var s = 0; s <= 714; s++)
          TrackPoint(
            at: t0.add(Duration(seconds: s)),
            lat: 12.97 + (s * 1.4 + noise()) / _mPerDeg,
            lon: 77.59 + noise() / _mPerDeg,
            accuracy: 5,
          ),
      ];
      final d = trackStats(points, ActivityKind.walk).distance;
      expect(d, closeTo(1000, 30), reason: 'seed $seed: ${d.round()} m');
    }
  });

  test('smoothing keeps the corners of a square route', () {
    for (final seed in [1, 2, 3]) {
      final rnd = Random(seed);
      double noise() => (rnd.nextDouble() + rnd.nextDouble() - 1) * 4;
      // Four 250 m sides at 1.4 m/s.
      (double, double) at(double m) {
        final side = (m ~/ 250).clamp(0, 3);
        final r = m - side * 250;
        return switch (side) {
          0 => (r, 0.0),
          1 => (250.0, r),
          2 => (250 - r, 250.0),
          _ => (0.0, 250 - r),
        };
      }

      final points = [
        for (var s = 0; s <= 714; s++)
          () {
            final (n, e) = at(s * 1.4);
            return TrackPoint(
              at: t0.add(Duration(seconds: s)),
              lat: 12.97 + (n + noise()) / _mPerDeg,
              lon: 77.59 + (e + noise()) / (_mPerDeg * cos(12.97 * pi / 180)),
              accuracy: 5,
            );
          }(),
      ];
      final d = trackStats(points, ActivityKind.walk).distance;
      expect(d, closeTo(1000, 30), reason: 'seed $seed: ${d.round()} m');
    }
  });
}
