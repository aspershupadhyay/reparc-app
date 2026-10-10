// Renders the RepArc mark to PNG masters for app icons, splash, and the
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

/// Renders the mark at [scale] of the square, centred, over [background]
/// (or transparent).
Future<void> _render(String path, int size, {Color? background, required Color color, double scale = 1}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();
  if (background != null) canvas.drawRect(Offset.zero & Size(s, s), Paint()..color = background);
  canvas.translate(s * (1 - scale) / 2, s * (1 - scale) / 2);
  canvas.scale(scale);
  ReparcMark(color: color).paint(canvas, Size(s, s));
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
      // Full-bleed square: lime mark on the training panel. iOS icon and
      // Android legacy icon source.
      await _render('$out/icon-1024.png', 1024, background: BrandColors.panel, color: BrandColors.lime, scale: 0.72);
      // Android adaptive foreground: the mark inside the 66/108 safe zone.
      await _render('$out/foreground-1024.png', 1024, color: BrandColors.lime, scale: 0.6);
      // Android 12+ splash icon (240 dp box, 160 dp visible circle), per theme.
      await _render('$out/splash-dark-1024.png', 1024, color: BrandColors.lime, scale: 0.6);
      await _render('$out/splash-light-1024.png', 1024, color: BrandColors.ink, scale: 0.6);
      // Splash and website mark on a transparent background, per theme.
      await _render('$out/mark-1024.png', 1024, color: BrandColors.lime);
      await _render('$out/mark-ink-1024.png', 1024, color: BrandColors.ink);
    });
  });
}
