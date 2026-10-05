import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Shared design tokens. See handbook/02-experience-and-design.md, 3.8 and 3.11.
///
/// Every screen uses these roles. Do not add screen-only token sets.
abstract final class AppColors {
  static const canvas = Color(0xFFF6F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const softSurface = Color(0xFFE8F1F1);
  static const ink = Color(0xFF141B18);
  static const secondaryText = Color(0xFF5D6B66);
  static const border = Color(0xFFDCE3E0);
  static const lime = Color(0xFFD8FF75);
  static const lavender = Color(0xFFCDBBFF);
  static const success = Color(0xFF246B4C);
  static const warning = Color(0xFF8A4B00);
  static const error = Color(0xFFB3261E);
}

abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Radii {
  static const s = 12.0;
  static const m = 20.0;
  static const l = 28.0;

  static const small = BorderRadius.all(Radius.circular(s));
  static const medium = BorderRadius.all(Radius.circular(m));
  static const large = BorderRadius.all(Radius.circular(l));
}

abstract final class IconSizes {
  static const s = 20.0;
  static const m = 24.0;
}

/// Minimum touch target in logical pixels.
const double minTarget = 48;

/// Motion tokens. These are proposed starting values (handbook 3.11).
abstract final class Motion {
  static const quick = Duration(milliseconds: 120);
  static const standard = Duration(milliseconds: 200);
  static const expanded = Duration(milliseconds: 280);
  static const chart = Duration(milliseconds: 220);

  static const enter = Curves.easeOut;
  static const exit = Curves.easeIn;
  static const change = Curves.easeInOut;
}
