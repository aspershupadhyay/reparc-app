import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/palette.dart';
import 'package:reparc/core/theme.dart';
import 'package:reparc/features/exercises/catalog/model.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/exercises/library/move_browser.dart';
import 'package:reparc/features/exercises/rig/anatomy.dart';

void main() {
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  testWidgets('body part, then muscle, then that muscle\'s moves with picks first', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [libraryProvider.overrideWith((ref) async => library)],
        child: MaterialApp(
          theme: buildTheme(Palette.dark),
          home: Scaffold(
            body: MoveBrowser(initialArea: BodyArea.arms, onTap: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Second step: the muscles of the chosen body part.
    expect(find.widgetWithText(ChoiceChip, 'All arms'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Biceps'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Triceps'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Forearms'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Triceps'));
    await tester.pumpAndSettle();

    final triceps = library.moves.where((m) => m.target == Muscle.triceps).length;
    expect(find.text('$triceps exercises'), findsOneWidget);
    // The hand-picked moves lead the list.
    final firstPick = library.essentialsFor(Muscle.triceps).first.name;
    final tiles = tester.widgetList<MoveTile>(find.byType(MoveTile)).toList();
    expect(tiles.first.m.name, firstPick);
    expect(tiles.every((t) => t.m.target == Muscle.triceps), isTrue);
  });
}
