import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/palette.dart';

/// What the inner ring is timing. Each phase has its own colours, so the
/// user can tell a set from a rest at a glance.
enum RingPhase { ready, warmup, set, rest, paused }

/// The colours of a phase on the dark workout panel: a gradient for the
/// inner ring. They come from the dark palette, because the panel is dark
/// in both modes.
List<Color> ringColors(RingPhase phase) {
  const p = Palette.dark;
  return switch (phase) {
    // Sunrise: getting warm.
    RingPhase.warmup => [p.orange, p.energy],
    // Heat: working.
    RingPhase.set => [p.coral, p.orange],
    // Cool water: recovering.
    RingPhase.rest => [p.blue, p.brand],
    RingPhase.paused => [p.onPanelSoft, p.onPanelSoft],
    RingPhase.ready => [p.brand, p.energy],
  };
}

/// Two rings around one clock (handbook 4.13).
///
/// The outer ring is the whole session: one segment for each set, filled as
/// sets are done, with the set being done now lit in the phase colour. The
/// inner ring is the set or rest now: it fills as the time runs. The middle
/// holds the clock and one word for the phase.
class RingClock extends StatelessWidget {
  const RingClock({
    super.key,
    required this.phase,
    required this.done,
    required this.total,
    required this.progress,
    required this.time,
    required this.label,
    required this.semantic,
    this.size = 232,
    this.current,
    this.showText = true,
  });

  /// False for the small ring in the folded header.
  final bool showText;

  final RingPhase phase;

  /// Sets done and sets in the session.
  final int done;
  final int total;

  /// Index of the set being done now, lit on the outer ring.
  final int? current;

  /// Fill of the inner ring, 0 to 1. Null leaves it empty, for a set the
  /// user ends.
  final double? progress;

  /// "1:15".
  final String time;

  /// "Rest", "Set 2 of 3".
  final String label;

  /// What a screen reader says.
  final String semantic;
  final double size;

  @override
  Widget build(BuildContext context) {
    const p = Palette.dark;
    final t = Theme.of(context).textTheme;
    final still = reduceMotion(context);
    final colors = ringColors(phase);
    return Semantics(
      label: semantic,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          // The inner ring glides between the one-second ticks.
          tween: Tween(end: progress ?? 0),
          duration: still ? Duration.zero : const Duration(milliseconds: 900),
          curve: Curves.linear,
          builder: (context, value, _) => CustomPaint(
            painter: _RingsPainter(
              done: done,
              total: total,
              current: current,
              progress: progress == null ? null : value,
              colors: colors,
              track: p.panelRaised,
              doneColor: p.onPanel.withValues(alpha: 0.85),
            ),
            child: !showText
                ? null
                : Center(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              label.toUpperCase(),
                              style: t.labelSmall?.copyWith(
                                color: colors.first,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              time,
                              style: t.displayMedium?.copyWith(
                                color: p.onPanel,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.done,
    required this.total,
    required this.current,
    required this.progress,
    required this.colors,
    required this.track,
    required this.doneColor,
  });

  final int done;
  final int total;
  final int? current;
  final double? progress;
  final List<Color> colors;
  final Color track;
  final Color doneColor;

  static const _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final outerW = r * 0.075;
    final innerW = r * 0.12;
    final outerR = r - outerW / 2;
    final innerR = outerR - outerW / 2 - r * 0.07 - innerW / 2;

    // Outer ring: one segment for each set of the session.
    final n = math.max(total, 1);
    final gap = n > 1 ? math.min(0.06, math.pi / n * 0.35) : 0.0;
    final seg = 2 * math.pi / n;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerW
      ..strokeCap = n > 40 ? StrokeCap.butt : StrokeCap.round;
    final outerRect = Rect.fromCircle(center: c, radius: outerR);
    for (var i = 0; i < n; i++) {
      stroke.color = total == 0
          ? track
          : i < done
          ? doneColor
          : i == current
          ? colors.first
          : track;
      // Round caps reach past the arc, so the gap takes them into account.
      final capGap = stroke.strokeCap == StrokeCap.round ? outerW / outerR : 0.0;
      final sweep = math.max(seg - gap - capGap, 0.001);
      canvas.drawArc(outerRect, _start + i * seg + (gap + capGap) / 2, sweep, false, stroke);
    }

    // Inner ring: the track, then the time run so far as a gradient.
    final innerRect = Rect.fromCircle(center: c, radius: innerR);
    canvas.drawCircle(
      c,
      innerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerW
        ..color = track,
    );
    final v = (progress ?? 0).clamp(0.0, 1.0);
    if (v <= 0) return;
    final sweep = 2 * math.pi * v;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerW
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.max(sweep, 0.01),
        colors: colors,
        transform: const GradientRotation(_start),
      ).createShader(innerRect);
    canvas.drawArc(innerRect, _start, sweep, false, arc);

    // A bright head on the moving end, so the eye finds "now".
    final head = Offset(c.dx + innerR * math.cos(_start + sweep), c.dy + innerR * math.sin(_start + sweep));
    canvas.drawCircle(
      head,
      innerW * 0.75,
      Paint()
        ..color = colors.last.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(head, innerW * 0.32, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.done != done ||
      old.total != total ||
      old.current != current ||
      old.progress != progress ||
      old.colors != colors ||
      old.track != track;
}
