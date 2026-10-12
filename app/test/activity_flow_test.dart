import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/activity/location_source.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/domain/track.dart';
import 'package:reparc/features/exercises/library/library.dart';

import 'fake_location.dart';
import 'helpers.dart';

const _mPerDeg = 6371008.8 * pi / 180;

void main() {
  late AppDatabase db;
  late FakeLocation gps;
  late FakeClock clock;
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  setUp(() {
    db = memoryDb();
    gps = FakeLocation();
    clock = FakeClock(DateTime(2026, 3, 2, 6, 30));
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 4000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      final s = SettingsRepository(db);
      await s.setOnboarded();
      await s.setIntroSeen();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          libraryProvider.overrideWith((ref) async => library),
          locationSourceProvider.overrideWithValue(gps),
        ],
        child: ReparcApp(router: buildRouter(initialLocation: '/workout')),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('record a run: live numbers, pause, finish, and history', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Record a run with GPS'));
    await tester.pumpAndSettle();
    expect(find.text('Morning run'), findsOneWidget, reason: 'The recording screen is open');
    expect(gps.on, isTrue);

    // 1 km at 4 m/s: a 4:10 /km pace.
    final t0 = clock.now.toUtc();
    for (var s = 0; s <= 250; s++) {
      gps.add(
        TrackPoint(
          at: t0.add(Duration(seconds: s)),
          lat: 12.97 + s * 4 / _mPerDeg,
          lon: 77.59,
          accuracy: 4,
        ),
      );
    }
    clock.advance(const Duration(seconds: 250));
    await tester.pump(const Duration(seconds: 4));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text('AVG PACE'), findsOneWidget);
    expect(find.text('4:10'), findsNWidgets(2), reason: 'Pace now and average pace');
    expect(find.text('Good GPS'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(gps.on, isFalse);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Finish and save'));
    await tester.pumpAndSettle();
    expect(find.text('Splits'), findsNothing, reason: 'One kilometre has no split list');
    expect(find.textContaining('1.00', findRichText: true), findsOneWidget);
    expect(find.textContaining('4:10', findRichText: true), findsNWidgets(3), reason: 'Avg pace, moving time, elapsed');
    expect(find.textContaining('stays on this phone'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Morning run'), findsOneWidget);
    expect(find.textContaining(RegExp(r'1\.00\skm')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a refused location permission starts nothing and says why', (tester) async {
    gps.access = LocationAccess.denied;
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Record a ride with GPS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('needs location'), findsOneWidget);
    expect(gps.starts, 0);
    await unmount(tester);
  });
}
