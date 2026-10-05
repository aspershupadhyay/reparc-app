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

  /// Dark panel for the workout hero and the body model, in both modes.
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

  static const light = Palette(
    bg: Color(0xFFEEF4F4),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF5F9F9),
    line: Color(0xFFDCE6E6),
    ink: Color(0xFF0F1B1D),
    inkSoft: Color(0xFF56686B),
    brand: Color(0xFF1E5B66),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFDCEDEF),
    energy: Color(0xFFC6F432),
    onEnergy: Color(0xFF0F1B1D),
    panel: Color(0xFF0F1B1D),
    panelRaised: Color(0xFF1A282B),
    onPanel: Color(0xFFF2F7F7),
    onPanelSoft: Color(0xFF9FB1B4),
    success: Color(0xFF2E8A57),
    warning: Color(0xFFA35F00),
    error: Color(0xFFC2362B),
    green: Color(0xFF6FA83A),
    greenSoft: Color(0xFFE8F3DC),
    blue: Color(0xFF2F4FD9),
    blueSoft: Color(0xFFE5E9FB),
    orange: Color(0xFFF29F1F),
    orangeSoft: Color(0xFFFFF0DA),
    coral: Color(0xFFE85A43),
    coralSoft: Color(0xFFFCE7E2),
  );

  static const dark = Palette(
    bg: Color(0xFF0A1012),
    surface: Color(0xFF121A1D),
    surfaceAlt: Color(0xFF182226),
    line: Color(0xFF243136),
    ink: Color(0xFFEAF1F1),
    inkSoft: Color(0xFF93A5A9),
    brand: Color(0xFF5CC1CC),
    onBrand: Color(0xFF0A1012),
    brandSoft: Color(0xFF15343A),
    energy: Color(0xFFC6F432),
    onEnergy: Color(0xFF0A1012),
    panel: Color(0xFF141E21),
    panelRaised: Color(0xFF1D2A2E),
    onPanel: Color(0xFFEAF1F1),
    onPanelSoft: Color(0xFF93A5A9),
    success: Color(0xFF5CC48A),
    warning: Color(0xFFF0A847),
    error: Color(0xFFFF7B6B),
    green: Color(0xFF8CC657),
    greenSoft: Color(0xFF1A2914),
    blue: Color(0xFF5B86FF),
    blueSoft: Color(0xFF142140),
    orange: Color(0xFFFFB547),
    orangeSoft: Color(0xFF2C2010),
    coral: Color(0xFFFF7B63),
    coralSoft: Color(0xFF331A17),
  );

  /// Readable glyph colour on [c]: white or ink, whichever has more contrast.
  Color on(Color c) => contrast(c, const Color(0xFFFFFFFF)) >= 3 ? const Color(0xFFFFFFFF) : const Color(0xFF0F1B1D);

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
