// Renders the Reparc mark to PNG masters for app icons, splash, and the
// website. Run from app/:
//
//   flutter test tool/icons/render_test.dart && python3 tool/icons/resize.py
//
// The painter is lib/core/brand.dart, so icons always match the app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/brand.dart';

Future<void> _render(String path, int size, {required bool background, double scale = 1}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (scale != 1) {
    canvas.translate(s * (1 - scale) / 2, s * (1 - scale) / 2);
    canvas.scale(scale);
  }
  ReparcMark(background: background).paint(canvas, Size(s, s));
  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render icon masters', (tester) async {
    await tester.runAsync(() async {
      const out = 'tool/icons/out';
      // Full-bleed square: iOS icon and Android legacy icon source.
      await _render('$out/icon-1024.png', 1024, background: true);
      // Android adaptive foreground: the mark inside the 66/108 safe zone.
      await _render('$out/foreground-1024.png', 1024, background: false, scale: 0.62);
      // Splash and website mark on a transparent background.
      await _render('$out/mark-1024.png', 1024, background: false);
    });
  });
}
