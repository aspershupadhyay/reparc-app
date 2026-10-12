import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/activity_repository.dart';
import 'package:reparc/data/data_controls.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/domain/track.dart';

import 'helpers.dart';

const _mPerDeg = 6371008.8 * pi / 180;

void main() {
  List<TrackPoint> run(DateTime from, int seconds, {double startMetres = 0}) => [
    for (var s = 0; s <= seconds; s++)
      TrackPoint(
        at: from.add(Duration(seconds: s)),
        lat: 12.97 + (startMetres + s * 3) / _mPerDeg,
        lon: 77.59,
        accuracy: 5,
        altitude: 900,
      ),
  ];

  test('record, pause, resume, and finish a run', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = FakeClock(DateTime(2026, 3, 2, 6, 30));
    final repo = ActivityRepository(db, clock.call);

    final id = await repo.start(ActivityKind.run);
    expect(await repo.start(ActivityKind.ride), id, reason: 'Only one activity records at a time');
    final a = (await repo.live())!;
    expect((a.name, a.status), ('Morning run', ActivityStatus.recording));

    await repo.addPoints(id, run(clock.now.toUtc(), 200));
    clock.advance(const Duration(seconds: 200));
    await repo.pause(id);
    // Fixes while paused are not saved.
    expect(await repo.addPoints(id, run(clock.now.toUtc(), 10, startMetres: 900)), 0);
    clock.advance(const Duration(minutes: 5));
    await repo.resume(id);
    await repo.addPoints(id, run(clock.now.toUtc(), 100, startMetres: 2000));
    clock.advance(const Duration(seconds: 100));

    final live = (await repo.live())!;
    expect(repo.elapsed(live), const Duration(seconds: 300), reason: 'The 5 minute pause is left out');
    await repo.finish(id);

    final done = (await repo.detail(id))!;
    expect(done.activity.status, ActivityStatus.finished);
    expect(done.activity.distanceM, closeTo(900, 2), reason: '600 m + 300 m; nothing across the pause');
    expect(done.activity.movingSec, 300);
    expect(done.points.map((p) => p.segment).toSet(), {0, 1});
    expect(await repo.live(), isNull);
    expect((await repo.watchHistory().first).single.id, id);
  });

  test('export, restore, and delete include activities', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = FakeClock(DateTime(2026, 3, 2, 18));
    final repo = ActivityRepository(db, clock.call);
    final id = await repo.start(ActivityKind.ride);
    await repo.addPoints(id, run(clock.now.toUtc(), 60));
    await repo.finish(id);

    final controls = DataControls(db, clock.call);
    final full = await controls.exportJson(appVersion: '0.5.0');
    final tables = (jsonDecode(full) as Map)['tables'] as Map;
    expect((tables['activities'] as List).single['name'], 'Evening ride');
    expect(tables['activityPoints'] as List, hasLength(61));
    final noRoutes = jsonDecode(await controls.exportJson(appVersion: '0.5.0', scopes: {'workout'})) as Map;
    expect((noRoutes['tables'] as Map)['activityPoints'], isEmpty, reason: 'Routes only with the activity scope');

    await controls.deleteAll();
    expect(await db.select(db.activities).get(), isEmpty);
    expect(await db.select(db.activityPoints).get(), isEmpty);

    await controls.importJson(full);
    final back = (await repo.detail(id))!;
    expect(back.points, hasLength(61));
    expect(back.activity.distanceM, closeTo(180, 2));
  });

  test('deleting an activity deletes its points', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final clock = FakeClock(DateTime(2026, 3, 2, 18));
    final repo = ActivityRepository(db, clock.call);
    final id = await repo.start(ActivityKind.walk);
    await repo.addPoints(id, run(clock.now.toUtc(), 30));
    await repo.delete(id);
    expect(await db.select(db.activityPoints).get(), isEmpty);
  });
}
