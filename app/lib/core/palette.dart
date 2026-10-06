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
    required this.amber,
    required this.amberSoft,
    required this.coral,
    required this.coralSoft,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color ink;
  final Color inkSoft;

  /// Ember. Selection, links, and main buttons in light mode (a deeper
  /// shade so white text stays readable).
  final Color brand;
  final Color onBrand;
  final Color brandSoft;

  /// Bright ember. Training energy: the live workout and main workout actions.
  final Color energy;
  final Color onEnergy;

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
  final Color amber;
  final Color amberSoft;
  final Color coral;
  final Color coralSoft;

  /// Main button colours. Deep ember in light mode, bright ember in dark mode.
  Color get action => brightness == Brightness.light ? brand : energy;
  Color get onAction => brightness == Brightness.light ? onBrand : onEnergy;

  Brightness get brightness => bg.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;

  // iOS system colours (Human Interface Guidelines, "Color"), with one ember
  // accent for identity and training energy (D-028).
  static const light = Palette(
    bg: Color(0xFFF2F2F7), // systemGroupedBackground
    surface: Color(0xFFFFFFFF), // secondarySystemGroupedBackground
    surfaceAlt: Color(0xFFF2F2F7),
    line: Color(0xFFE5E5EA), // separator, opaque
    ink: Color(0xFF000000), // label
    inkSoft: Color(0xFF636366), // secondaryLabel, opaque for 4.5:1
    brand: Color(0xFFC2410C),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFFFEADF),
    energy: Color(0xFFFF5A1F),
    onEnergy: Color(0xFF000000),
    panel: Color(0xFF1C1C1E),
    panelRaised: Color(0xFF2C2C2E),
    onPanel: Color(0xFFFFFFFF),
    onPanelSoft: Color(0xFF98989F),
    success: Color(0xFF248A3D),
    warning: Color(0xFF9F5A00),
    error: Color(0xFFD70015),
    green: Color(0xFF34C759), // systemGreen
    greenSoft: Color(0xFFE3F6E7),
    blue: Color(0xFF007AFF), // systemBlue
    blueSoft: Color(0xFFE0EEFF),
    amber: Color(0xFFF5B400), // between systemYellow and systemOrange
    amberSoft: Color(0xFFFFF4D1),
    coral: Color(0xFFFF3B30), // systemRed
    coralSoft: Color(0xFFFFE5E3),
  );

  static const dark = Palette(
    bg: Color(0xFF000000), // systemGroupedBackground (dark)
    surface: Color(0xFF1C1C1E), // secondarySystemGroupedBackground (dark)
    surfaceAlt: Color(0xFF2C2C2E),
    line: Color(0xFF38383A),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFF98989F),
    brand: Color(0xFFFF7A3D),
    onBrand: Color(0xFF000000),
    brandSoft: Color(0xFF3A1A0C),
    energy: Color(0xFFFF5A1F),
    onEnergy: Color(0xFF000000),
    panel: Color(0xFF1C1C1E),
    panelRaised: Color(0xFF2C2C2E),
    onPanel: Color(0xFFFFFFFF),
    onPanelSoft: Color(0xFF98989F),
    success: Color(0xFF30D158),
    warning: Color(0xFFFFD60A),
    error: Color(0xFFFF453A),
    green: Color(0xFF30D158),
    greenSoft: Color(0xFF0F2A17),
    blue: Color(0xFF0A84FF),
    blueSoft: Color(0xFF0A2340),
    amber: Color(0xFFFFD60A), // systemYellow (dark)
    amberSoft: Color(0xFF2E2604),
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
