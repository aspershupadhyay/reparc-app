import 'dart:io';
import 'dart:typed_data';
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

final _mesh = BodyMesh.parse(ByteData.sublistView(File('assets/body/body.bin').readAsBytesSync()));

BodyFrame _draw(double yaw, Size size, {double zoom = 1}) {
  final rec = ui.PictureRecorder();
  final f = paintBody(
    Canvas(rec),
    size,
    _mesh,
    yaw: yaw,
    pitch: 5,
    paint: const BodyPaint(skin: Color(0xFF58636B), muscle: {}, rim: Color(0xFF2AA7B8)),
    zoom: zoom,
  );
  rec.endRecording().dispose();
  return f;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the app bundle has the body mesh', () async {
    final mesh = await BodyMesh.load();
    expect(mesh.vertexCount, _mesh.vertexCount);
    expect(mesh.triangleCount, _mesh.triangleCount);
  });

  test('the body mesh is closed, unit-normal, and faces outward', () {
    final mesh = _mesh;
    // Every edge is shared by exactly two triangles, in opposite
    // directions: no holes, and one winding throughout.
    final edges = <int, int>{};
    final idx = mesh.indices;
    for (var t = 0; t < mesh.triangleCount; t++) {
      for (var k = 0; k < 3; k++) {
        final a = idx[t * 3 + k], b = idx[t * 3 + (k + 1) % 3];
        edges[a * 65536 + b] = (edges[a * 65536 + b] ?? 0) + 1;
      }
    }
    for (final e in edges.keys) {
      expect(edges[e], 1, reason: 'edge used twice the same way');
      final a = e ~/ 65536, b = e % 65536;
      expect(edges[b * 65536 + a], 1, reason: 'open edge $a-$b');
    }
    // Positive volume: triangles wind counter-clockwise seen from outside.
    final p = mesh.positions;
    var volume = 0.0;
    for (var t = 0; t < mesh.triangleCount; t++) {
      final a = idx[t * 3] * 3, b = idx[t * 3 + 1] * 3, c = idx[t * 3 + 2] * 3;
      volume +=
          p[a] * (p[b + 1] * p[c + 2] - p[b + 2] * p[c + 1]) -
          p[a + 1] * (p[b] * p[c + 2] - p[b + 2] * p[c]) +
          p[a + 2] * (p[b] * p[c + 1] - p[b + 1] * p[c]);
    }
    // About 70 litres: an athletic adult of 1.78 m.
    expect(volume / 6, inInclusiveRange(0.055, 0.09));
    for (var v = 0; v < mesh.vertexCount; v++) {
      final n = mesh.normals;
      final l = n[v * 3] * n[v * 3] + n[v * 3 + 1] * n[v * 3 + 1] + n[v * 3 + 2] * n[v * 3 + 2];
      expect(l, closeTo(1, 0.02));
    }
    // Feet on the floor, head at 1.78 m, left and right the same width.
    var lo = double.infinity, hi = double.negativeInfinity, left = 0.0, right = 0.0;
    for (var v = 0; v < mesh.vertexCount; v++) {
      lo = lo < p[v * 3 + 1] ? lo : p[v * 3 + 1];
      hi = hi > p[v * 3 + 1] ? hi : p[v * 3 + 1];
      left = left > p[v * 3] ? left : p[v * 3];
      right = right < p[v * 3] ? right : p[v * 3];
    }
    expect(lo, closeTo(0, 1e-3));
    expect(hi, closeTo(1.78, 1e-3));
    expect(left, closeTo(-right, 0.005));
  });

  test('the body mesh covers every muscle in the browse tree and fits 16-bit indices', () {
    final mesh = _mesh;
    final tree = areaMuscles.values.expand((m) => m).toSet();
    expect(mapMuscles.toSet(), tree);
    expect(mesh.vertexCount, lessThan(65536));
    final drawn = {
      for (final m in mesh.triangleMuscle)
        if (m >= 0) mapMuscles[m],
    };
    expect(drawn, tree, reason: 'every muscle has visible triangles');
    // Each muscle is on both sides of the body.
    for (final m in mapMuscles) {
      final xs = mesh.anchors[m]!.map((a) => a.point.x);
      expect(xs.any((x) => x > 0) && xs.any((x) => x < 0), isTrue, reason: '${m.label} on both sides');
    }
  });

  test('a turned body shows about half its triangles, far ones first', () {
    const size = Size(390, 400);
    for (final yaw in [0.0, 37.0, 90.0, 180.0, 270.0]) {
      final f = _draw(yaw, size);
      expect(f.order.length, inInclusiveRange(_mesh.triangleCount * 0.35, _mesh.triangleCount * 0.65));
    }
  });

  test('a tap on each muscle, front or back, picks that muscle', () {
    const size = Size(390, 400);
    final front = _draw(0, size), back = _draw(180, size);
    final views = [
      front,
      back,
      for (final yaw in [45.0, 90.0, 135.0, 225.0, 270.0, 315.0]) _draw(yaw, size),
    ];
    for (final m in mapMuscles) {
      var shown = 0;
      for (final f in views) {
        for (final at in f.anchorsOnScreen[m] ?? const <Offset>[]) {
          expect(f.hit(at), m, reason: '${m.label} at $at');
          shown++;
        }
      }
      expect(shown, greaterThan(0), reason: '${m.label} can be tapped from some view');
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
        overrides: [
          libraryProvider.overrideWith((ref) async => library),
          bodyMeshProvider.overrideWith((ref) async => _mesh),
        ],
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
