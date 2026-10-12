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
import 'package:drift/drift.dart' show Value;
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/roadmap.dart';
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
    'roadmap': '/workout/plan/new?goal=aesthetic',
    'live': '/live/',
    'calculator': '/workout/calculator',
    'library': '/workout/library',
    'arms': '/workout/area/arms',
    'triceps': '/workout/muscle/triceps',
    'body': '/me/body',
    'data': '/me/data',
  };
  for (final dark in [false, true]) {
    for (final MapEntry(key: name, value: at) in tabs.entries) {
      testWidgets('$name ${dark ? 'dark' : 'light'}', (tester) async {
        final db = memoryDb();
        var route = at;
        if (name == 'live') route = await tester.runAsync(() => _seedLive(db)) ?? at;
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
            child: ReparcApp(router: buildRouter(initialLocation: route)),
          ),
        );
        // The live screen ticks every second, so it never settles.
        Future<void> settle() =>
            name == 'live' ? tester.pump(const Duration(milliseconds: 500)) : tester.pumpAndSettle();
        await settle();
        // Let the update check's database write land.
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        // Decode pictures (body icons, photos) so they show in the PNG.
        await tester.runAsync(() async {
          for (final e in find.byType(Image).evaluate()) {
            await precacheImage((e.widget as Image).image, e);
          }
        });
        await settle();
        await settle();
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

/// A live plan day with a done warm-up and one done working set.
Future<String> _seedLive(AppDatabase db) async {
  DateTime clock() => DateTime(2026, 3, 4, 17, 40);
  final plan = buildProgram(goal: RoadmapGoal.bodybuilding, level: RoadmapLevel.beginner, setup: GymSetup.fullGym);
  final id = await ProgramRepository(db, clock).adopt(plan);
  final w = WorkoutRepository(db, clock);
  final sid = await w.startProgramDay(programId: id, dayIndex: 0);
  final d = (await w.loadSession(sid))!;
  for (final e in d.exercises.take(5)) {
    await w.setCompleted(e.sets.first.id, true);
  }
  final main = d.exercises[5];
  for (final s in main.sets.take(3)) {
    await w.updateSet(
      s.id,
      SetEntriesCompanion(
        load: const Value(60),
        loadUnit: const Value('kg'),
        reps: const Value(8),
        durationSec: const Value(26),
      ),
    );
    await w.setCompleted(s.id, true);
  }
  return '/live/$sid';
}
