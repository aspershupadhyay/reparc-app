// Renders the body map to PNG from several angles, in both themes, with
// nothing and with a muscle selected, for a visual check on the real
// renderer. Run from app/:
//
//   flutter test tool/body/render_body_test.dart --update-goldens
//
// Output: tool/body/out/<theme>-<view>.png at 1170 x 1500.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/palette.dart';
import 'package:reparc/core/theme.dart';
import 'package:reparc/features/exercises/body3d/body_map_3d.dart';
import 'package:reparc/features/exercises/body3d/body_model.dart';
import 'package:reparc/features/exercises/library/library.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

void main() {
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());
  final mesh = BodyMesh.parse(ByteData.sublistView(File('assets/body/body.bin').readAsBytesSync()));
  final pub = '${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}/hosted/pub.dev';
  final lucide = Directory(pub).listSync().firstWhere((d) => d.path.contains('lucide_icons_flutter-')).path;

  setUpAll(() async {
    await _font('Inter', 'assets/fonts/Inter-Variable.ttf');
    await _font('packages/lucide_icons_flutter/Lucide', '$lucide/assets/lucide.ttf');
  });

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    testWidgets('body map $theme', (tester) async {
      tester.view.physicalSize = const Size(1170, 1500);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryProvider.overrideWith((ref) async => library),
            bodyMeshProvider.overrideWith((ref) async => mesh),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(dark ? Palette.dark : Palette.light),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: BodyMap3D(height: 440)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final map = find.byType(BodyMap3D);
      Future<void> shot(String view) => expectLater(map, matchesGoldenFile('out/$theme-$view.png'));

      await shot('start');
      for (final v in ['Front', 'Side', 'Back']) {
        await tester.tap(find.text(v).first);
        await tester.pumpAndSettle();
        await shot(v.toLowerCase());
      }
      // A three-quarter back view, then a muscle selected.
      await tester.drag(map, const Offset(-60, 0));
      await tester.pumpAndSettle();
      await shot('back-three-quarter');
      await tester.tap(find.text('Front').first);
      await tester.pumpAndSettle();
      final box = tester.getRect(map);
      await tester.tapAt(box.center + const Offset(-22, -88));
      await tester.pumpAndSettle();
      await shot('front-selected');
    });
  }
}
