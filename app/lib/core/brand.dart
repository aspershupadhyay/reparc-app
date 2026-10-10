import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'brand_wordmark.dart';

/// Brand colours. They match the shared palette (handbook 3.8).
abstract final class BrandColors {
  /// Dark canvas behind the mark (splash, intro, dark icons).
  static const ink = Color(0xFF0B0C0A);

  /// App icon tile: the lime-tinted training panel (#1A2010).
  static const panel = Color(0xFF1A2010);
  static const lime = Color(0xFFC6F432);

  /// Light canvas (iOS grouped grey).
  static const paper = Color(0xFFF2F2F7);

  /// Wordmark on dark.
  static const white = Color(0xFFF4F7EC);
}

/// Geometry of the RepArc mark on a 128 x 128 grid (D-034).
///
/// One bar runs through four round plates and rises in a flat-topped curve
/// in the middle: a loaded bar at lockout, and the "arc" in RepArc.
abstract final class MarkGeometry {
  /// Bar thickness.
  static const bar = 11.0;

  /// Centre line of the bar, left to right.
  static Path barPath() => Path()
    ..moveTo(3, 70)
    ..lineTo(35, 70)
    ..cubicTo(48, 70, 49, 53, 64, 53)
    ..cubicTo(79, 53, 80, 70, 93, 70)
    ..lineTo(125, 70);

  /// Plates as capsules (rounded ends so they read as discs), outer to
  /// inner on the left, inner to outer on the right.
  static const smallLeft = Rect.fromLTWH(7, 53, 10, 34);
  static const bigLeft = Rect.fromLTWH(20, 40, 15, 60);
  static const bigRight = Rect.fromLTWH(93, 40, 15, 60);
  static const smallRight = Rect.fromLTWH(111, 53, 10, 34);

  /// Visible ink of the mark: plate tops to plate bottoms.
  static const inkTop = 40.0;
  static const inkBottom = 100.0;

  /// Where the bubble forms and where it settles, as x on the bar.
  static const bubbleFrom = 36.0;
  static const bubbleTo = 101.0;

  /// Bubble diameter (the bar swells to this as water passes).
  static const bubble = 21.0;
}

/// The RepArc mark. Every part has its own progress value, so the intro can
/// load the bar piece by piece; with the defaults it paints the finished
/// logo. The same painter renders the app icons (tool/icons).
class ReparcMark extends CustomPainter {
  const ReparcMark({
    this.color = BrandColors.lime,
    this.smallLeft = 1,
    this.bigLeft = 1,
    this.pipe = 1,
    this.bubble = 0,
    this.bubbleAt = 0,
    this.bigRight = 1,
    this.smallRight = 1,
    this.background = false,
  });

  final Color color;

  /// 0..1: each plate slides in from its own side and fades in.
  final double smallLeft;
  final double bigLeft;
  final double bigRight;
  final double smallRight;

  /// 0..1 of the bar's length filled, from the left.
  final double pipe;

  /// Bubble size, 0..1 (0 hides it).
  final double bubble;

  /// Bubble position along the bar, 0..1 of its length.
  final double bubbleAt;

  /// Paint the icon tile behind the mark.
  final bool background;

  /// How far a plate travels while it slides in, in grid units.
  static const _slide = 29.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    if (background) canvas.drawRect(Offset.zero & Size(s, s), Paint()..color = BrandColors.panel);
    canvas.scale(s / 128);

    final paint = Paint()..color = color;
    final bar = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = MarkGeometry.bar
      ..strokeCap = StrokeCap.butt;

    final path = MarkGeometry.barPath();
    final metric = path.computeMetrics().first;
    if (pipe > 0) {
      canvas.drawPath(pipe >= 1 ? path : metric.extractPath(0, metric.length * pipe.clamp(0, 1)), bar);
    }
    if (bubble > 0) {
      final at = metric.getTangentForOffset(metric.length * bubbleAt.clamp(0, 1))!.position;
      canvas.drawCircle(at, MarkGeometry.bubble / 2 * bubble.clamp(0, 1), paint);
    }

    void plate(Rect r, double v, double side) {
      if (v <= 0) return;
      final dx = side * _slide * (1 - v);
      final rr = RRect.fromRectAndRadius(r.shift(Offset(dx, 0)), Radius.circular(r.width / 2));
      canvas.drawRRect(rr, Paint()..color = color.withValues(alpha: color.a * v.clamp(0, 1)));
    }

    plate(MarkGeometry.smallLeft, smallLeft, -1);
    plate(MarkGeometry.bigLeft, bigLeft, -1);
    plate(MarkGeometry.bigRight, bigRight, 1);
    plate(MarkGeometry.smallRight, smallRight, 1);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ReparcMark old) =>
      old.color != color ||
      old.smallLeft != smallLeft ||
      old.bigLeft != bigLeft ||
      old.pipe != pipe ||
      old.bubble != bubble ||
      old.bubbleAt != bubbleAt ||
      old.bigRight != bigRight ||
      old.smallRight != smallRight ||
      old.background != background;
}

/// The RepArc wordmark, drawn from its outlines (lib/core/brand_wordmark.dart).
class WordmarkPainter extends CustomPainter {
  const WordmarkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width / wordmarkSize.width, size.height / wordmarkSize.height);
    canvas.save();
    canvas.translate((size.width - wordmarkSize.width * k) / 2, (size.height - wordmarkSize.height * k) / 2);
    canvas.scale(k);
    canvas.drawPath(wordmarkPath..fillType = ui.PathFillType.nonZero, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(WordmarkPainter old) => old.color != color;
}

/// The finished mark as a widget.
class ReparcLogo extends StatelessWidget {
  const ReparcLogo({super.key, this.size = 48, this.background = false, this.color});
  final double size;
  final bool background;

  /// Mark colour; lime on the icon tile by default.
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'RepArc logo',
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: ReparcMark(background: background, color: color ?? BrandColors.lime),
      ),
    ),
  );
}
