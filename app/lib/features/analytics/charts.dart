import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';

/// Calendar heatmap. One square per day, weeks as columns. A day without
/// records stays empty. It is never drawn as zero activity on a line.
class Heatmap extends StatelessWidget {
  const Heatmap({
    super.key,
    required this.from,
    required this.to,
    required this.values,
    required this.color,
    required this.empty,
    required this.semanticLabel,
  });

  final DateTime from;
  final DateTime to;
  final Map<String, double> values;
  final Color color;
  final Color empty;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final start = addDays(from, -(from.weekday - 1));
    final weeks = (to.difference(start).inDays ~/ 7) + 1;
    final maxV = values.values.fold<double>(0, math.max);
    Color fill(DateTime day) {
      final v = values[dayKey(day)];
      return v == null ? empty : color.withValues(alpha: maxV == 0 ? 1 : 0.35 + 0.65 * (v / maxV));
    }

    if (to.difference(from).inDays < 7) {
      // One week: a single row of days with their letters.
      final t = Theme.of(context).textTheme;
      final n = to.difference(from).inDays + 1;
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: Row(
          children: [
            for (var i = 0; i < n; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(color: fill(addDays(from, i)), borderRadius: Radii.small),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'MTWTFSS'[addDays(from, i).weekday - 1],
                        style: t.labelSmall?.copyWith(color: empty.computeLuminance() < 0.2 ? Colors.white70 : null),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, c) {
          const gap = 4.0;
          final cell = math.min(28.0, (c.maxWidth - gap * (weeks - 1)) / weeks);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var w = 0; w < weeks; w++)
                Padding(
                  padding: EdgeInsets.only(right: w == weeks - 1 ? 0 : gap),
                  child: Column(
                    children: [
                      for (var d = 0; d < 7; d++)
                        Builder(
                          builder: (context) {
                            final day = addDays(start, w * 7 + d);
                            final out = day.isBefore(from) || day.isAfter(to);
                            final v = values[dayKey(day)];
                            final a = v == null || maxV == 0 ? 0.0 : 0.35 + 0.65 * (v / maxV);
                            return Container(
                              width: cell,
                              height: cell,
                              margin: const EdgeInsets.only(bottom: gap),
                              decoration: BoxDecoration(
                                color: out ? Colors.transparent : (v == null ? empty : color.withValues(alpha: a)),
                                borderRadius: BorderRadius.circular(cell * 0.28),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Vertical bars, one per bucket. Buckets without data have no bar.
class Bars extends StatelessWidget {
  const Bars({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.semanticLabel,
    this.height = 140,
    this.goal,
  });

  /// Optional target drawn as a line across the bars.
  final double? goal;

  final List<double?> values;
  final List<String> labels;
  final Color color;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final maxV = math.max(values.whereType<double>().fold<double>(0, math.max), goal ?? 0);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(child: _barsBody(context, maxV, p)),
                if (goal != null && maxV > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: height * goal! / maxV - 1,
                    child: Container(height: 2, color: p.ink.withValues(alpha: 0.5)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              for (final (i, l) in labels.indexed)
                Expanded(
                  child: Text(
                    l,
                    textAlign: i == 0 ? TextAlign.start : (i == labels.length - 1 ? TextAlign.end : TextAlign.center),
                    style: t.labelSmall,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barsBody(BuildContext context, double maxV, Palette p) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(Object.hashAll(values)),
      tween: Tween(begin: 0, end: 1),
      duration: motionOf(context, Motion.chart),
      curve: Motion.enter,
      builder: (context, k, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final v in values)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: values.length > 14 ? 1 : 3),
                child: v == null || maxV == 0
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
                        ),
                      )
                    : FractionallySizedBox(
                        heightFactor: math.max(0.04, v / maxV * k),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Donut of shares. [parts] are (value, colour). Zero total shows a ring.
class Donut extends StatelessWidget {
  const Donut({super.key, required this.parts, required this.size, required this.child, required this.semanticLabel});
  final List<(double, Color)> parts;
  final double size;
  final Widget child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final track = context.pal.line;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: motionOf(context, Motion.expanded),
        builder: (context, k, _) => CustomPaint(
          painter: _DonutPainter(parts, track, k),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.parts, this.track, this.k);
  final List<(double, Color)> parts;
  final Color track;
  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * math.pi, false, paint..color = track);
    final total = parts.fold<double>(0, (a, p) => a + p.$1);
    if (total <= 0) return;
    var a = -math.pi / 2;
    for (final (v, c) in parts) {
      final sweep = 2 * math.pi * v / total * k;
      canvas.drawArc(r, a + 0.03, math.max(0, sweep - 0.06), false, paint..color = c);
      a += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter o) => o.k != k || o.parts != parts;
}

/// One labelled horizontal bar.
class HBar extends StatelessWidget {
  const HBar({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.text,
  });
  final String label;
  final double value;
  final double max;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $text',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(label, style: t.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: Container(
                height: 14,
                decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: BorderRadius.circular(7)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: max == 0 ? 0 : (value / max).clamp(0.02, 1.0),
                  child: Container(
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(text, textAlign: TextAlign.end, style: t.labelMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Up or down change against the previous period.
String deltaText(num now, num before) {
  // Nothing in both periods says nothing, not "Same as before".
  if (before == 0) return now == 0 ? '' : 'New';
  final pct = ((now - before) / before * 100).round();
  if (pct == 0) return 'Same as before';
  return '${pct > 0 ? '+' : ''}$pct% vs before';
}

String fmtCompact(double v) => v >= 10000 ? '${fmtNum(v / 1000, maxDecimals: 1)}k' : fmtNum(v, maxDecimals: 0);

/// Points over time joined by a line. A gap of more than [maxGapDays]
/// breaks the line, so missing weeks are not drawn as data.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.points,
    required this.color,
    required this.semanticLabel,
    this.height = 140,
    this.maxGapDays = 21,
  });

  final List<(DateTime, double)> points;
  final Color color;
  final String semanticLabel;
  final double height;
  final int maxGapDays;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _LinePainter(points, color, p.line, maxGapDays)),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points, this.color, this.grid, this.maxGapDays);
  final List<(DateTime, double)> points;
  final Color color;
  final Color grid;
  final int maxGapDays;

  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    if (points.isEmpty) return;
    final t0 = points.first.$1, t1 = points.last.$1;
    final span = math.max(1, t1.difference(t0).inDays);
    var lo = points.map((e) => e.$2).reduce(math.min), hi = points.map((e) => e.$2).reduce(math.max);
    if (hi - lo < 1e-9) {
      lo -= 1;
      hi += 1;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    Offset at((DateTime, double) e) => Offset(
      points.length == 1 ? size.width / 2 : size.width * e.$1.difference(t0).inDays / span,
      size.height * (1 - (e.$2 - lo) / (hi - lo)),
    );
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      if (points[i].$1.difference(points[i - 1].$1).inDays > maxGapDays) continue;
      canvas.drawLine(at(points[i - 1]), at(points[i]), line);
    }
    final dot = Paint()..color = color;
    for (final e in points) {
      canvas.drawCircle(at(e), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter o) => o.points != points || o.color != color;
}
