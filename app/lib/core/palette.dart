import 'package:flutter/material.dart';

/// Colour roles for one brightness. Screens read colours only from here.
///
/// See handbook/02-experience-and-design.md, 3.8. There is no purple.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.brand,
    required this.onBrand,
    required this.brandSoft,
    required this.energy,
    required this.onEnergy,
    required this.energyStrong,
    required this.panel,
    required this.panelRaised,
    required this.onPanel,
    required this.onPanelSoft,
    required this.success,
    required this.warning,
    required this.error,
    required this.green,
    required this.greenSoft,
    required this.blue,
    required this.blueSoft,
    required this.orange,
    required this.orangeSoft,
    required this.coral,
    required this.coralSoft,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color ink;
  final Color inkSoft;

  /// Deep teal. Selection, links, and main buttons in light mode.
  final Color brand;
  final Color onBrand;
  final Color brandSoft;

  /// Lime. Training energy: the live workout and main workout actions.
  final Color energy;
  final Color onEnergy;

  /// Lime meaning on a light surface, such as a done set or a done day.
  /// Dark green in light mode (5.2:1 on white); lime in dark mode.
  final Color energyStrong;

  /// Dark panel for the workout hero, in both modes.
  final Color panel;
  final Color panelRaised;
  final Color onPanel;
  final Color onPanelSoft;

  final Color success;
  final Color warning;
  final Color error;

  /// Category colours for meals, muscles, and charts.
  final Color green;
  final Color greenSoft;
  final Color blue;
  final Color blueSoft;
  final Color orange;
  final Color orangeSoft;
  final Color coral;
  final Color coralSoft;

  /// Main button colours. Teal in light mode, lime in dark mode.
  Color get action => brightness == Brightness.light ? brand : energy;
  Color get onAction => brightness == Brightness.light ? onBrand : onEnergy;

  Brightness get brightness => bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;

  // iOS system colours (Human Interface Guidelines, "Color"), with a teal
  // tint for identity and lime kept for training energy.
  static const light = Palette(
    bg: Color(0xFFF2F2F7), // systemGroupedBackground
    surface: Color(0xFFFFFFFF), // secondarySystemGroupedBackground
    surfaceAlt: Color(0xFFF2F2F7),
    line: Color(0xFFE5E5EA), // separator, opaque
    ink: Color(0xFF000000), // label
    inkSoft: Color(0xFF636366), // secondaryLabel, opaque for 4.5:1
    brand: Color(0xFF00727E),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFDDF0F2),
    energy: Color(0xFFC6F432),
    onEnergy: Color(0xFF000000),
    energyStrong: Color(0xFF4A7A00),
    panel: Color(0xFF1C1C1E),
    panelRaised: Color(0xFF2C2C2E),
    onPanel: Color(0xFFFFFFFF),
    onPanelSoft: Color(0xFF98989F),
    success: Color(0xFF248A3D),
    warning: Color(0xFFC93400),
    error: Color(0xFFD70015),
    // Increase Contrast shades, so icons reach 3:1 on their soft tints.
    green: Color(0xFF248A3D), // systemGreen, high contrast
    greenSoft: Color(0xFFE3F6E7),
    blue: Color(0xFF007AFF), // systemBlue
    blueSoft: Color(0xFFE0EEFF),
    orange: Color(0xFFC46A00), // deeper systemOrange
    orangeSoft: Color(0xFFFFF0DB),
    coral: Color(0xFFD70015), // systemRed, high contrast
    coralSoft: Color(0xFFFFE5E3),
  );

  static const dark = Palette(
    bg: Color(0xFF000000), // systemGroupedBackground (dark)
    surface: Color(0xFF1C1C1E), // secondarySystemGroupedBackground (dark)
    surfaceAlt: Color(0xFF2C2C2E),
    line: Color(0xFF38383A),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFF98989F),
    brand: Color(0xFF40C8E0),
    onBrand: Color(0xFF000000),
    brandSoft: Color(0xFF0D2E33),
    energy: Color(0xFFC6F432),
    onEnergy: Color(0xFF000000),
    energyStrong: Color(0xFFC6F432),
    panel: Color(0xFF1C1C1E),
    panelRaised: Color(0xFF2C2C2E),
    onPanel: Color(0xFFFFFFFF),
    onPanelSoft: Color(0xFF98989F),
    success: Color(0xFF30D158),
    warning: Color(0xFFFF9F0A),
    error: Color(0xFFFF453A),
    green: Color(0xFF30D158),
    greenSoft: Color(0xFF0F2A17),
    blue: Color(0xFF0A84FF),
    blueSoft: Color(0xFF0A2340),
    orange: Color(0xFFFF9F0A),
    orangeSoft: Color(0xFF2E1F06),
    coral: Color(0xFFFF453A),
    coralSoft: Color(0xFF33110F),
  );

  /// Readable glyph colour on [c]: white or ink, whichever has more contrast.
  Color on(Color c) => contrast(c, const Color(0xFFFFFFFF)) >= 3 ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => t < 0.5 || other == null ? this : other;
}

/// WCAG contrast ratio between two colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

extension PaletteOf on BuildContext {
  Palette get pal => Theme.of(this).extension<Palette>()!;
}
