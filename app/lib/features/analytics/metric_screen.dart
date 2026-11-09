import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';
import '../../data/workout_repository.dart';
import '../../domain/analytics.dart';
import '../../domain/nutrition.dart';
import '../../health/health_service.dart';
import '../../health/health_sync.dart';
import '../me/health_screen.dart';
import 'trend_chart.dart';

/// The metrics with a drill-down page (owner request, 2026-11-09: "if user
/// clicks on a chart it shouldn't direct them to the permission page, it
/// should drill down about their data").
enum TrendMetric {
  steps('Steps', LucideIcons.footprints, health: HealthFeature.steps),
  distance('Distance', LucideIcons.route, health: HealthFeature.distance),
  activeEnergy('Active energy', LucideIcons.flame, health: HealthFeature.activeEnergy),
  weight('Body weight', LucideIcons.scale, line: true),
  workouts('Workouts', LucideIcons.dumbbell, sum: true),
  volume('Volume lifted', LucideIcons.chartColumn, sum: true),
  eaten('Energy eaten', LucideIcons.utensils),
  protein('Protein', LucideIcons.beef);

  const TrendMetric(this.title, this.icon, {this.health, this.line = false, this.sum = false});
  final String title;
  final IconData icon;

  /// The health type this metric reads, or null for the app's own records.
  final HealthFeature? health;

  /// Drawn as a line (a level), not bars (a daily amount).
  final bool line;

  /// The period's value is a total (workouts, volume), not a daily average.
  final bool sum;

  Color color(Palette p) => switch (this) {
    steps || distance => p.green,
    activeEnergy || eaten => p.orange,
    protein => p.coral,
    weight => p.blue,
    workouts || volume => p.brand,
  };
}

enum _Range {
  week(7, '7 days'),
  month(30, '30 days'),
  quarter(90, '90 days'),
  year(365, '1 year');

  const _Range(this.days, this.label);
  final int days;
  final String label;
}

/// Values per local day (yyyy-MM-dd) for [metric] from [from] to [to].
/// A missing key is a day with no data. Null: the source is not connected.
final metricSeriesProvider = FutureProvider.autoDispose.family<Map<String, double>?, (TrendMetric, DateTime, DateTime)>(
  (ref, key) async {
    final (metric, from, to) = key;
    final settings = ref.watch(currentSettingsProvider);
    final health = metric.health;
    if (health != null) {
      if (!settings.health.contains(health.name)) return null;
      final h = ref.watch(healthSourceProvider);
      try {
        return switch (metric) {
          TrendMetric.steps => {for (final e in (await h.dailySteps(from, to)).entries) e.key: e.value.toDouble()},
          TrendMetric.distance => await h.dailyDistance(from, to),
          _ => await h.dailyActiveEnergy(from, to),
        };
      } catch (_) {
        return const {};
      }
    }
    if (metric == TrendMetric.weight) {
      final all = await ref.watch(weightsProvider.future);
      final out = <String, double>{};
      for (final w in all) {
        final day = parseDayKey(w.day);
        if (day.isBefore(from) || day.isAfter(to)) continue;
        // In the user's unit; the last reading of a day wins.
        final kg = w.unit == 'lb' ? w.value * 0.45359237 : w.value;
        out[w.day] = settings.loadUnit == 'lb' ? kg / 0.45359237 : kg;
      }
      return out;
    }
    final s = await ref.watch(progressProvider((from, to)).future);
    switch (metric) {
      case TrendMetric.workouts:
        final out = <String, double>{};
        for (final x in s.sessions) {
          final k = dayKey(s.sessionDay(x.session));
          out[k] = (out[k] ?? 0) + 1;
        }
        return out;
      case TrendMetric.volume:
        final byDay = <String, List<SetRecord>>{};
        for (final r in s.sets) {
          (byDay[dayKey(s.sessionDay(r.session))] ??= []).add(r);
        }
        return {
          for (final e in byDay.entries)
            if (volumeOf(e.value).counted > 0) e.key: volumeOf(e.value).inUnit(settings.loadUnit),
        };
      case TrendMetric.eaten:
        return {
          for (final e in s.nutritionByDay.entries)
            if (e.value.energyKcal.value != null) e.key: e.value.energyKcal.value!,
        };
      default:
        return {
          for (final e in s.nutritionByDay.entries)
            if (e.value.proteinG.value != null) e.key: e.value.proteinG.value!,
        };
    }
  },
);

