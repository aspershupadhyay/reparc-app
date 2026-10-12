import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/features/me/health_screen.dart';
import 'package:reparc/health/health_service.dart';
import 'package:reparc/health/live_steps.dart';

import 'fake_health.dart';
import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<(ProviderContainer, FakeHealth, FakeStepSensor)> setUpLive({required bool live}) async {
    final db = memoryDb();
    addTearDown(db.close);
    final settings = SettingsRepository(db);
    await settings.setHealth('steps', true);
    await settings.setHealth('distance', true);
    if (live) await settings.setLiveSteps(true);
    final health = FakeHealth()
      ..steps = {'2026-03-02': 1000}
      ..distance = {'2026-03-02': 750};
    final sensor = FakeStepSensor();
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => DateTime(2026, 3, 2, 9)),
        healthSourceProvider.overrideWithValue(health),
        stepSensorProvider.overrideWithValue(sensor),
      ],
    );
    addTearDown(c.dispose);
    c.listen(settingsProvider, (_, _) {});
    await c.read(settingsProvider.future);
    c.listen(liveStepsProvider, (_, _) {});
    await c.read(healthTodayProvider.future);
    await pumpEventQueue();
    return (c, health, sensor);
  }

  test('live steps add the sensor\'s new steps to the health total and never go down', () async {
    final (c, health, sensor) = await setUpLive(live: true);
    expect(c.read(liveStepsProvider).steps, 1000);
    expect(c.read(healthTodayProvider).value?.distance, 750);

    // The first count is only the starting point.
    sensor.controller.add(52000);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1000);
    sensor.controller.add(52020);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1020);

    // The store is read again but lags behind: the number stays.
    health.steps = {'2026-03-02': 1010};
    c.invalidate(healthTodayProvider);
    await c.read(healthTodayProvider.future);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1020);
    sensor.controller.add(52020);
    await pumpEventQueue();
    sensor.controller.add(52035);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1025, reason: '1010 from the store + 15 new steps');

    // A phone restart resets the sensor; counting goes on from there.
    sensor.controller.add(3);
    await pumpEventQueue();
    sensor.controller.add(10);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1025, reason: '1010 + 7 is still below 1025');
    sensor.controller.add(30);
    await pumpEventQueue();
    expect(c.read(liveStepsProvider).steps, 1037, reason: '1010 + 27 since the restart');
  });

  test('with Live steps off the sensor is not used', () async {
    final (c, _, sensor) = await setUpLive(live: false);
    expect(c.read(liveStepsProvider).steps, 1000);
    expect(sensor.listens, 0);
  });

  test('day runs cover the range in order, one bucket a day', () {
    final runs = dayRuns(DateTime(2026, 3, 1), DateTime(2026, 4, 9));
    expect(runs.first.$1, DateTime(2026, 3, 1));
    expect(runs.last.$2, DateTime(2026, 4, 10));
    var days = 0;
    for (final (i, (start, end, slice)) in runs.indexed) {
      if (i > 0) expect(start, runs[i - 1].$2, reason: 'No gap and no overlap');
      expect(end.difference(start).inSeconds % slice, 0, reason: 'Whole buckets only');
      days += end.difference(start).inSeconds ~/ slice;
    }
    expect(days, 40);
  });
}
