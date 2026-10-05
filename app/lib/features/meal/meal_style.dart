import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../data/database.dart';

/// Icon and colours for a meal slot.
class SlotLook {
  const SlotLook(this.icon, this.color, this.soft);
  final IconData icon;
  final Color color;
  final Color soft;
}

/// Kind of a slot. Uses the stored kind, or guesses from the name for
/// slots the user created.
String slotKind(MealSlot s) {
  if (s.kind != null) return s.kind!;
  final n = s.name.toLowerCase();
  if (n.contains('breakfast')) return 'breakfast';
  if (n.contains('lunch')) return 'lunch';
  if (n.contains('dinner') || n.contains('supper')) return 'dinner';
  if (n.contains('snack')) return 'snack';
  if (n.contains('drink') || n.contains('shake') || n.contains('coffee') || n.contains('tea')) return 'drink';
  return 'other';
}

SlotLook slotLook(Palette p, MealSlot s) => switch (slotKind(s)) {
  'breakfast' => SlotLook(LucideIcons.coffee, p.blue, p.blueSoft),
  'lunch' => SlotLook(LucideIcons.soup, p.green, p.greenSoft),
  'snack' => SlotLook(LucideIcons.apple, p.orange, p.orangeSoft),
  'dinner' => SlotLook(LucideIcons.utensilsCrossed, p.coral, p.coralSoft),
  'drink' => SlotLook(LucideIcons.cupSoda, p.brand, p.brandSoft),
  _ => SlotLook(LucideIcons.utensils, p.brand, p.brandSoft),
};
