import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';

/// One point of a trend: a day (or a week) and its value. A null value is
/// a day with no data, drawn as a small dot on the base line, never as 0.
typedef TrendPoint = ({DateTime day, double? value});

/// A clean chart for one metric over time (handbook 6, drill-down pages).
///
/// Bars for daily totals, or a line for a level such as body weight. The
/// average is a dashed line with its value. The newest point is in full
/// colour and the rest are lighter, so today reads first. Tap or drag to
/// see one point's value; it reads out for screen readers too.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.points,
    required this.color,
    required this.format,
    required this.label,
    this.line = false,
    this.average,
    this.goal,
    this.height = 200,
  });

  final List<TrendPoint> points;
  final Color color;

  /// Formats a value with its unit, for the selected point and the lines.
  final String Function(double v) format;

  /// Formats a point's day, for the selected point and the axis.
  final String Function(DateTime d) label;
  final bool line;
  final double? average;
  final double? goal;
  final double height;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;

  int? _indexAt(double dx, double width) {
    final n = widget.points.length;
    if (n == 0 || width <= 0) return null;
    return (dx / width * n).floor().clamp(0, n - 1);
  }

  void _select(int? i) {
    if (i == _selected) return;
    if (i != null) HapticFeedback.selectionClick();
    setState(() => _selected = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final pts = widget.points;
    final known = [for (final e in pts) ?e.value];
    final sel = _selected == null || _selected! >= pts.length ? null : pts[_selected!];
    final lastWithData = pts.lastIndexWhere((e) => e.value != null);
    final focus = sel ?? (lastWithData < 0 ? null : pts[lastWithData]);
    return Semantics(
      label:
          '${known.length} of ${pts.length} points have data. '
          '${widget.average == null ? '' : 'Average ${widget.format(widget.average!)}. '}'
          '${focus?.value == null ? '' : '${widget.label(focus!.day)}: ${widget.format(focus.value!)}.'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The value under the finger, or the newest one. Fixed height, so
          // the chart does not jump.
          SizedBox(
            height: 40,
            child: focus == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        focus.value == null ? 'No data' : widget.format(focus.value!),
                        style: t.titleMedium?.tabular,
                      ),
                      Text(widget.label(focus.day), style: t.bodySmall?.copyWith(color: p.inkSoft)),
                    ],
                  ),
          ),
          const SizedBox(height: Space.s),
          LayoutBuilder(
            builder: (context, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _select(_indexAt(d.localPosition.dx, box.maxWidth)),
              onHorizontalDragUpdate: (d) => _select(_indexAt(d.localPosition.dx, box.maxWidth)),
              onTapUp: (_) {},
              child: TweenAnimationBuilder<double>(
                key: ValueKey(Object.hash(pts.length, widget.line, Object.hashAll(known))),
                tween: Tween(begin: 0, end: 1),
                duration: motionOf(context, Motion.chart),
                curve: Motion.enter,
                builder: (context, k, _) => SizedBox(
                  height: widget.height,
                  width: box.maxWidth,
                  child: CustomPaint(
                    painter: _TrendPainter(
                      points: pts,
                      color: widget.color,
                      faint: widget.color.withValues(alpha: 0.32),
                      grid: p.line,
                      ink: p.inkSoft,
                      line: widget.line,
                      average: widget.average,
                      goal: widget.goal,
                      selected: _selected,
                      progress: k,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          if (pts.isNotEmpty)
            Row(
              children: [
                Text(widget.label(pts.first.day), style: t.labelSmall),
                const Spacer(),
                Text(widget.label(pts.last.day), style: t.labelSmall),
              ],
            ),
          if (widget.average != null || widget.goal != null) ...[
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.l,
              children: [
                if (widget.average != null) _key(context, 'Average ${widget.format(widget.average!)}', dashed: true),
                if (widget.goal != null) _key(context, 'Target ${widget.format(widget.goal!)}', dashed: false),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _key(BuildContext context, String text, {required bool dashed}) {
    final p = context.pal;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 8,
          child: CustomPaint(painter: _KeyPainter(p.inkSoft, dashed)),
        ),
        const SizedBox(width: Space.xs),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _KeyPainter extends CustomPainter {
  _KeyPainter(this.color, this.dashed);
  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final y = size.height / 2;
    if (!dashed) return canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 3, size.width), y), paint);
    }
  }

  @override
  bool shouldRepaint(_KeyPainter o) => o.color != color || o.dashed != dashed;
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.color,
    required this.faint,
    required this.grid,
    required this.ink,
    required this.line,
    required this.average,
    required this.goal,
    required this.selected,
    required this.progress,
  });

  final List<TrendPoint> points;
  final Color color, faint, grid, ink;
  final bool line;
  final double? average, goal;
  final int? selected;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final n = points.length;
    if (n == 0) return;
    final values = [for (final e in points) ?e.value];
    final base = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), base);
    if (values.isEmpty) return;

    // Bars start at 0. A line uses the data's own range with some room, so
    // a 0.4 kg change in weight is visible.
    var hi = [...values, ?average, ?goal].reduce(math.max);
    var lo = line ? [...values, ?average, ?goal].reduce(math.min) : 0.0;
    if (line) {
      final pad = math.max((hi - lo) * 0.2, hi.abs() * 0.01 + 0.5);
      hi += pad;
      lo -= pad;
    } else {
      hi *= 1.1;
    }
    if (hi - lo < 1e-9) hi = lo + 1;
    final top = 8.0;
    double y(double v) => size.height - (size.height - top) * ((v - lo) / (hi - lo));
    final slot = size.width / n;
    final lastIdx = points.lastIndexWhere((e) => e.value != null);
    final focusIdx = selected ?? lastIdx;

    if (line) {
      final path = Path();
      var open = false;
      final dots = <Offset>[];
      for (var i = 0; i < n; i++) {
        final v = points[i].value;
        if (v == null) continue;
        final at = Offset(slot * (i + 0.5), y(lo + (v - lo) * progress));
        open ? path.lineTo(at.dx, at.dy) : path.moveTo(at.dx, at.dy);
        open = true;
        dots.add(at);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (n <= 31) {
        for (final d in dots) {
          canvas.drawCircle(d, 2.5, Paint()..color = color);
        }
      }
    } else {
      final gap = n > 60 ? 1.0 : (n > 20 ? 2.0 : 6.0);
      final w = math.max(1.5, slot - gap);
      final r = Radius.circular(math.min(6, w / 2));
      for (var i = 0; i < n; i++) {
        final v = points[i].value;
        final cx = slot * (i + 0.5);
        if (v == null) {
          canvas.drawCircle(Offset(cx, size.height - 3), math.min(2, w / 2), Paint()..color = grid);
          continue;
        }
        final h = math.max(3.0, (size.height - y(v)) * progress);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(cx - w / 2, size.height - h, w, h),
            topLeft: r,
            topRight: r,
          ),
          Paint()..color = i == focusIdx ? color : faint,
        );
      }
    }

    void hLine(double v, {required bool dashed}) {
      final yy = y(v);
      final paint = Paint()
        ..color = ink
        ..strokeWidth = 1.2;
      if (!dashed) return canvas.drawLine(Offset(0, yy), Offset(size.width, yy), paint);
      for (var x = 0.0; x < size.width; x += 7) {
        canvas.drawLine(Offset(x, yy), Offset(math.min(x + 4, size.width), yy), paint);
      }
    }

    if (average != null) hLine(average!, dashed: true);
    if (goal != null) hLine(goal!, dashed: false);

    // The selected point: a thin guide and a ring.
    if (selected != null && selected! < n) {
      final cx = slot * (selected! + 0.5);
      canvas.drawLine(Offset(cx, top), Offset(cx, size.height), Paint()..color = grid);
      final v = points[selected!].value;
      if (line && v != null) {
        canvas.drawCircle(Offset(cx, y(v)), 6, Paint()..color = color);
        canvas.drawCircle(Offset(cx, y(v)), 3, Paint()..color = grid);
      }
    }
  }

  @override
  bool shouldRepaint(_TrendPainter o) =>
      o.points != points || o.selected != selected || o.progress != progress || o.color != color;
}
