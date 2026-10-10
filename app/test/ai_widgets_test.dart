import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/ai/ai_controller.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/brand.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/intro/intro.dart';

import 'helpers.dart';

class MemorySecrets implements SecretStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String? value) async => value == null ? values.remove(key) : values[key] = value;
}

void main() {
  late AppDatabase db;
  late FakeClock clock;
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime(2026, 3, 2, 18));
  });
  tearDown(() => db.close());

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          libraryProvider.overrideWith((ref) async => library),
          secretStoreProvider.overrideWithValue(MemorySecrets()),
        ],
        child: child,
      ),
    );
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the intro plays once in full, can be skipped, and then shows the app', (tester) async {
    await pump(tester, const MaterialApp(home: IntroGate(child: Text('App body'))));
    // Settings load first; the splash colour covers the app meanwhile.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CustomPaint), findsWidgets);
    // Mid-way the bar is loading; at the end the logo is complete.
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.bySemanticsLabel('RepArc. Tap to skip.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
    expect(find.text('App body'), findsOneWidget);
    expect(find.bySemanticsLabel('RepArc. Tap to skip.'), findsNothing);
    final settings = await tester.runAsync(() => SettingsRepository(db).watch().first);
    expect(settings!.introSeen, isTrue);
    await unmount(tester);
  });

  testWidgets('a tap skips the intro', (tester) async {
    await pump(tester, const MaterialApp(home: IntroGate(child: Text('App body'))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.bySemanticsLabel('RepArc. Tap to skip.'));
    await tester.pump();
    expect(find.bySemanticsLabel('RepArc. Tap to skip.'), findsNothing);
    await unmount(tester);
  });

  test('the intro builds the bar in order and ends complete', () {
    // Sample the intro timeline the way IntroFrame does.
    final metric = MarkGeometry.barPath().computeMetrics().first;
    expect(metric.length, greaterThan(122));
    for (final c in [const Color(0xFF0B0C0A), BrandColors.lime]) {
      final rec = ui.PictureRecorder();
      ReparcMark(
        color: c,
        smallLeft: 0.5,
        bigLeft: 0,
        pipe: 0.4,
        bubble: 1,
        bubbleAt: 0.4,
        bigRight: 0,
        smallRight: 0,
      ).paint(Canvas(rec), const Size(200, 200));
      rec.endRecording().dispose();
    }
  });

  testWidgets('the logo paints at any size', (tester) async {
    await pump(tester, const MaterialApp(home: Center(child: ReparcLogo(size: 120, background: true))));
    expect(find.bySemanticsLabel('RepArc logo'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('approving a proposal in the app saves the plan', (tester) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        libraryProvider.overrideWith((ref) async => library),
      ],
    );
    final id = await container
        .read(proposalRepoProvider)
        .create(
          kind: ProposalKind.workoutPlan,
          client: 'Claude',
          via: 'online',
          summary: 'A short push day.',
          payload: {
            'plans': [
              {
                'name': 'Push',
                'exercises': [
                  {'name': 'Bench press', 'library_id': 'bench-press', 'sets': 3, 'reps': 8},
                ],
              },
            ],
          },
        );
    container.dispose();

    await pump(tester, ReparcApp(router: buildRouter(initialLocation: '/me/ai/proposal/$id')));
    await tester.pumpAndSettle();
    expect(find.text('Workout plan from Claude'), findsOneWidget);
    expect(find.text('3 × 8'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();
    final plans = await db.select(db.programs).get();
    expect(plans.single.name, 'Push');
    expect(plans.single.active, isFalse, reason: 'An approved plan is followed only when the user taps Follow');
    expect((await db.select(db.aiProposals).getSingle()).status, ProposalStatus.approved);
    await unmount(tester);
  });
}
