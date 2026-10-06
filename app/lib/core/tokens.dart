import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Shared size and motion tokens. Colours live in palette.dart.
/// See handbook/02-experience-and-design.md, 3.8 and 3.11.
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class Radii {
  // iOS-like corners: grouped lists 10, controls 14, cards 18.
  static const s = 10.0;
  static const m = 14.0;
  static const l = 18.0;

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