/// The drill-down page for one metric: the headline number, how it
/// changed against the period before, a chart to touch, and every day.
class MetricScreen extends ConsumerStatefulWidget {
  const MetricScreen({super.key, required this.metric});
  final TrendMetric metric;

  @override
  ConsumerState<MetricScreen> createState() => _MetricScreenState();
}

class _MetricScreenState extends ConsumerState<MetricScreen> {
  _Range _range = _Range.month;

  @override
  Widget build(BuildContext context) {
    final m = widget.metric;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(currentSettingsProvider);
    final today = dayOf(ref.watch(clockProvider)());
    final from = addDays(today, -(_range.days - 1));
    final prevTo = addDays(from, -1);
    final prevFrom = addDays(prevTo, -(_range.days - 1));
    final now = ref.watch(metricSeriesProvider((m, from, today)));
    final before = ref.watch(metricSeriesProvider((m, prevFrom, prevTo))).value;
    final fmt = _formatter(m, settings);

    return Scaffold(
      appBar: AppBar(title: Text(m.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          PillTabs<_Range>(
            compact: true,
            values: _Range.values,
            selected: _range,
            label: (r) => r.label,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: Space.l),
          now.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Space.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Text('Could not read this data. Try again.'),
            data: (series) => series == null
                ? _Connect(metric: m)
                : _Body(
                    metric: m,
                    series: series,
                    before: before,
                    from: from,
                    to: today,
                    format: fmt,
                    color: m.color(p),
                    target: _target(m, settings),
                  ),
          ),
          const SizedBox(height: Space.l),
          Text(_source(m, ref), style: t.bodySmall?.copyWith(color: p.inkSoft)),
        ],
      ),
    );
  }

  String _source(TrendMetric m, WidgetRef ref) {
    if (m.health != null) return 'From ${ref.watch(healthSourceProvider).platformName}. A gap is a day with no data.';
    return switch (m) {
      TrendMetric.weight => 'From the weights you log in Me → Body and goals.',
      TrendMetric.workouts || TrendMetric.volume => 'From your finished workouts. Volume counts working sets only.',
      _ => 'From meals marked as eaten. Planned meals are not counted.',
    };
  }

  static double? _target(TrendMetric m, AppSettings s) {
    final key = switch (m) {
      TrendMetric.eaten => Nutrient.energy,
      TrendMetric.protein => Nutrient.protein,
      _ => null,
    };
    if (key == null) return null;
    for (final x in s.targets) {
      if (x.nutrient == key) return x.amount;
    }
    return null;
  }
}

/// Formats a value of [m] with its unit.
String Function(double) _formatter(TrendMetric m, AppSettings s) => switch (m) {
  TrendMetric.steps => (v) => '${fmtNum(v, maxDecimals: 0)} steps',
  TrendMetric.distance => (v) => fmtDistance(v, s.distanceUnit)!,
  TrendMetric.activeEnergy || TrendMetric.eaten => (v) => '${fmtNum(v, maxDecimals: 0)} kcal',
  TrendMetric.weight => (v) => '${fmtNum(v, maxDecimals: 1)} ${s.loadUnit}',
  TrendMetric.workouts => (v) => v == 1 ? '1 workout' : '${fmtNum(v, maxDecimals: 1)} workouts',
  TrendMetric.volume => (v) => '${fmtNum(v, maxDecimals: 0)} ${s.loadUnit}',
  TrendMetric.protein => (v) => '${fmtNum(v, maxDecimals: 0)} g',
};

