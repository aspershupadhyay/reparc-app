// Renders the main tabs to PNG with the real fonts and icons, for a visual
// check of colour, layout, and text wrapping. Run from app/:
//
//   flutter test tool/screens/render_screens_test.dart --update-goldens
//
// Output: tool/screens/out/<tab>-<light|dark>.png at 1170 x 2532.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/updates/update_controller.dart';

import '../../test/helpers.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

void main() {
  final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());
  final pub = '${Platform.environment['PUB_CACHE'] ?? '${Platform.environment['HOME']}/.pub-cache'}/hosted/pub.dev';
  final lucide = Directory(pub).listSync().firstWhere((d) => d.path.contains('lucide_icons_flutter-')).path;

  setUpAll(() async {
    await _font('Inter', 'assets/fonts/Inter-Variable.ttf');
    await _font('packages/lucide_icons_flutter/Lucide', '$lucide/assets/lucide.ttf');
    // Material icons, so any stray Material glyph shows up as itself.
    final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    await _font('MaterialIcons', '$sdk/artifacts/material_fonts/MaterialIcons-Regular.otf');
  });

  const tabs = {
    'home': '/home',
    'workout': '/workout',
    'meal': '/meal',
    'analytics': '/analytics',
    'me': '/me',
    'updates': '/me/updates',
    'roadmap': '/workout/roadmap/new?goal=aesthetic',
    'calculator': '/workout/calculator',
    'library': '/workout/library',
    'body': '/me/body',
    'data': '/me/data',
  };
  for (final dark in [false, true]) {
    for (final MapEntry(key: name, value: at) in tabs.entries) {
      testWidgets('$name ${dark ? 'dark' : 'light'}', (tester) async {
        final db = memoryDb();
        tester.view.physicalSize = const Size(1170, 2532);
        tester.view.devicePixelRatio = 3;
        tester.platformDispatcher.platformBrightnessTestValue = dark ? Brightness.dark : Brightness.light;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              clockProvider.overrideWithValue(() => DateTime(2026, 3, 4, 18)),
              libraryProvider.overrideWith((ref) async => library),
              installedVersionProvider.overrideWith((ref) async => '0.3.2'),
              // A newer release, so Home and App updates show the notice.
              fetchJsonProvider.overrideWithValue(
                (url) async => {
                  'tag_name': 'v0.4.0',
                  'html_url': 'https://github.com/aspershupadhyay/reparc/releases/tag/v0.4.0',
                  'published_at': '2026-03-04T10:00:00Z',
                  'body': 'Reparc v0.4.0 (beta). Sample notes.',
                  'assets': <Object>[],
                },
              ),
            ],
            child: ReparcApp(router: buildRouter(initialLocation: at)),
          ),
        );
        await tester.pumpAndSettle();
        // Let the update check's database write land.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ReparcApp),
          matchesGoldenFile('out/$name-${dark ? 'dark' : 'light'}.png'),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        await tester.runAsync(db.close);
      });
    }
  }
}
