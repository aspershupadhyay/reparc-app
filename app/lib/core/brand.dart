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
}

/// The Reparc mark: a range-of-motion arc read as a progress gauge, with a
/// needle that also draws the leg of an "R".
///
/// Every part has its own progress value so the intro can build the mark
/// piece by piece. With all values at 1 it paints the finished logo. The
/// same painter renders the app icons (tool/icons).
class ReparcMark extends CustomPainter {
  const ReparcMark({
    this.arc = 1,
    this.inner = 1,
    this.needle = 1,
    this.hub = 1,
    this.glow = 0,
    this.background = false,
  });

  /// 0..1 of the outer arc drawn.
  final double arc;

  /// 0..1 of the inner arc drawn.
  final double inner;

  /// Needle position: 0 points at the arc start, 1 at rest. Values above 1
  /// overshoot, which the intro uses for an elastic swing.
  final double needle;

  /// Hub scale, 0..1 (may overshoot).
  final double hub;

  /// Extra glow around the arc tip and hub, 0..1.
  final double glow;

  /// Paint the dark rounded background (for icons and splash).
  final bool background;

  static const _start = 150 * math.pi / 180;
  static const _sweep = 240 * math.pi / 180;
  static const _rest = 315 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);

    if (background) {
      final rect = Offset.zero & Size(s, s);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, 0.1),
            radius: 0.85,
            colors: [BrandColors.panelRaised, BrandColors.ink],
          ).createShader(rect),
      );
    }

    final c = Offset(s * 0.5, s * 0.56);
    final r = s * 0.27;
    final w = s * 0.085;

    // Faint full track, so the gauge reads even before it fills.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      _start,
      _sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = BrandColors.white.withValues(alpha: 0.06),
    );

    // Inner arc for depth.
    if (inner > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r * 0.62),
        _start,
        _sweep * inner.clamp(0, 1),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.03
          ..strokeCap = StrokeCap.round
          ..color = BrandColors.teal.withValues(alpha: 0.55),
      );
    }

    // Outer arc in lime, brighter toward its tip.
    if (arc > 0) {
      final sweep = _sweep * arc.clamp(0, 1);
      final rect = Rect.fromCircle(center: c, radius: r);
      canvas.drawArc(
        rect,
        _start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: 0,
            endAngle: math.pi * 2,
            transform: const GradientRotation(_start - 0.2),
            colors: const [BrandColors.deepTeal, BrandColors.teal, BrandColors.lime, BrandColors.limeLight],
            stops: const [0, 0.18, 0.55, 0.68],
          ).createShader(rect),
      );
      final tipAngle = _start + sweep;
      final tip = c + Offset(math.cos(tipAngle), math.sin(tipAngle)) * r;
      if (glow > 0) {
        canvas.drawCircle(
          tip,
          w * 1.4,
          Paint()
            ..color = BrandColors.lime.withValues(alpha: 0.45 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.9),
        );
      }
    }

    // Needle: swings from the arc start to rest.
    if (needle > 0) {
      // Clockwise from the arc start (150°) to rest (315°).
      final a = _start + (_rest - _start) * needle;
      final end = c + Offset(math.cos(a), math.sin(a)) * (r * 0.86);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round
        ..color = BrandColors.white;
      canvas.drawLine(c, end, paint);
    }

    // Hub.
    if (hub > 0) {
      if (glow > 0) {
        canvas.drawCircle(
          c,
          s * 0.11 * hub,
          Paint()
            ..color = BrandColors.lime.withValues(alpha: 0.35 * glow)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.05),
        );
      }
      canvas.drawCircle(c, s * 0.058 * hub, Paint()..color = BrandColors.lime);
      canvas.drawCircle(c, s * 0.022 * hub, Paint()..color = BrandColors.ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ReparcMark old) =>
      old.arc != arc ||
      old.inner != inner ||
      old.needle != needle ||
      old.hub != hub ||
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