class _Body extends StatelessWidget {
  const _Body({
    required this.metric,
    required this.series,
    required this.before,
    required this.from,
    required this.to,
    required this.format,
    required this.color,
    required this.target,
  });

  final TrendMetric metric;
  final Map<String, double> series;
  final Map<String, double>? before;
  final DateTime from, to;
  final String Function(double) format;
  final Color color;
  final double? target;

  /// The headline: a total for workouts and volume, the newest value for
  /// weight, else the average over the days that have data.
  static double? headline(TrendMetric m, Map<String, double> s) {
    if (s.isEmpty) return null;
    if (m.sum) return s.values.fold<double>(0, (a, b) => a + b);
    if (m.line) return s[(s.keys.toList()..sort()).last];
    return s.values.fold<double>(0, (a, b) => a + b) / s.length;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final m = metric;
    final days = [for (var d = from; !d.isAfter(to); d = addDays(d, 1)) d];
    final value = headline(m, series);
    final prev = before == null ? null : headline(m, before!);
    final weekly = days.length > 90;
    final points = weekly ? _weeks(days) : [for (final d in days) (day: d, value: series[dayKey(d)])];
    final known = [for (final e in points) ?e.value];
    final avg = m.line || known.isEmpty ? null : known.reduce((a, b) => a + b) / known.length;
    final best = series.isEmpty ? null : series.entries.reduce((a, b) => b.value > a.value ? b : a);
    final low = m.line && series.isNotEmpty ? series.values.reduce(math.min) : null;
    final caption = m.sum
        ? 'Total over ${days.length} days'
        : m.line
        ? 'Latest'
        : 'Average a day, over ${series.length} of ${days.length} days with data';

    if (series.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing in these ${days.length} days', style: t.titleMedium),
            const SizedBox(height: Space.xs),
            Text(_emptyHint(m), style: t.bodyMedium?.copyWith(color: p.inkSoft)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(caption, style: t.bodySmall?.copyWith(color: p.inkSoft)),
        const SizedBox(height: Space.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value == null ? '–' : format(value), style: t.displaySmall?.tabular),
              ),
            ),
            const SizedBox(width: Space.m),
            if (value != null && prev != null) _Change(now: value, before: prev, line: m.line, format: format),
          ],
        ),
        const SizedBox(height: Space.l),
        AppCard(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.l),
          child: TrendChart(
            points: points,
            color: color,
            line: m.line,
            average: avg,
            goal: target,
            format: format,
            label: (d) => weekly ? 'Week of ${fmtDayMonth(d)}' : fmtDayShort(d),
          ),
        ),
        const SizedBox(height: Space.m),
        Row(
          children: [
            if (m.line) ...[
              Expanded(child: _Stat('Lowest', format(low!))),
              Expanded(child: _Stat('Highest', format(series.values.reduce(math.max)))),
              Expanded(
                child: _Stat(
                  'Change',
                  _signed(
                    series[(series.keys.toList()..sort()).last]! - series[(series.keys.toList()..sort()).first]!,
                    format,
                  ),
                ),
              ),
            ] else ...[
              Expanded(child: _Stat(m.sum ? 'Per week' : 'Average', format(m.sum ? value! / days.length * 7 : avg!))),
              Expanded(child: _Stat('Best day', format(best!.value), note: fmtDayMonth(parseDayKey(best.key)))),
              Expanded(child: _Stat('Days with data', '${series.length}', note: 'of ${days.length}')),
            ],
          ],
        ),
        const SectionHeader('Day by day'),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (final k in (series.keys.toList()..sort((a, b) => b.compareTo(a))).take(60))
                _DayRow(
                  day: parseDayKey(k),
                  text: format(series[k]!),
                  fraction: m.line ? null : series[k]! / best!.value,
                  color: color,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Weeks for a long range: a total for workouts and volume, else the
  /// average of the week's days with data.
  List<TrendPoint> _weeks(List<DateTime> days) {
    final out = <TrendPoint>[];
    for (var i = 0; i < days.length; i += 7) {
      final week = days.sublist(i, math.min(i + 7, days.length));
      final vals = [for (final d in week) ?series[dayKey(d)]];
      out.add((
        day: week.first,
        value: vals.isEmpty
            ? null
            : metric.sum
            ? vals.reduce((a, b) => a + b)
            : vals.reduce((a, b) => a + b) / vals.length,
      ));
    }
    return out;
  }

  static String _signed(double v, String Function(double) format) =>
      v.abs() < 0.05 ? 'No change' : '${v > 0 ? '+' : '−'}${format(v.abs())}';

  static String _emptyHint(TrendMetric m) => switch (m) {
    TrendMetric.weight => 'Log your weight in Me → Body and goals. One reading a week is enough to see a trend.',
    TrendMetric.workouts || TrendMetric.volume => 'Finish a workout and it shows here.',
    TrendMetric.eaten || TrendMetric.protein => 'Mark meals as eaten in Meal and they show here.',
    _ => 'Your health app has no data for these days. Carry your phone, or wear a watch that syncs to it.',
  };
}

