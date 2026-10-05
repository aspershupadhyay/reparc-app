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
import 'package:reparc/features/me/me_screen.dart';
import 'package:reparc/features/workout/session_detail_screen.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

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
    expect(find.text('Free workout'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Meal, tab 3 of 5'));
    await tester.pumpAndSettle();
    expect(find.text('Eaten'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Analytics, tab 4 of 5'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Best lifts'),
      300,
      scrollable: _scrollableIn(find.byType(AnalyticsScreen)),
    );
    expect(find.text('Best lifts'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Me, tab 5 of 5'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('None. Nothing is shared.'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    await unmount(tester);
  });

  testWidgets('log a workout set from start to saved history', (tester) async {
    await pumpApp(tester, at: '/workout');

    await tester.tap(find.widgetWithText(FilledButton, 'Start'));
    await tester.pumpAndSettle();
    expect(find.text('Elapsed'), findsOneWidget);
    expect(await db.select(db.workoutSessions).get(), hasLength(1));

    // Create an exercise without leaving the workout.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create your own'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Squat');
    await tester.tap(find.widgetWithText(FilledButton, 'Save exercise'));
    await tester.pumpAndSettle();
    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Add set'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '100');
    await tester.enterText(fields.at(1), '5');
    await tester.pumpAndSettle();

    final set = (await db.select(db.setEntries).get()).single;
    expect(set.load, 100);
    expect(set.loadUnit, 'kg');
    expect(set.reps, 5);
    expect(set.completed, isFalse);

    await tester.tap(find.bySemanticsLabel('Set 1 complete'));
    await tester.pumpAndSettle();
    expect((await db.select(db.setEntries).get()).single.completed, isTrue);
    expect(find.text('1 / 1'), findsOneWidget);

    // Leaving the screen keeps the session live.
    await tester.tap(find.byTooltip('Leave screen. The workout keeps running.'));
    await tester.pumpAndSettle();
    expect(find.text('Training now'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, 'Open'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Finish workout'));
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

  testWidgets('log a meal; missing values stay missing', (tester) async {
    await pumpApp(tester, at: '/meal');
    await tester.tap(find.text('Add food'));
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
      find.text('Account and sync'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    expect(find.text('Off. Records stay on this phone.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('None. Nothing is shared.'),
      300,
      scrollable: _scrollableIn(find.byType(MeScreen)),
    );
    await tester.drag(_scrollableIn(find.byType(MeScreen)), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None. Nothing is shared.'));
    await tester.pumpAndSettle();
    expect(find.text('No AI connections'), findsOneWidget);
    await unmount(tester);
  });
}

/// Removes the app inside the test zone so stream queries and timers end.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

Finder _scrollableIn(Finder screen) => find.descendant(of: screen, matching: find.byType(Scrollable)).first;
