import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Brand colours. They match the shared palette (handbook 3.8).
abstract final class BrandColors {
  static const ink = Color(0xFF0A1012);
  static const panel = Color(0xFF141E21);
  static const panelRaised = Color(0xFF1D2A2E);
  static const lime = Color(0xFFC6F432);
  static const limeLight = Color(0xFFE4FF8A);
  static const teal = Color(0xFF5CC1CC);
  static const deepTeal = Color(0xFF1E5B66);
  static const white = Color(0xFFEAF1F1);

  /// The mark's gradient: teal into lime, top left to bottom right.
  static const markGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, lime, limeLight],
    stops: [0.45, 0.8, 1],
  );
}

/// The Reparc mark: a white "R" whose leg is a limb. It swings from a lime
/// joint through a dotted arc, the range of motion of one rep (Rep + Arc).
///
/// Every part has its own progress value so the intro can build the mark
/// piece by piece. With all values at 1 it paints the finished logo. The
/// same painter renders the app icons (tool/icons).
class ReparcMark extends CustomPainter {
  const ReparcMark({
    this.letter = 1,
    this.dots = 1,
    this.leg = 1,
    this.joint = 1,
    this.glow = 0,
    this.background = false,
  });

  /// 0..1 of the white stem and bowl drawn.
  final double letter;

  /// 0..1 of the range-of-motion dots shown.
  final double dots;

  /// Leg swing: 0 hangs straight down, 1 is at rest. Values above 1
  /// overshoot, which the intro uses for an elastic swing.
  final double leg;

  /// Joint scale, 0..1 (may overshoot).
  final double joint;

  /// Extra glow around the joint, 0..1.
  final double glow;

  /// Paint the dark background (for icons and splash).
  final bool background;

  /// Where the joint sits, as a fraction of the mark's square.
  static const jointAt = Offset(0.48, 0.48);

  static const _rest = 56 * math.pi / 180;
  static const _hang = 90 * math.pi / 180;
  static const _legLength = 0.31;
  static const _dotCount = 7;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    final box = Offset.zero & Size(s, s);
    final accent = BrandColors.markGradient.createShader(box);

    if (background) {
      canvas.drawRect(
        box,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.16),
            radius: 0.75,
            colors: [BrandColors.panelRaised, BrandColors.ink],
          ).createShader(box),
      );
    }

    final j = jointAt * s;
    final w = s * 0.10;

    // Range of motion: dots on an arc around the joint, from the hanging
    // position up to rest. They appear from the bottom.
    if (dots > 0) {
      final r = s * (_legLength + 0.08);
      final shown = (_dotCount * dots.clamp(0, 1)).ceil();
      for (var i = 0; i < shown; i++) {
        final a = _rest + (50 * math.pi / 180) * (1 - i / (_dotCount - 1));
        canvas.drawCircle(
          j + Offset(math.cos(a), math.sin(a)) * r,
          s * 0.015,
          Paint()
            ..shader = accent
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85),
        );
      }
    }

    // The white stem and bowl, drawn as one stroke.
    if (letter > 0) {
      final path = Path()
        ..moveTo(0.30 * s, 0.74 * s)
        ..lineTo(0.30 * s, 0.20 * s)
        ..lineTo(0.49 * s, 0.20 * s)
        ..arcToPoint(Offset(0.49 * s, 0.48 * s), radius: Radius.circular(0.14 * s))
        ..lineTo(0.34 * s, 0.48 * s);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = BrandColors.white;
      if (letter >= 1) {
        canvas.drawPath(path, paint);
      } else {
        for (final m in path.computeMetrics()) {
          canvas.drawPath(m.extractPath(0, m.length * letter.clamp(0, 1)), paint);
        }
      }
    }

    // The leg swings from hanging to rest.
    if (leg > 0) {
      final a = _hang + (_rest - _hang) * leg;
      final tip = j + Offset(math.cos(a), math.sin(a)) * (s * _legLength);
      canvas.drawLine(
        j,
        tip,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..shader = accent,
      );
    }

    // The joint.
    if (joint > 0) {
      if (glow > 0) {
        canvas.drawCircle(
          j,
          s * 0.13 * joint,
          Paint()
            ..color = BrandColors.lime.withValues(alpha: 0.45 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
        );
      }
      canvas.drawCircle(j, s * 0.075 * joint, Paint()..shader = accent);
      canvas.drawCircle(j, s * 0.026 * joint, Paint()..color = BrandColors.ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ReparcMark old) =>
      old.letter != letter ||
      old.dots != dots ||
      old.leg != leg ||
      old.joint != joint ||
      old.glow != glow ||
      old.background != background;
}

/// The finished mark as a widget.
class ReparcLogo extends StatelessWidget {
  const ReparcLogo({super.key, this.size = 48, this.background = false});
  final double size;
  final bool background;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Reparc logo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: ReparcMark(background: background)),
    ),
  );
}