/// Up or down against the period before, in plain words.
class _Change extends StatelessWidget {
  const _Change({required this.now, required this.before, required this.line, required this.format});
  final double now, before;
  final bool line;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final diff = now - before;
    final pct = before == 0 ? null : diff / before * 100;
    final flat = line ? diff.abs() < 0.05 : (pct != null && pct.abs() < 1);
    final text = flat
        ? 'Same as before'
        : line
        ? '${diff > 0 ? '+' : '−'}${format(diff.abs())}'
        : pct == null
        ? 'New'
        : '${diff > 0 ? '+' : '−'}${pct.abs().round()}%';
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Semantics(
        label: '$text against the period before',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              flat
                  ? LucideIcons.minus
                  : diff > 0
                  ? LucideIcons.trendingUp
                  : LucideIcons.trendingDown,
              size: 16,
              color: p.inkSoft,
            ),
            const SizedBox(width: Space.xs),
            Text(text, style: t.labelMedium),
            Text(' vs before', style: t.bodySmall?.copyWith(color: p.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.note});
  final String label, value;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: Space.s),
    child: Metric(label: label, value: value, note: note),
  );
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.text, required this.fraction, required this.color});
  final DateTime day;
  final String text;
  final double? fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text(DateFormat('EEE d MMM').format(day), style: t.bodyMedium)),
          Expanded(
            child: fraction == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction!.clamp(0.02, 1.0),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: Space.m),
          Text(text, style: t.bodyMedium?.tabular),
        ],
      ),
    );
  }
}

/// A health metric whose type is off: connect it here, without leaving
/// the page. One system sheet for this one type.
class _Connect extends ConsumerWidget {
  const _Connect({required this.metric});
  final TrendMetric metric;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final f = metric.health!;
    final health = ref.watch(healthSourceProvider);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${metric.title} come from ${health.platformName}', style: t.titleMedium),
          const SizedBox(height: Space.xs),
          Text(f.purpose, style: t.bodyMedium?.copyWith(color: p.inkSoft)),
          const SizedBox(height: Space.m),
          FilledButton(
            onPressed: () async {
              try {
                final granted = await health.requestAll([f]);
                if (granted.contains(f)) {
                  await ref.read(settingsRepoProvider).setHealth(f.name, true);
                  ref.invalidate(healthTodayProvider);
                  unawaited(ref.read(healthSyncProvider).run());
                } else if (context.mounted) {
                  showMessage(context, '${health.platformName} did not allow ${metric.title.toLowerCase()}.');
                }
              } catch (_) {
                if (context.mounted) showMessage(context, '${health.platformName} could not open. Try again.');
              }
            },
            child: Text('Connect ${metric.title.toLowerCase()}'),
          ),
        ],
      ),
    );
  }
}
