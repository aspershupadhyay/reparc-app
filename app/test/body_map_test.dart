import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/palette.dart';
import 'package:reparc/core/theme.dart';
import 'package:reparc/features/exercises/body3d/body_map_3d.dart';
import 'package:reparc/features/exercises/body3d/body_model.dart';
import 'package:reparc/features/exercises/body3d/body_render.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/exercises/muscle_map.dart';
import 'package:reparc/features/exercises/rig/anatomy.dart';

BodyFrame _draw(double yaw, Size size, {double zoom = 1}) {
  final rec = ui.PictureRecorder();
  final f = paintBody(
    Canvas(rec),
    size,
    BodyMesh.instance,
    yaw: yaw,
    pitch: 5,
    paint: const BodyPaint(skin: Color(0xFF58636B), muscle: {}, rim: Color(0xFF2AA7B8)),
    zoom: zoom,
  );
  rec.endRecording().dispose();
  return f;
}

void main() {
  test('the body mesh covers every muscle in the browse tree and fits 16-bit indices', () {
    final mesh = BodyMesh.instance;
    final tree = areaMuscles.values.expand((m) => m).toSet();
    expect(mapMuscles.toSet(), tree);
    expect(mesh.vertexCount, lessThan(65536));
    final drawn = {
      for (final m in mesh.triangleMuscle)
        if (m >= 0) mapMuscles[m],
    };
    expect(drawn, tree, reason: 'every muscle has visible triangles');
  });

  test('a tap on each muscle, front or back, picks that muscle', () {
    const size = Size(390, 400);
    final front = _draw(0, size), back = _draw(180, size);
    final views = [front, back, _draw(90, size), _draw(-90, size)];
    for (final m in mapMuscles) {
      final f = views.firstWhere((v) => v.anchorsOnScreen[m] != null);
      final at = f.anchorsOnScreen[m]!.first;
      expect(f.hit(at), m, reason: '${m.label} at $at');
    }
    // Empty space beside the body picks nothing.
    expect(front.hit(const Offset(8, 8)), isNull);
  });

  testWidgets('tap a muscle to select it, then open its exercises', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [libraryProvider.overrideWith((ref) async => library)],
        child: MaterialApp(
          theme: buildTheme(Palette.dark),
          home: const Scaffold(body: Center(child: BodyMap3D())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drag to turn · Tap a muscle'), findsOneWidget);

    // Turn to the front, then tap the middle of the chest.
    await tester.tap(find.text('Front'));
    await tester.pumpAndSettle();
    final box = tester.getRect(find.byType(BodyMap3D));
    final frame = _draw(0, Size(box.width, box.height - bodyMapInsets.vertical), zoom: bodyMapZoom);
    final chest = frame.anchorsOnScreen[Muscle.chest]!.first;
    await tester.tapAt(box.topLeft + bodyMapInsets.topLeft + chest);
    await tester.pumpAndSettle();
    expect(find.text('Mid chest'), findsOneWidget);
    final count = library.moves.where((m) => m.target == Muscle.chest && m.kind == MoveKind.strength).length;
    expect(find.text('$count exercises'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear selection'));
    await tester.pumpAndSettle();
    expect(find.text('Mid chest'), findsNothing);
  });
}
