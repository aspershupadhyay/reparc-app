// Renders moments of the opening animation, in both themes, for a visual
// check. Run from app/:
//
//   flutter test tool/brand/render_intro_test.dart --update-goldens
//
// Output: tool/brand/out/intro-<theme>-<seconds>.png at 390 x 844.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/brand.dart';
import 'package:reparc/features/intro/intro.dart';

void main() {
  const moments = [0.3, 0.6, 0.85, 1.1, 1.3, 1.5, 1.75, 2.05, 2.5];
  for (final dark in [true, false]) {
    final theme = dark ? 'dark' : 'light';
    final colors = dark
        ? const IntroColors(BrandColors.ink, BrandColors.lime, BrandColors.white)
        : const IntroColors(BrandColors.paper, BrandColors.ink, BrandColors.ink);
    for (final s in moments) {
      testWidgets('intro $theme $s', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: IntroFrame(seconds: s, colors: colors),
          ),
        );
        await expectLater(find.byType(IntroFrame), matchesGoldenFile('out/intro-$theme-${s.toStringAsFixed(2)}.png'));
      });
    }
  }
}
