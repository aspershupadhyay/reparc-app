import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/activity/location_source.dart';
import 'package:reparc/activity/recorder.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/domain/track.dart';

import 'fake_location.dart';
import 'helpers.dart';

const _mPerDeg = 6371008.8 * pi / 180;

void main() {
  test('records fixes, turns GPS off while paused, and finishes', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final gps = FakeLocation();
    final clock = FakeClock(DateTime(2026, 3, 2, 6));
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        locationSourceProvider.overrideWithValue(gps),
      ],
    );
    addTearDown(c.dispose);
    final rec = c.read(recorderProvider.notifier);

    expect(await rec.start(ActivityKind.run), LocationAccess.allowed);
    final repo = c.read(activityRepoProvider);
    final live = (await repo.live())!;
    expect(gps.on, isTrue);

    final t0 = DateTime.utc(2026, 3, 2, 0, 30);
    for (var s = 0; s <= 100; s++) {
      gps.add(
        TrackPoint(
          at: t0.add(Duration(seconds: s)),
          lat: 12.97 + s * 3 / _mPerDeg,
          lon: 77.59,
          accuracy: 4,
        ),
      );
    }
    await pumpEventQueue();
    expect(c.read(recorderProvider).lastFix?.accuracy, 4);
    expect(
      GpsSignal.of(c.read(recorderProvider).lastFix, ActivityKind.run, t0.add(const Duration(seconds: 101))),
      GpsSignal.good,
    );

    await rec.pause();
    expect(gps.on, isFalse, reason: 'GPS is off while paused');
    expect(await repo.points(live.id), hasLength(101), reason: 'Pause saves the fixes not yet saved');

    await rec.resume((await repo.live())!);
    expect(gps.on, isTrue);
    expect(gps.starts, 2);
    final id = await rec.finish(live.id);
    final done = (await repo.detail(id!))!;
    expect(done.activity.status, ActivityStatus.finished);
    expect(done.activity.distanceM, closeTo(300, 2));
    expect(gps.on, isFalse);
  });

  test('fixes are saved every few seconds while recording', () {
    fakeAsync((async) {
      final db = memoryDb();
      final gps = FakeLocation();
      final c = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db), locationSourceProvider.overrideWithValue(gps)],
      );
      final rec = c.read(recorderProvider.notifier);
      rec.start(ActivityKind.walk);
      async.flushMicrotasks();
      gps.add(TrackPoint(at: DateTime.utc(2026), lat: 1, lon: 1, accuracy: 5));
      async.elapse(ActivityRecorder.saveEvery + const Duration(milliseconds: 100));
      List<Object>? saved;
      c
          .read(activityRepoProvider)
          .live()
          .then((a) => c.read(activityRepoProvider).points(a!.id))
          .then((p) => saved = p);
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 100));
      expect(saved, hasLength(1));
      c.dispose();
      db.close();
      async.flushMicrotasks();
    });
  });

  test('a recording picks up again after a restart; a refused permission starts nothing', () async {
    final db = memoryDb();
    addTearDown(db.close);
    final gps = FakeLocation();
    final c = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db), locationSourceProvider.overrideWithValue(gps)],
    );
    addTearDown(c.dispose);
    final id = await c.read(activityRepoProvider).start(ActivityKind.ride);
    await c.read(recorderProvider.notifier).attach((await c.read(activityRepoProvider).live())!);
    expect(gps.on, isTrue);
    await c.read(recorderProvider.notifier).discard(id);
    expect(await c.read(activityRepoProvider).live(), isNull);

    gps.access = LocationAccess.deniedForever;
    expect(await c.read(recorderProvider.notifier).start(ActivityKind.run), LocationAccess.deniedForever);
    expect(await c.read(activityRepoProvider).live(), isNull);
  });
}
