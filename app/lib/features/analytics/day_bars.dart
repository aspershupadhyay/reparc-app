import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/tokens.dart';

/// One bar per day. A day without records has no bar. The chart never
/// draws a line across missing days (handbook 6.3).
class DayBars extends StatelessWidget {
  const DayBars({super.key, required this.days, required this.values, required this.metric, this.unit});

  final List<DateTime> days;

  /// Values by day key. A missing key means no record on that day.
  final Map<String, double> values;
  final String metric;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final recorded = days.where((d) => values.containsKey(dayKey(d))).toList();
    final maxV = values.values.fold<double>(0, math.max);
    final peakDay = recorded.isEmpty
        ? null
        : recorded.reduce((a, b) => values[dayKey(a)]! >= values[dayKey(b)]! ? a : b);
    final label = recorded.isEmpty
        ? '$metric per day. No records in this range.'
        : '$metric per day. ${recorded.length} of ${days.length} days have records. '
              'Highest ${fmtWithUnit(maxV, unit)} on ${fmtDayMonth(peakDay!)}.';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 120,
            child: TweenAnimationBuilder<double>(
              // Animate once when data changes. Reduced motion shows the end state.
              key: ValueKey(Object.hashAll([...values.entries.map((e) => '${e.key}${e.value}'), days.length])),
              tween: Tween(begin: 0, end: 1),
              duration: motionOf(context, Motion.chart),
              curve: Motion.enter,
              builder: (_, p, _) => CustomPaint(
                painter: _BarsPainter(days: days, values: values, maxV: maxV, progress: p),
              ),
            ),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              Text(fmtDayMonth(days.first), style: t.labelSmall?.copyWith(color: AppColors.secondaryText)),
              const Spacer(),
              Text(
                maxV == 0 ? '' : 'Top: ${fmtWithUnit(maxV, unit)}',
                style: t.labelSmall?.copyWith(color: AppColors.secondaryText),
              ),
              const Spacer(),
              Text(fmtDayMonth(days.last), style: t.labelSmall?.copyWith(color: AppColors.secondaryText)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.days, required this.values, required this.maxV, required this.progress});

  final List<DateTime> days;
  final Map<String, double> values;
  final double maxV;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    final slot = size.width / n;
    final barW = math.max(2.0, math.min(24.0, slot * 0.6));
    final base = Paint()..color = AppColors.border;
    final bar = Paint()..color = AppColors.ink;
    canvas.drawRect(Rect.fromLTWH(0, size.height - 1, size.width, 1), base);
    for (var i = 0; i < n; i++) {
      final v = values[dayKey(days[i])];
      final cx = slot * i + slot / 2;
      if (v == null) {
        // No record: a small marker on the baseline, not a zero bar.
        canvas.drawCircle(Offset(cx, size.height - 1), math.min(2, barW / 2), base);
        continue;
      }
      final h = maxV == 0 ? 2.0 : math.max(2.0, (v / maxV) * (size.height - 8) * progress);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - barW / 2, size.height - 1 - h, barW, h),
          Radius.circular(math.min(6, barW / 2)),
        ),
        bar,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress || old.values != values || old.days.length != days.length || old.maxV != maxV;
}
