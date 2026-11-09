import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/health/health_service.dart';
import 'package:reparc/health/live_steps.dart';

import 'fake_health.dart';
import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeHealth health;
  late FakeStepSensor sensor;
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  setUp(() {
    db = memoryDb();
    health = FakeHealth()
      ..steps = {'2026-03-01': 8000, '2026-03-02': 4321}
      ..distance = {'2026-03-01': 6000, '2026-03-02': 3250};
    sensor = FakeStepSensor();
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, String at) async {
    // Tall enough that every card is built without scrolling.
    tester.view.physicalSize = const Size(1170, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final s = SettingsRepository(db);
      await s.setHealth('steps', true);
      await s.setHealth('distance', true);
      await s.setOnboarded();
      await s.setIntroSeen();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 3, 2, 18)),
          libraryProvider.overrideWith((ref) async => library),
          healthSourceProvider.overrideWithValue(health),
          stepSensorProvider.overrideWithValue(sensor),
          motionSourceProvider.overrideWithValue(FakeMotion()),
        ],
        child: ReparcApp(router: buildRouter(initialLocation: at)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Drift closes its queries on a zero-length timer; let it run.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('Home shows today\'s steps and distance from the health store', (tester) async {
    await pumpApp(tester, '/home');
    expect(find.textContaining('4,321', findRichText: true), findsOneWidget);
    expect(find.textContaining('today · 3.25 km', findRichText: true), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Live steps asks for the sensor permission and counts new steps', (tester) async {
    await pumpApp(tester, '/me/health');
    await tester.tap(find.text('Live steps'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Live steps')).value, isTrue);
    expect(find.text('Steps: 4321 '), findsOneWidget);
    sensor.controller
      ..add(900)
      ..add(912);
    await tester.pumpAndSettle();
    expect(find.text('Steps: 4333 '), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('Allow all asks for every type that is off in one sheet', (tester) async {
    health.refuse = {HealthFeature.weight};
    await pumpApp(tester, '/me/health');
    await tester.tap(find.text('Allow all'));
    await tester.pumpAndSettle();
    // Steps and distance were already on; the other four go in one request.
    expect(health.requested, [
      HealthFeature.activeEnergy,
      HealthFeature.weight,
      HealthFeature.writeWorkouts,
      HealthFeature.writeMeals,
    ]);
    expect(find.textContaining('Connected 3 of 4 types'), findsOneWidget);
    bool on(String label) => tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, label)).value;
    expect(on('Active energy'), isTrue);
    expect(on('Body weight'), isFalse, reason: 'left unticked in the system sheet');
    expect(on('Workouts'), isTrue);
    // Let the write-back that Allow all started finish before the database closes.
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await unmount(tester);
  });

  testWidgets('Live steps stays off when the permission is refused', (tester) async {
    sensor.allow = false;
    await pumpApp(tester, '/me/health');
    await tester.tap(find.text('Live steps'));
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Live steps')).value, isFalse);
    expect(find.textContaining('Physical activity permission'), findsOneWidget);
    expect(sensor.listens, 0);
    await unmount(tester);
  });

  testWidgets('a tap on Home steps opens the steps trend, not the permission page', (tester) async {
    await pumpApp(tester, '/home');
    await tester.tap(find.textContaining('4,321', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsWidgets);
    expect(find.text('Allow all'), findsNothing, reason: 'Not Me → Health apps');
    expect(find.text('DAY BY DAY'), findsOneWidget);
    expect(find.text('6,161 steps'), findsWidgets, reason: 'The average over the 2 days with data');
    expect(find.textContaining('2 of 30 days'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a trend whose health type is off connects it on the same page', (tester) async {
    await pumpApp(tester, '/trend/activeEnergy');
    expect(find.text('Connect active energy'), findsOneWidget);
    health.energy = {'2026-03-02': 420};
    await tester.tap(find.text('Connect active energy'));
    await tester.pumpAndSettle();
    expect(health.requested, [HealthFeature.activeEnergy]);
    expect(find.text('420 kcal'), findsWidgets);
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await unmount(tester);
  });

  testWidgets('Analytics shows steps a day and distance, with gaps for missing days', (tester) async {
    await pumpApp(tester, '/analytics');
    expect(find.text('6,161'), findsOneWidget, reason: '(8000 + 4321) / 2 days with data');
    expect(find.text('over 2 of 7 days'), findsOneWidget);
    expect(find.text('9.25 km'), findsOneWidget);
    await unmount(tester);
  });
}
