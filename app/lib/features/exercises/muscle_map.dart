import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'catalog/model.dart';
import 'rig/anatomy.dart';

/// Where each muscle sits in the browse tree, and which side of the body
/// shows it.
extension MuscleGroups on Muscle {
  BodyArea get area => switch (this) {
    Muscle.chest || Muscle.upperChest || Muscle.lowerChest => BodyArea.chest,
    Muscle.lats || Muscle.upperBack || Muscle.traps || Muscle.lowerBack => BodyArea.back,
    Muscle.frontDelts || Muscle.sideDelts || Muscle.rearDelts => BodyArea.shoulders,
    Muscle.biceps || Muscle.triceps || Muscle.forearms => BodyArea.arms,
    Muscle.quads || Muscle.hamstrings || Muscle.calves || Muscle.adductors || Muscle.hipFlexors => BodyArea.legs,
    Muscle.glutes || Muscle.abductors => BodyArea.glutes,
    Muscle.abs || Muscle.lowerAbs || Muscle.obliques => BodyArea.core,
  };

  /// True when the muscle is drawn on the back view.
  bool get onBack => const {
    Muscle.lats,
    Muscle.upperBack,
    Muscle.traps,
    Muscle.lowerBack,
    Muscle.rearDelts,
    Muscle.triceps,
    Muscle.glutes,
    Muscle.abductors,
    Muscle.hamstrings,
    Muscle.calves,
  }.contains(this);

  /// Short words for the browse list.
  String get hint => switch (this) {
    Muscle.upperChest => 'Top of the chest, below the collarbone',
    Muscle.chest => 'Middle of the chest: most of its size',
    Muscle.lowerChest => 'Lower edge of the chest',
    Muscle.lats => 'Width: the wings under your arms',
    Muscle.upperBack => 'Thickness: between the shoulder blades',
    Muscle.traps => 'Top of the back, from the neck to the shoulders',
    Muscle.lowerBack => 'Muscles beside the spine, low down',
    Muscle.frontDelts => 'Front of the shoulder',
    Muscle.sideDelts => 'Side of the shoulder: makes shoulders look wider',
    Muscle.rearDelts => 'Back of the shoulder: helps posture',
    Muscle.biceps => 'Front of the upper arm',
    Muscle.triceps => 'Back of the upper arm: most of the arm size',
    Muscle.forearms => 'Grip and wrist',
    Muscle.quads => 'Front of the thigh',
    Muscle.hamstrings => 'Back of the thigh',
    Muscle.calves => 'Lower leg, behind the shin',
    Muscle.adductors => 'Inside of the thigh',
    Muscle.hipFlexors => 'Front of the hip',
    Muscle.glutes => 'Your bum: hip power',
    Muscle.abductors => 'Side of the hip: keeps knees and pelvis steady',
    Muscle.abs => 'Six-pack, front of the stomach',
    Muscle.lowerAbs => 'Below the navel: lift the legs or curl the hips',
    Muscle.obliques => 'Sides of the waist',
  };
}

/// Muscles shown under each body area, in the order a coach would teach.
const areaMuscles = <BodyArea, List<Muscle>>{
  BodyArea.chest: [Muscle.upperChest, Muscle.chest, Muscle.lowerChest],
  BodyArea.back: [Muscle.lats, Muscle.upperBack, Muscle.traps, Muscle.lowerBack],
  BodyArea.shoulders: [Muscle.frontDelts, Muscle.sideDelts, Muscle.rearDelts],
  BodyArea.arms: [Muscle.biceps, Muscle.triceps, Muscle.forearms],
  BodyArea.legs: [Muscle.quads, Muscle.hamstrings, Muscle.calves, Muscle.adductors],
  BodyArea.glutes: [Muscle.glutes, Muscle.abductors],
  BodyArea.core: [Muscle.abs, Muscle.lowerAbs, Muscle.obliques],
};

/// Body icon artwork: a realistic muscle illustration with only the
/// target muscle, or the whole area, in a vivid colour. Made in Figma; see
/// `tool/body_icons/README.md`.
String bodyIconAsset({BodyArea? area, Muscle? muscle}) =>
    'assets/body/icons/${muscle != null ? muscle.name : 'area_${area!.name}'}.webp';

/// An icon for one body area or one muscle: the anatomy in soft grey, with
/// only that part lit. Chest shows the chest, biceps show the biceps, and
/// so on.
class MuscleIcon extends StatelessWidget {
  const MuscleIcon.area(BodyArea this.area, {super.key, this.size = 44, required this.color, this.background})
    : muscle = null;
  const MuscleIcon.muscle(Muscle this.muscle, {super.key, this.size = 44, required this.color, this.background})
    : area = null;

  final BodyArea? area;
  final Muscle? muscle;
  final double size;

  /// Tints the tile behind the artwork.
  final Color color;

