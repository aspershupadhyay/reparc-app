import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/features/analytics/analytics_screen.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/me/ai_connections_screen.dart';
import 'package:reparc/features/me/me_screen.dart';
import 'package:reparc/features/workout/live_session_screen.dart';
import 'package:reparc/features/workout/session_detail_screen.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;
  // Asset loading is real I/O, which never settles under fake async.
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  setUp(() {
    db = memoryDb();
    clock = FakeClock(DateTime(2026, 3, 2, 18));
  });
  // Close outside the fake-async test zone.
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester, {String at = '/home'}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          libraryProvider.overrideWith((ref) async => library),
        ],
        child: ReparcApp(router: buildRouter(initialLocation: at)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('five labelled tabs in the accepted order, each reachable', (tester) async {
    await pumpApp(tester);
    final labels = ['Home', 'Workout', 'Meal', 'Analytics', 'Me'];
    for (final (i, l) in labels.indexed) {
      expect(find.bySemanticsLabel('$l, tab ${i + 1} of 5'), findsOneWidget);
    }
    await tester.tap(find.bySemanticsLabel('Workout, tab 2 of 5'));
    await tester.pumpAndSettle();
    expect(find.text('FREE WORKOUT'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Meal, tab 3 of 5'));
    await tester.pumpAndSettle();
    expect(find.text('Eaten'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Analytics, tab 4 of 5'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Your progress shows here'),
      300,
      scrollable: _scrollableIn(find.byType(AnalyticsScreen)),
    );
    expect(find.text('Your progress shows here'), findsOneWidget, reason: 'No zeros before the first workout');
    expect(find.text('Best lifts'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Me, tab 5 of 5'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Off. Nothing is shared.'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    await unmount(tester);
  });

  testWidgets('a new user answers three questions and gets a plan and a first workout', (tester) async {
    await pumpApp(tester);
    expect(find.text('Get your plan'), findsOneWidget);
    await tester.tap(find.text('Get your plan'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Strength'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beginner'));
    await tester.pumpAndSettle();
    expect(find.text('Suggested for you'), findsOneWidget);
    await tester.tap(find.text('Make my plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your plan is ready'), findsOneWidget);
    expect(find.text('YOUR FIRST WORKOUT'), findsOneWidget);
    final programs = await db.select(db.programs).get();
    expect(programs.single.active, isTrue);
    expect(programs.single.goal, 'strength');
    expect(programs.single.level, 'beginner');
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Get your plan'), findsNothing, reason: 'Home now shows the plan');
    expect(find.text('NEXT IN YOUR PLAN'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the first-run setup can be skipped and does not come back', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Get your plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.text('Get your plan'), findsNothing);
    expect(await db.select(db.programs).get(), isEmpty);
    await unmount(tester);
  });

  testWidgets('log a workout set from start to saved history', (tester) async {
    await pumpApp(tester, at: '/workout');

    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();
    expect(find.text('Add an exercise to start'), findsOneWidget);
    expect(await db.select(db.workoutSessions).get(), hasLength(1));

    // Create an exercise without leaving the workout.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create your own'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Squat');
    await tester.tap(find.widgetWithText(FilledButton, 'Save exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Squat'), findsWidgets, reason: 'On its card and as the next step');

    // A new exercise starts with three empty sets: weight and reps each.
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(6));
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '5');
    await tester.pumpAndSettle();

    final sets = await (db.select(db.setEntries)..orderBy([(s) => OrderingTerm.asc(s.position)])).get();
    expect(sets, hasLength(3));
    final set = sets.first;
    expect(set.load, 100);
    expect(set.loadUnit, 'kg');
    expect(set.reps, 5);
    expect(set.completed, isFalse);

    await tester.tap(find.bySemanticsLabel('Set 1 complete'));
    await tester.pumpAndSettle();
    expect((await db.select(db.setEntries).get()).where((s) => s.completed), hasLength(1));
    expect(find.bySemanticsLabel(RegExp('^Rest left')), findsOneWidget, reason: 'The ring clock times the rest');

    // Leaving the screen keeps the session live.
    await tester.tap(find.byTooltip('Leave screen. The workout keeps running.'));
    await tester.pumpAndSettle();
    expect(find.text('TRAINING NOW'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue workout'));
    await tester.pumpAndSettle();

    // The sets scroll under the pinned clock panel.
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Finish workout'),
      300,
      scrollable: find
          .descendant(
            of: find.descendant(of: find.byType(LiveSessionScreen), matching: find.byType(CustomScrollView)),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Finish workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finish and save'));
    await tester.pumpAndSettle();

    final session = (await db.select(db.workoutSessions).get()).single;
    expect(session.status, SessionStatus.finished);
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a set that becomes done keeps a weight typed on screen', (tester) async {
    await pumpApp(tester, at: '/workout');
    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create your own'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Squat');
    await tester.tap(find.widgetWithText(FilledButton, 'Save exercise'));
    await tester.pumpAndSettle();

    // A value on screen that did not reach the database, as when text
    // comes in without a key press (launch review, 2026-10-10).
    final load = tester.widget<TextField>(find.byType(TextField).at(0)).controller!;
    load.text = '30';
    var first = (await (db.select(db.setEntries)..orderBy([(s) => OrderingTerm.asc(s.position)])).get()).first;
    expect(first.load, isNull);

    // Another change to the set rebuilds the row; the text stays.
    await (db.update(db.setEntries)..where((s) => s.id.equals(first.id))).write(
      const SetEntriesCompanion(note: Value('felt easy')),
    );
    await tester.pumpAndSettle();
    expect(load.text, '30');

    // The set ends (as the guide's set time running out does).
    await (db.update(db.setEntries)..where((s) => s.id.equals(first.id))).write(
      const SetEntriesCompanion(completed: Value(true)),
    );
    await tester.pumpAndSettle();
    first = (await (db.select(db.setEntries)..where((s) => s.id.equals(first.id))).getSingle());
    expect(first.load, 30);
    expect(first.loadUnit, 'kg');
    expect(first.reps, isNull, reason: 'Nothing is invented for an empty field');
    await unmount(tester);
  });

  testWidgets('browse the library, open a library exercise, and log it', (tester) async {
    // Reduced motion keeps the photo loop still so the test can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, at: '/workout');

    await tester.tap(find.text('Exercises'));
    await tester.pumpAndSettle();
    expect(find.text('TAP A MUSCLE'), findsOneWidget);
    expect(find.text('OR PICK A BODY PART'), findsOneWidget);

    // Arms splits into biceps, triceps, and forearms, with picks to start.
    final arms = find.bySemanticsLabel(RegExp('^Arms: Biceps, Triceps, Forearms'));
    await tester.ensureVisible(arms);
    await tester.pumpAndSettle();
    await tester.tap(arms);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Biceps'), findsOneWidget);
    expect(find.bySemanticsLabel('Triceps'), findsOneWidget);
    expect(find.bySemanticsLabel('Forearms'), findsOneWidget);
    expect(find.text('START HERE'), findsOneWidget);
    expect(find.textContaining('Barbell curl'), findsWidgets);
    await tester.tap(find.bySemanticsLabel('Triceps'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Triceps pushdown'), findsWidgets);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    final search = find.textContaining('Search ${library.moves.length} exercises');
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    await tester.tap(search);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'air bike');
    await tester.pumpAndSettle();
    expect(find.text('1 exercise'), findsOneWidget);
    await tester.tap(find.text('Air bike'));
    await tester.pumpAndSettle();
    expect(find.text('End'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('HOW TO DO IT'), 300, scrollable: find.byType(Scrollable).last);
    expect(find.text('HOW TO DO IT'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Start workout with this'));
    await tester.pumpAndSettle();
    final ex = (await db.select(db.exercises).get()).single;
    expect(ex.catalogId, 'lib:Air_Bike');
    // Library names are shown and saved in sentence case (D-032).
    expect(ex.name, 'Air bike');
    await unmount(tester);
  });

  testWidgets('guide link in a live workout opens the guide above it', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(tester, at: '/workout');

    await tester.tap(find.widgetWithText(FilledButton, 'Start workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'back squat');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back squat'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Set 1 complete'), findsOneWidget);

    await tester.tap(find.byTooltip('How to do Back squat'));
    await tester.pumpAndSettle();
    expect(find.textContaining('king of leg strength'), findsOneWidget);
    // The move is already in the workout, so the guide offers no add button.
    expect(find.text('Add to workout'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Start workout'), findsOneWidget, reason: 'Back on the live workout');
    await unmount(tester);
  });

  testWidgets('log a meal; missing values stay missing', (tester) async {
    await pumpApp(tester, at: '/meal');
    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    // Search comes first; the manual form opens on request.
    await tester.tap(find.text('Can\'t find it? Enter it yourself'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Food name'), 'Oats');
    await tester.enterText(find.widgetWithText(TextField, 'Serving size'), '40');
    await tester.enterText(find.widgetWithText(TextField, 'Energy'), '150');
    await tester.enterText(find.widgetWithText(TextField, 'Amount'), '2');
    await tester.pumpAndSettle();
    expect(find.textContaining('For this amount: 300 kcal'), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    final e = (await db.select(db.mealEntries).get()).single;
    expect(e.status, MealStatus.eaten);
    expect(e.energyKcal, 150);
    expect(e.amount, 2);
    expect(e.amountUnit, 'serving');
    expect(e.proteinG, isNull);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.text('300 kcal'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('Me shows honest connection states', (tester) async {
    await pumpApp(tester, at: '/me');
    await tester.scrollUntilVisible(
      find.text('Backup and restore'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    expect(find.text('Apple Health, Health Connect. Off.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Off. Nothing is shared.'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    await tester.drag(_scrollableIn(find.byType(MeScreen)), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off. Nothing is shared.'));
    await tester.pumpAndSettle();
    // Every data category starts off, and both ways in are off.
    final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(switches, hasLength(4));
    expect(switches.every((s) => !s.value), isTrue);
    await tester.scrollUntilVisible(
      find.text('Set up my gateway'),
      300,
      scrollable: _scrollableIn(find.byType(AiConnectionsScreen)),
    );
    expect(find.text('Turn on'), findsOneWidget);
    await unmount(tester);
  });
}

/// Removes the app inside the test zone so stream queries and timers end.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

Finder _scrollableIn(Finder screen) => find.descendant(of: screen, matching: find.byType(Scrollable)).first;
