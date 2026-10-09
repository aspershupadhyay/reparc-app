import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/format.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/domain/meal_plan.dart';
import 'package:reparc/domain/targets.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/me/ai_file_screen.dart';
import 'package:reparc/mcp/reparc_tools.dart';
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
    await pumpApp(tester, at: '/workout/plan/new?goal=calisthenics');
    final builder = find.descendant(of: find.byType(RoadmapBuilderScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('YOUR WEEK'), 100, scrollable: builder);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Home, no weights', skipOffstage: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home, no weights'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Follow this plan'));
    await tester.pumpAndSettle();

    expect(find.text('NEXT IN YOUR PLAN'), findsOneWidget);
    await tester.tap(find.text('See the day'));
    await tester.pumpAndSettle();
    // Warm-up is folded to one summary row (D-032).
    expect(find.text('Warm-up'), findsOneWidget);
    expect(find.text(metaLine(['5 moves', 'about 8 min'])), findsOneWidget);
    // Let the "Roadmap saved" message close.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();

    final session = (await db.select(db.workoutSessions).get()).single;
    expect(session.name, 'Skills A');
    expect(session.programId, isNotNull);
    final sets = await db.select(db.setEntries).get();
    final warm = sets.where((s) => s.setType == SetType.warmup).toList();
    // Five warm-up moves, one set each to tick off. Body-weight moves get no ramp-up sets.
    expect(warm, hasLength(5), reason: 'Warm-up moves only');
    expect(warm.every((s) => !s.completed && s.reps == null && s.load == null), isTrue);
    final notes = (await db.select(db.sessionExercises).get()).map((e) => e.note ?? '').toList();
    expect(notes.where((n) => n.startsWith('Warm-up')), hasLength(5));
    expect(notes.where((n) => n.contains('Ramp-up')), isEmpty);
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

  testWidgets('import an AI roadmap only after preview and approval', (tester) async {
    await pumpApp(tester, at: '/me/ai/file');
    final list = find.descendant(of: find.byType(AiFileScreen), matching: find.byType(Scrollable)).first;
    // Jump to the end: a drag from the centre can land on the selectable
    // config text, which keeps the drag for itself.
    final pos = tester.state<ScrollableState>(list).position;
    pos.jumpTo(pos.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Import a plan'), -300, scrollable: list);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import a plan', skipOffstage: false));
    await tester.pumpAndSettle();
    final example = jsonEncode((importFormats['roadmap']! as Map)['example']);
    await tester.enterText(find.widgetWithText(TextField, 'Plan JSON'), '```json\n$example\n```');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Check'));
    await tester.pumpAndSettle();
    expect(find.text('PREVIEW'), findsOneWidget);
    expect(await db.select(db.programs).get(), isEmpty, reason: 'Nothing is saved before approval');
    await tester.ensureVisible(find.text('Approve and save this plan'));
    await tester.tap(find.text('Approve and save this plan'));
    await tester.pumpAndSettle();
    final rows = await db.select(db.programs).get();
    expect(rows.single.active, isFalse, reason: 'Saved, not followed, until the user taps Follow');
    await unmount(tester);
  });

  testWidgets('make my own plan, add a day, follow it, and start a day', (tester) async {
    await pumpApp(tester, at: '/workout');
    await tester.ensureVisible(find.text('Or make my own plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Or make my own plan'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Arms');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Arms'), findsWidgets);
    expect(find.text('Day 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Add day'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add day'));
    await tester.pumpAndSettle();
    expect(find.text('This day is empty'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Day 2'), findsOneWidget);
    await tester.tap(find.text('Follow this plan'));
    await tester.pumpAndSettle();
    final row = (await db.select(db.programs).get()).single;
    expect(row.active, isTrue);
    expect(row.daysPerWeek, 2);
    await unmount(tester);
  });
}