  /// Fill behind the artwork. Null draws a soft tint of [color].
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final px = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(size * 0.26),
        ),
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.all(size * 0.06),
        child: Image.asset(
          bodyIconAsset(area: area, muscle: muscle),
          // Decode at the size shown, not 256 px, to keep memory low in
          // long lists.
          cacheWidth: px < 256 ? px : null,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

/// Front and back figures side by side, with main muscles in a strong
/// colour and helper muscles in a lighter one.
class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.primary,
    this.secondary = const {},
    required this.hot,
    required this.warm,
    required this.body,
    this.height = 180,
  });

  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final Color hot;
  final Color warm;
  final Color body;
  final double height;

  @override
  Widget build(BuildContext context) {
    Widget fig(bool back) => SizedBox(
      width: height / 2,
      height: height,
      child: CustomPaint(
        painter: _FigurePainter(
          primary: primary,
          secondary: secondary,
          back: back,
          crop: const Rect.fromLTRB(0, 0, 100, 200),
          hot: hot,
          warm: warm,
          body: body,
        ),
      ),
    );
    final names = [...primary.map((m) => m.label), ...secondary.map((m) => '${m.label} (helper)')];
    return Semantics(
      label: 'Muscles worked: ${names.join(', ')}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(children: [fig(false), _caption(context, 'Front')]),
          SizedBox(width: height / 6),
          Column(children: [fig(true), _caption(context, 'Back')]),
        ],
      ),
    );
  }

  Widget _caption(BuildContext context, String s) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(s, style: Theme.of(context).textTheme.labelSmall),
  );
}

class _FigurePainter extends CustomPainter {
  _FigurePainter({
    required this.primary,
    required this.secondary,
    required this.back,
    required this.crop,
    required this.hot,
    required this.body,
    this.warm,
  });

  final Set<Muscle> primary;
  final Set<Muscle> secondary;
  final bool back;
  final Rect crop;
  final Color hot;
  final Color? warm;
  final Color body;

