import 'package:flutter/widgets.dart';

import '../../core/palette.dart';
import 'catalog/model.dart';

/// One colour per body area, from the shared palette.
(Color, Color) areaColors(Palette p, BodyArea a) => switch (a) {
  BodyArea.chest => (p.coral, p.coralSoft),
  BodyArea.back => (p.blue, p.blueSoft),
  BodyArea.shoulders => (p.orange, p.orangeSoft),
  BodyArea.arms => (p.brand, p.brandSoft),
  BodyArea.legs => (p.green, p.greenSoft),
  BodyArea.glutes => (p.coral, p.coralSoft),
  BodyArea.core => (p.orange, p.orangeSoft),
};
