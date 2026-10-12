import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reparc/core/palette.dart';
import 'package:reparc/core/theme.dart';
import 'package:reparc/features/exercises/catalog/model.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/exercises/library/move_browser.dart';
import 'package:reparc/features/exercises/library_screen.dart';
import 'package:reparc/features/exercises/muscle_map.dart';
import 'package:reparc/features/exercises/rig/anatomy.dart';

void main() {
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  test('every body area and every muscle has its icon on disk', () {
    for (final a in BodyArea.values) {
      expect(File(bodyIconAsset(area: a)).existsSync(), isTrue, reason: a.name);
    }
    for (final m in Muscle.values) {
      expect(File(bodyIconAsset(muscle: m)).existsSync(), isTrue, reason: m.name);
    }
  });

  test('Gym and Home split moves by the kit they need', () {
    Move named(String id) => library.byCatalogId[id]!;
    final pushUp = named('push-up');
    expect(Place.home.fits(pushUp), isTrue);
    expect(Place.gym.fits(pushUp), isFalse);
    final bench = named('bench-press');
    expect(Place.gym.fits(bench), isTrue);
    expect(Place.home.fits(bench), isFalse);
    // Dumbbells work in both places.
    final dbPress = named('lib:Dumbbell_Bench_Press');
    expect(Place.gym.fits(dbPress), isTrue);
    expect(Place.home.fits(dbPress), isTrue);
    // Every muscle has something to do at home and in a gym.
    for (final muscles in areaMuscles.values) {
      for (final m in muscles) {
        final moves = library.moves.where((x) => x.target == m);
        expect(moves.any(Place.home.fits), isTrue, reason: 'home: ${m.label}');
        expect(moves.any(Place.gym.fits), isTrue, reason: 'gym: ${m.label}');
      }
    }
  });

  Future<void> pumpAt(WidgetTester tester, String location) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/workout/area/:area',
          builder: (_, s) => AreaScreen(area: BodyArea.values.byName(s.pathParameters['area']!)),
        ),
        GoRoute(
          path: '/workout/muscle/:muscle',
          builder: (_, s) => MuscleScreen(muscle: Muscle.values.byName(s.pathParameters['muscle']!)),
        ),
        GoRoute(path: '/workout/move/:id', builder: (_, s) => Text('move ${s.pathParameters['id']}')),
        GoRoute(path: '/workout/guide/:id', builder: (_, s) => Text('guide ${s.pathParameters['id']}')),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [libraryProvider.overrideWith((ref) async => library)],
        child: MaterialApp.router(theme: buildTheme(Palette.light), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Arms shows Biceps, Triceps, and Forearms, and a card opens that muscle', (tester) async {
    await pumpAt(tester, '/workout/area/arms');
    expect(find.text('Biceps'), findsOneWidget);
    expect(find.text('Triceps'), findsOneWidget);
    expect(find.text('Forearms'), findsOneWidget);

    await tester.tap(find.text('Triceps'));
    await tester.pumpAndSettle();
    expect(find.byType(MuscleScreen), findsOneWidget);
    expect(find.text('START HERE'), findsOneWidget);
    final tiles = tester.widgetList<MoveTile>(find.byType(MoveTile)).toList();
    expect(tiles.first.m.name, library.essentialsFor(Muscle.triceps).first.name);
    expect(tiles.every((t) => t.m.target == Muscle.triceps), isTrue);
  });

  testWidgets('Home on a muscle page leaves only moves that work at home', (tester) async {
    await pumpAt(tester, '/workout/muscle/chest');
    final all = library.moves.where((m) => m.target == Muscle.chest).length;
    expect(find.text('$all exercises'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    final home = library.moves.where((m) => m.target == Muscle.chest && Place.home.fits(m)).length;
    expect(home, lessThan(all));
    expect(find.text('$home exercises'), findsOneWidget);
    final tiles = tester.widgetList<MoveTile>(find.byType(MoveTile));
    expect(tiles, isNotEmpty);
    expect(tiles.every((t) => Place.home.fits(t.m)), isTrue);
  });

  testWidgets('long groups show a few moves and open on "Show more"', (tester) async {
    await pumpAt(tester, '/workout/muscle/abs');
    final more = find.textContaining(RegExp(r'^Show \d+ more$'));
    // The list builds lazily: scroll down to the first long group.
    await tester.scrollUntilVisible(more, 300, scrollable: find.byType(Scrollable).first);
    expect(more, findsWidgets);
    final label = tester.widget<Text>(more.first).data!;
    final hidden = int.parse(label.split(' ')[1]);
    expect(hidden, greaterThan(0));
    await tester.ensureVisible(more.first);
    await tester.tap(more.first);
    await tester.pumpAndSettle();
    expect(find.text(label), findsNothing);
  });
}