  @override
  void paint(Canvas canvas, Size size) {
    // Fit the crop in the box, keep proportions, centre it.
    final s = math.min(size.width / crop.width, size.height / crop.height) * 0.92;
    final dx = (size.width - crop.width * s) / 2 - crop.left * s;
    final dy = (size.height - crop.height * s) / 2 - crop.top * s;
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(s);

    // Draw the body in one layer so overlapping parts keep one even tint.
    canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, body.a));
    _silhouette(canvas, Paint()..color = body.withValues(alpha: 1));
    canvas.restore();
    for (final m in Muscle.values) {
      final isMain = primary.contains(m);
      final isHelper = !isMain && secondary.contains(m);
      if (!isMain && !isHelper) continue;
      if (m.onBack != back) continue;
      _muscle(canvas, m, Paint()..color = isMain ? hot : (warm ?? hot.withValues(alpha: 0.55)));
    }
    canvas.restore();
  }

  void _cap(Canvas c, Offset a, Offset b, double r, Paint p, {bool mirror = true}) {
    final stroke = Paint()
      ..color = p.color
      ..strokeWidth = r * 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(a, b, stroke);
    if (mirror) c.drawLine(Offset(100 - a.dx, a.dy), Offset(100 - b.dx, b.dy), stroke);
  }

  void _oval(Canvas c, Offset center, double rx, double ry, Paint p, {bool mirror = true}) {
    c.drawOval(Rect.fromCenter(center: center, width: rx * 2, height: ry * 2), p);
    if (mirror) {
      c.drawOval(Rect.fromCenter(center: Offset(100 - center.dx, center.dy), width: rx * 2, height: ry * 2), p);
    }
  }

  void _silhouette(Canvas c, Paint p) {
    _oval(c, const Offset(50, 12.5), 8, 10, p, mirror: false);
    final neck = Path()
      ..moveTo(45, 19)
      ..lineTo(55, 19)
      ..lineTo(57, 31)
      ..lineTo(43, 31)
      ..close();
    c.drawPath(neck, p);
    final torso = Path()
      ..moveTo(30, 32)
      ..quadraticBezierTo(50, 26, 70, 32)
      ..quadraticBezierTo(76, 35, 74.5, 44)
      ..quadraticBezierTo(68, 52, 66.5, 60)
      ..quadraticBezierTo(63, 74, 63.5, 86)
      ..quadraticBezierTo(67, 94, 66.5, 104)
      ..lineTo(55, 112)
      ..lineTo(45, 112)
      ..lineTo(33.5, 104)
      ..quadraticBezierTo(33, 94, 36.5, 86)
      ..quadraticBezierTo(37, 74, 33.5, 60)
      ..quadraticBezierTo(32, 52, 25.5, 44)
      ..quadraticBezierTo(24, 35, 30, 32)
      ..close();
    c.drawPath(torso, p);
    _cap(c, const Offset(28.5, 40), const Offset(25, 72), 6, p); // upper arm
    _cap(c, const Offset(24.5, 75), const Offset(20.5, 106), 4.6, p); // forearm
    _oval(c, const Offset(19.5, 113), 4, 5.2, p); // hand
    _cap(c, const Offset(42, 106), const Offset(42.5, 146), 9, p); // thigh
    _cap(c, const Offset(42.5, 150), const Offset(42.5, 186), 6, p); // shin
    _oval(c, const Offset(41.5, 192), 5.5, 3.2, p); // foot
  }

  void _muscle(Canvas c, Muscle m, Paint p) {
    switch (m) {
      case Muscle.upperChest:
        _oval(c, const Offset(41.8, 39.5), 8, 3.8, p);
      case Muscle.chest:
        _oval(c, const Offset(41.8, 46.5), 8.6, 6.4, p);
      case Muscle.lowerChest:
        _oval(c, const Offset(41.8, 51), 8.2, 3.4, p);
      case Muscle.frontDelts:
        _oval(c, const Offset(32.5, 37), 4.6, 5.6, p);
      case Muscle.sideDelts:
        _oval(c, const Offset(27.5, 39), 4.2, 6.2, p);
      case Muscle.biceps:
        _cap(c, const Offset(27.5, 47), const Offset(25.5, 66), 4.4, p);
      case Muscle.forearms:
        _cap(c, const Offset(23.8, 80), const Offset(21.2, 100), 3.8, p);
      case Muscle.abs:
        c.drawRRect(RRect.fromLTRBR(44.5, 55, 55.5, 90, const Radius.circular(4)), p);
      case Muscle.lowerAbs:
        c.drawRRect(RRect.fromLTRBR(44.5, 76, 55.5, 92, const Radius.circular(4)), p);
      case Muscle.obliques:
        _cap(c, const Offset(39, 61), const Offset(39.5, 86), 3.2, p);
      case Muscle.quads:
        _cap(c, const Offset(42, 116), const Offset(42.3, 142), 7, p);
      case Muscle.adductors:
        _cap(c, const Offset(47.5, 111), const Offset(46.5, 130), 2.8, p);
      case Muscle.hipFlexors:
        _cap(c, const Offset(40, 100), const Offset(44, 108), 3, p);
      case Muscle.upperBack:
        // Rhomboids and mid traps, between the shoulder blades.
        final mid = Path()
          ..moveTo(50, 34)
          ..lineTo(60, 38)
          ..quadraticBezierTo(57, 52, 50, 62)
          ..quadraticBezierTo(43, 52, 40, 38)
          ..close();
        c.drawPath(mid, p);
      case Muscle.traps:
        // Upper traps: neck to the tops of the shoulders.
        final traps = Path()
          ..moveTo(50, 22)
          ..lineTo(56, 28)
          ..lineTo(66, 33)
          ..lineTo(58, 36)
          ..lineTo(50, 38)
          ..lineTo(42, 36)
          ..lineTo(34, 33)
          ..lineTo(44, 28)
          ..close();
        c.drawPath(traps, p);
      case Muscle.lats:
        final wing = Path()
          ..moveTo(34, 42)
          ..quadraticBezierTo(43, 52, 47.5, 64)
          ..lineTo(46, 86)
          ..quadraticBezierTo(38, 76, 34.5, 60)
          ..quadraticBezierTo(33, 50, 34, 42)
          ..close();
        c.drawPath(wing, p);
        c.drawPath(wing.transform(_mirror), p);
      case Muscle.lowerBack:
        c.drawRRect(RRect.fromLTRBR(44.5, 72, 55.5, 95, const Radius.circular(3)), p);
      case Muscle.rearDelts:
        _oval(c, const Offset(30, 37.5), 4.8, 5.6, p);
      case Muscle.triceps:
        _cap(c, const Offset(27.5, 46), const Offset(25.5, 68), 4.6, p);
      case Muscle.glutes:
        _oval(c, const Offset(43.5, 102), 7.6, 7.8, p);
      case Muscle.abductors:
        _oval(c, const Offset(35.5, 97), 3.4, 6.5, p);
      case Muscle.hamstrings:
        _cap(c, const Offset(42, 118), const Offset(42.3, 144), 7, p);
      case Muscle.calves:
        _cap(c, const Offset(42.3, 156), const Offset(42.5, 175), 5.4, p);
    }
  }

  static final _mirror = Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 100, 0, 0, 1]);

  @override
  bool shouldRepaint(_FigurePainter o) =>
      o.back != back ||
      o.crop != crop ||
      o.hot != hot ||
      o.body != body ||
      o.warm != warm ||
      !_same(o.primary, primary) ||
      !_same(o.secondary, secondary);

  static bool _same(Set<Muscle> a, Set<Muscle> b) => a.length == b.length && a.containsAll(b);
}
