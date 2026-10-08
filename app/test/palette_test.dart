import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/palette.dart';

/// Calculated contrast for the main text pairs. A rendered review on
/// devices is still required (handbook 3.8).
void main() {
  for (final (name, p) in [('light', Palette.light), ('dark', Palette.dark)]) {
    test('$name text pairs meet 4.5:1', () {
      for (final bg in [p.bg, p.surface, p.surfaceAlt]) {
        expect(contrast(p.ink, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(p.inkSoft, bg), greaterThanOrEqualTo(4.5));
      }
      expect(contrast(p.onAction, p.action), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onEnergy, p.energy), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onPanel, p.panel), greaterThanOrEqualTo(4.5));
      expect(contrast(p.onPanelSoft, p.panel), greaterThanOrEqualTo(4.5));
      for (final soft in [p.greenSoft, p.blueSoft, p.orangeSoft, p.coralSoft, p.brandSoft]) {
        expect(contrast(p.ink, soft), greaterThanOrEqualTo(4.5));
      }
    });

    test('$name category icons on their soft tints and lime on surfaces meet 3:1', () {
      for (final (c, soft) in [
        (p.green, p.greenSoft),
        (p.blue, p.blueSoft),
        (p.orange, p.orangeSoft),
        (p.coral, p.coralSoft),
        (p.brand, p.brandSoft),
      ]) {
        expect(contrast(c, soft), greaterThanOrEqualTo(3), reason: '$c on $soft');
        expect(contrast(c, p.surface), greaterThanOrEqualTo(3), reason: '$c on surface');
      }
      expect(contrast(p.energyStrong, p.surface), greaterThanOrEqualTo(4.5));
      expect(contrast(p.on(p.energyStrong), p.energyStrong), greaterThanOrEqualTo(4.5));
    });

    test('$name icon glyphs on category colours meet 3:1', () {
      for (final c in [p.green, p.blue, p.orange, p.coral, p.brand, p.energy]) {
        expect(contrast(p.on(c), c), greaterThanOrEqualTo(3));
      }
    });
  }
}
