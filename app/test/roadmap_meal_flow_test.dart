import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/domain/meal_plan.dart';
import 'package:reparc/domain/targets.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/workout/roadmap_screens.dart';

import 'app_flow_test.dart' show unmount;
import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());
  final foods = FoodLibrary.parse(File('assets/foods/foods.json').readAsStringSync());

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime(2026, 3, 2, 9));
  });
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {String at = '/home'}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          libraryProvider.overrideWith((ref) async => library),
          foodLibraryProvider.overrideWith((ref) async => foods),
        ],
        child: ReparcApp(router: buildRouter(initialLocation: at)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('choose a roadmap, open today, and start it with warm-up sets', (tester) async {
    await pumpApp(tester, at: '/workout');
    expect(find.text('What do you want to work towards?'), findsOneWidget);
    for (final g in ['Aesthetic', 'Bodybuilding', 'Strength', 'Calisthenics', 'Lean & fit']) {
      expect(find.text(g, skipOffstage: false), findsOneWidget);
    }
    await unmount(tester);
    await pumpApp(tester, at: '/workout/roadmap/new?goal=calisthenics');
    final builder = find.descendant(of: find.byType(RoadmapBuilderScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Your week'), 100, scrollable: builder);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Home, no weights', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home, no weights'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Use this roadmap'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Next: Skills A'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Warm up and start'));
    await tester.pumpAndSettle();
    expect(find.text('1. Warm-up (about 8 min)'), findsOneWidget);
    // Let the "Roadmap saved" message close.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();

    final session = (await db.select(db.workoutSessions).get()).single;
    expect(session.name, 'Skills A');
    expect(session.programId, isNotNull);
    final sets = await db.select(db.setEntries).get();
    expect(sets.where((s) => s.setType == SetType.warmup), hasLength(2), reason: 'Beginner ramp-up: 2 sets');
    await unmount(tester);
  });

  testWidgets('plan a vegan day, add it as planned, and see targets in Meal', (tester) async {
    await db.into(db.settings).insert(SettingsCompanion.insert(key: 'targetsOn', value: 'true'));
    for (final e in const Profile(
      sex: Sex.female,
      ageYears: 30,
      heightCm: 165,
      weightKg: 60,
      activity: Activity.moderate,
      goal: BodyGoal.gain,
      diet: Diet.vegan,
    ).toMap().entries) {
      if (e.value != null) {
        await db.into(db.settings).insert(SettingsCompanion.insert(key: 'profile.${e.key}', value: e.value!));
      }
    }
    await pumpApp(tester, at: '/meal');
    expect(find.text('Protein'), findsWidgets);
    expect(find.text('Fibre'), findsWidgets);
    // 60 kg × (1.8 + 0.2 for vegan) = 120 g.
    expect(find.textContaining('/ 120 g'), findsOneWidget);

    await tester.tap(find.text('Plan my day'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sized for your targets'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Add to this day as planned'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Add to this day as planned'));
    await tester.pumpAndSettle();

    final entries = await db.select(db.mealEntries).get();
    expect(entries, isNotEmpty);
    expect(entries.every((e) => e.status == MealStatus.planned), isTrue, reason: 'Plans are never logged as eaten');
    expect(entries.every((e) => e.source.startsWith('USDA FoodData Central')), isTrue);
    final animal = {
      for (final f in foods.foods)
        if (f.diet != 'plant') f.name,
    };
    expect(entries.where((e) => animal.contains(e.name)), isEmpty, reason: 'Vegan plan has no animal foods');
    await unmount(tester);
  });

  testWidgets('Analytics has separate Workout and Meal tabs', (tester) async {
    await pumpApp(tester, at: '/analytics');
    expect(find.text('Sets per muscle'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Meal'));
    await tester.pumpAndSettle();
    expect(find.text('Daily average'), findsOneWidget);
    expect(find.text('Sets per muscle'), findsNothing);
    await unmount(tester);
  });
}
