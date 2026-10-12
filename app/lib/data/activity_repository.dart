import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../domain/session_time.dart';
import '../domain/track.dart';
import 'database.dart';
import 'models.dart';

const _uuid = Uuid();

/// A saved activity with its points worked into numbers.
class ActivityDetail {
  const ActivityDetail(this.activity, this.points, this.stats);
  final GpsActivity activity;
  final List<TrackPoint> points;
  final TrackStats stats;
}

/// GPS runs, walks, and rides (handbook 4.14). Every point is saved on the
/// phone as it arrives, so a closed app or a flat battery loses at most the
/// last few seconds. Nothing here uses the network.
class ActivityRepository {
  ActivityRepository(this.db, this.clock);

  final AppDatabase db;
  final Clock clock;

  DateTime get _now => clock().toUtc();

  /// The activity that records or is paused, if any. There is at most one.
  Stream<GpsActivity?> watchLive() =>
      (db.select(db.activities)
            ..where((a) => a.status.equalsValue(ActivityStatus.finished).not())
            ..orderBy([(a) => OrderingTerm.desc(a.startedAt)])
            ..limit(1))
          .watchSingleOrNull();

  Future<GpsActivity?> live() =>
      (db.select(db.activities)
            ..where((a) => a.status.equalsValue(ActivityStatus.finished).not())
            ..orderBy([(a) => OrderingTerm.desc(a.startedAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Starts recording, or returns the activity that already records.
  Future<String> start(ActivityKind kind) => db.transaction(() async {
    final existing = await live();
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    final local = clock();
    final now = local.toUtc();
    await db
        .into(db.activities)
        .insert(
          ActivitiesCompanion.insert(
            id: id,
            kind: kind,
            name: defaultName(kind, local),
            status: ActivityStatus.recording,
            startedAt: now,
            utcOffsetMinutes: local.timeZoneOffset.inMinutes,
            timeZoneName: local.timeZoneName,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  });

  /// "Morning run", "Evening ride": named by the local start time.
  static String defaultName(ActivityKind kind, DateTime local) {
    final h = local.hour;
    final part = h < 5
        ? 'Night'
        : h < 12
        ? 'Morning'
        : h < 17
        ? 'Afternoon'
        : h < 21
        ? 'Evening'
        : 'Night';
    return '$part ${kind.label.toLowerCase()}';
  }

  /// Saves fixes for [id] in the activity's current segment. Fixes that
  /// arrive while it is paused or finished are not saved.
  Future<int> addPoints(String id, List<TrackPoint> points) async {
    if (points.isEmpty) return 0;
    final a = await (db.select(db.activities)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (a == null || a.status != ActivityStatus.recording) return 0;
    await db.batch((b) {
      b.insertAll(db.activityPoints, [
        for (final p in points)
          ActivityPointsCompanion.insert(
            activityId: id,
            at: p.at.toUtc(),
            lat: p.lat,
            lon: p.lon,
            accuracy: p.accuracy,
            altitude: Value(p.altitude),
            altitudeAccuracy: Value(p.altitudeAccuracy),
            segment: a.segment,
          ),
      ]);
    });
    return points.length;
  }

  Future<void> pause(String id) => db.transaction(() async {
    final a = await _get(id);
    if (a.status != ActivityStatus.recording) return;
    await _write(id, ActivitiesCompanion(status: const Value(ActivityStatus.paused), pausedAt: Value(_now)));
  });

  /// Resumes in a new segment, so no distance is counted across the pause.
  Future<void> resume(String id) => db.transaction(() async {
    final a = await _get(id);
    if (a.status != ActivityStatus.paused) return;
    final paused = a.pausedAt == null ? 0 : _now.difference(a.pausedAt!).inMilliseconds;
    await _write(
      id,
      ActivitiesCompanion(
        status: const Value(ActivityStatus.recording),
        pausedAt: const Value(null),
        pausedMs: Value(a.pausedMs + (paused < 0 ? 0 : paused)),
        segment: Value(a.segment + 1),
      ),
    );
  });

  /// Elapsed time without pauses.
  Duration elapsed(GpsActivity a) => sessionElapsed(
    startedAt: a.startedAt,
    endedAt: a.endedAt,
    pausedAt: a.pausedAt,
    pausedMs: a.pausedMs,
    now: _now,
  );

  /// Ends the activity and saves its summary from the points.
  Future<void> finish(String id) => db.transaction(() async {
    final a = await _get(id);
    if (a.status == ActivityStatus.finished) return;
    final stats = trackStats(await points(id), a.kind);
    // A paused activity ends when it was paused, not now.
    final end = a.pausedAt ?? _now;
    await _write(
      id,
      ActivitiesCompanion(
        status: const Value(ActivityStatus.finished),
        endedAt: Value(end),
        pausedAt: const Value(null),
        distanceM: Value(stats.distance),
        movingSec: Value(stats.moving.inSeconds),
        elevationGainM: Value(stats.elevationGain),
        maxSpeed: Value(stats.maxSpeed),
      ),
    );
  });

  /// Deletes an activity and its points.
  Future<void> delete(String id) => (db.delete(db.activities)..where((a) => a.id.equals(id))).go();

  Future<void> rename(String id, String name) =>
      _write(id, ActivitiesCompanion(name: Value(name.trim().isEmpty ? 'Activity' : name.trim())));

  Future<void> setNote(String id, String? note) =>
      _write(id, ActivitiesCompanion(note: Value(note == null || note.trim().isEmpty ? null : note.trim())));

  Future<List<TrackPoint>> points(String id) async => [
    for (final p
        in await (db.select(db.activityPoints)
              ..where((x) => x.activityId.equals(id))
              ..orderBy([(x) => OrderingTerm.asc(x.at), (x) => OrderingTerm.asc(x.id)]))
            .get())
      TrackPoint(
        at: p.at,
        lat: p.lat,
        lon: p.lon,
        accuracy: p.accuracy,
        altitude: p.altitude,
        altitudeAccuracy: p.altitudeAccuracy,
        segment: p.segment,
      ),
  ];

  Future<ActivityDetail?> detail(String id, {double splitMetres = 1000}) async {
    final a = await (db.select(db.activities)..where((x) => x.id.equals(id))).getSingleOrNull();
    if (a == null) return null;
    final p = await points(id);
    return ActivityDetail(a, p, trackStats(p, a.kind, splitMetres: splitMetres));
  }

  Stream<ActivityDetail?> watchDetail(String id, {double splitMetres = 1000}) => db
      .tableUpdates(TableUpdateQuery.onAllTables([db.activities, db.activityPoints]))
      .asyncMap((_) => detail(id, splitMetres: splitMetres))
      .startWithFuture(() => detail(id, splitMetres: splitMetres));

  /// Finished activities, newest first.
  Stream<List<GpsActivity>> watchHistory({DateTime? fromUtc, DateTime? toUtc}) {
    final q = db.select(db.activities)
      ..where((a) => a.status.equalsValue(ActivityStatus.finished))
      ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]);
    if (fromUtc != null) q.where((a) => a.startedAt.isBiggerOrEqualValue(fromUtc));
    if (toUtc != null) q.where((a) => a.startedAt.isSmallerThanValue(toUtc));
    return q.watch();
  }

  Future<GpsActivity> _get(String id) => (db.select(db.activities)..where((a) => a.id.equals(id))).getSingle();

  Future<void> _write(String id, ActivitiesCompanion c) => (db.update(
    db.activities,
  )..where((a) => a.id.equals(id))).write(c.copyWith(updatedAt: Value(_now)));
}

extension<T> on Stream<T> {
  /// This stream, after [first] gives its value.
  Stream<T> startWithFuture(Future<T> Function() first) async* {
    yield await first();
    yield* this;
  }
}
