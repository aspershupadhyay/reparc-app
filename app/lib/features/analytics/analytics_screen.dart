import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/analytics.dart';
import '../../domain/nutrition.dart';
import '../exercises/area_style.dart';
import '../exercises/catalog/model.dart';
import '../exercises/library/library.dart';
import 'charts.dart';

enum _Range {
  week(7, 'Week'),
  month(30, 'Month'),
  quarter(90, '3 months');

  const _Range(this.days, this.label);
  final int days;
  final String label;
}

/// The user's own progress from saved records (handbook 6). Every number
/// opens the records behind it.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    final today = dayOf(ref.watch(clockProvider)());
    final from = addDays(today, -(_range.days - 1));
    final prevTo = addDays(from, -1);
    final prevFrom = addDays(prevTo, -(_range.days - 1));
    final now = ref.watch(progressProvider((from, today)));
    final before = ref.watch(progressProvider((prevFrom, prevTo))).value;
    final records = ref.watch(recordsProvider).value ?? const <PersonalRecord>[];
    final settings = ref.watch(currentSettingsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            ScreenTitle('Analytics', subtitle: '${fmtDayMonth(from)} – ${fmtDayMonth(today)}'),
            PillTabs<_Range>(
              values: _Range.values,
              selected: _range,
              label: (r) => r.label,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: Space.l),
            AsyncBody(
              value: now,
              builder: (s) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Consistency(s: s, before: before),
                  const SizedBox(height: Space.m),
                  _LoadRow(s: s, before: before, unit: settings.loadUnit),
                  const SizedBox(height: Space.m),
                  _Muscles(s: s),
                  const SizedBox(height: Space.m),
                  _Records(records: records, s: s),
                  const SizedBox(height: Space.m),
                  _Nutrition(s: s, showEnergy: settings.showEnergy),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRecords(BuildContext context, String kind, ProgressSummary s) =>
    context.push('/analytics/sources/$kind?from=${dayKey(s.fromDay)}&to=${dayKey(s.toDay)}');

class _Consistency extends StatelessWidget {
  const _Consistency({required this.s, required this.before});
  final ProgressSummary s;
  final ProgressSummary? before;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final days = s.trainingDays.length;
    final perDay = s.setsByDay.map((k, v) => MapEntry(k, v.toDouble()));
    for (final k in s.trainingDays) {
      perDay.putIfAbsent(k, () => 0.5);
    }
    return Material(
      color: p.panel,
      borderRadius: Radii.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRecords(context, 'workouts', s),
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workouts', style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
                        Text('${s.sessions.length}', style: t.displayLarge?.tabular.copyWith(color: p.onPanel)),
                        if (before != null)
                          Tag(
                            deltaText(s.sessions.length, before!.sessions.length),
                            color: p.panelRaised,
                            textColor: p.energy,
                            icon: s.sessions.length >= before!.sessions.length
                                ? LucideIcons.trendingUp
                                : LucideIcons.trendingDown,
                          ),
                      ],
                    ),
                  ),
                  Ring(
                    value: days / s.dayCount,
                    color: p.energy,
                    track: p.panelRaised,
                    size: 96,
                    stroke: 10,
                    semanticLabel: 'Trained on $days of ${s.dayCount} days',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$days/${s.dayCount}', style: t.titleMedium?.tabular.copyWith(color: p.onPanel)),
                        Text('days', style: t.labelSmall?.copyWith(color: p.onPanelSoft)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.l),
              Heatmap(
                from: s.fromDay,
                to: s.toDay,
                values: perDay,
                color: p.energy,
                empty: p.panelRaised,
                semanticLabel: 'Training calendar. $days days with a workout.',
              ),
              const SizedBox(height: Space.s),
              Row(
                children: [
                  Text('Less', style: t.labelSmall?.copyWith(color: p.onPanelSoft)),
                  const SizedBox(width: 6),
                  for (final a in [0.35, 0.6, 1.0])
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: p.energy.withValues(alpha: a),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const SizedBox(width: 3),
                  Text('More sets', style: t.labelSmall?.copyWith(color: p.onPanelSoft)),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, size: 18, color: p.onPanelSoft),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Total load lifted: load × reps of completed sets, in one unit.
(double, int) _volume(ProgressSummary s, String unit) {
  var v = 0.0, other = 0;
  for (final r in s.sets) {
    final l = r.set.load, n = r.set.reps;
    if (l == null || n == null) continue;
    if (r.set.loadUnit == unit) {
      v += l * n;
    } else {
      other++;
    }
  }
  return (v, other);
}

class _LoadRow extends StatelessWidget {
  const _LoadRow({required this.s, required this.before, required this.unit});
  final ProgressSummary s;
  final ProgressSummary? before;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final (vol, other) = _volume(s, unit);
    final prevVol = before == null ? null : _volume(before!, unit).$1;
    Widget tile(IconData icon, Color c, Color soft, String label, String value, String? unitText, String note) =>
        Expanded(
          child: AppCard(
            color: soft,
            onTap: () => _openRecords(context, 'workouts', s),
            semanticLabel: '$label $value ${unitText ?? ''}. $note',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon, color: c, size: 36),
                  const SizedBox(height: Space.m),
                  Metric(label: label, value: value, unit: unitText, note: note),
                ],
              ),
            ),
          ),
        );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        tile(
          LucideIcons.weight,
          p.blue,
          p.blueSoft,
          'Volume',
          fmtCompact(vol),
          unit,
          other > 0 ? '$other sets in other unit' : (prevVol == null ? '' : deltaText(vol, prevVol)),
        ),
        const SizedBox(width: Space.m),
        tile(
          LucideIcons.layers,
          p.green,
          p.greenSoft,
          'Sets done',
          '${s.completedSets}',
          null,
          '${fmtNum(s.totalReps)} reps',
        ),
      ],
    );
  }
}

class _Muscles extends ConsumerWidget {
  const _Muscles({required this.s});
  final ProgressSummary s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider).value;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final counts = <BodyArea, int>{};
    var other = 0;
    for (final r in s.sets) {
      final area = areaForCatalogId(r.exercise.catalogId, lib);
      if (area == null) {
        other++;
      } else {
        counts[area] = (counts[area] ?? 0) + 1;
      }
    }
    final maxV = [...counts.values, other].fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    final missed = BodyArea.values.where((a) => !counts.containsKey(a)).toList();
    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.personStanding, color: p.coral, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Muscles trained', style: t.titleMedium)),
              Text('sets', style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.m),
          if (s.sets.isEmpty)
            Text('Complete a set to see this.', style: t.bodyMedium?.copyWith(color: p.inkSoft))
          else ...[
            for (final a in BodyArea.values)
              if (counts.containsKey(a))
                HBar(
                  label: a.short,
                  value: counts[a]!.toDouble(),
                  max: maxV,
                  color: areaColors(p, a).$1,
                  text: '${counts[a]}',
                ),
            if (other > 0)
              HBar(label: 'Your own', value: other.toDouble(), max: maxV, color: p.inkSoft, text: '$other'),
            if (missed.isNotEmpty) ...[
              const SizedBox(height: Space.m),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Not trained:', style: t.labelSmall),
                  for (final a in missed) Tag(a.short),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Records extends StatelessWidget {
  const _Records({required this.records, required this.s});
  final List<PersonalRecord> records;
  final ProgressSummary s;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final sorted = [...records]..sort((a, b) => b.source.session.startedAt.compareTo(a.source.session.startedAt));
    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.trophy, color: p.orange, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Best lifts', style: t.titleMedium)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Heaviest completed load per exercise', style: t.bodySmall),
          const SizedBox(height: Space.m),
          if (sorted.isEmpty)
            Text('Log a set with a load to set your first record.', style: t.bodyMedium?.copyWith(color: p.inkSoft)),
          for (final r in sorted.take(5))
            Builder(
              builder: (context) {
                final d = localDayOfInstant(r.source.session.startedAt, r.source.session.utcOffsetMinutes);
                final fresh = !d.isBefore(s.fromDay);
                return InkWell(
                  borderRadius: Radii.medium,
                  onTap: () => context.push('/workout/session/${r.source.session.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.source.exercise.name, style: t.titleSmall),
                              Text(
                                '${r.source.set.reps == null ? '' : '× ${r.source.set.reps} · '}${fmtDayShort(d)}',
                                style: t.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (fresh) ...[
                          Tag('New', color: p.energy, textColor: p.onEnergy),
                          const SizedBox(width: Space.s),
                        ],
                        Text(fmtWithUnit(r.source.set.load, r.source.set.loadUnit), style: t.titleMedium?.tabular),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Nutrition extends StatelessWidget {
  const _Nutrition({required this.s, required this.showEnergy});
  final ProgressSummary s;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final n = s.nutrition;
    final byDay = s.nutritionByDay;
    final logged = s.mealDays.length;
    final kcalDays = byDay.values.where((d) => d.energyKcal.value != null).toList();
    final avg = kcalDays.isEmpty ? null : kcalDays.fold<double>(0, (a, d) => a + d.energyKcal.value!) / kcalDays.length;
    final pk = (n.proteinG.value ?? 0) * 4, ck = (n.carbsG.value ?? 0) * 4, fk = (n.fatG.value ?? 0) * 9;
    final total = pk + ck + fk;
    String pct(double v) => total == 0 ? '—' : '${(v / total * 100).round()}%';
    final daily = [for (final d in s.days) byDay[dayKey(d)]?.energyKcal.value];
    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      onTap: () => _openRecords(context, 'meals', s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.utensils, color: p.green, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Nutrition', style: t.titleMedium)),
              Text('$logged/${s.dayCount} days logged', style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.l),
          Row(
            children: [
              Donut(
                size: 120,
                parts: [(ck, p.orange), (pk, p.coral), (fk, p.blue)],
                semanticLabel: 'Macro split by energy. Carbs ${pct(ck)}, protein ${pct(pk)}, fat ${pct(fk)}.',
                child: showEnergy
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(avg == null ? '—' : fmtNum(avg, maxDecimals: 0), style: t.titleLarge?.tabular),
                          Text('kcal/day', style: t.labelSmall),
                        ],
                      )
                    : Text('Macros', style: t.labelMedium),
              ),
              const SizedBox(width: Space.xl),
              Expanded(
                child: Column(
                  children: [
                    _Legend('Carbs', p.orange, n.carbsG, pct(ck)),
                    _Legend('Protein', p.coral, n.proteinG, pct(pk)),
                    _Legend('Fat', p.blue, n.fatG, pct(fk)),
                  ],
                ),
              ),
            ],
          ),
          if (showEnergy) ...[
            const SizedBox(height: Space.l),
            Bars(
              values: _range(daily),
              labels: [fmtDayMonth(s.fromDay), fmtDayMonth(s.toDay)],
              color: p.green,
              height: 90,
              semanticLabel: 'Energy eaten per day. ${kcalDays.length} days have values.',
            ),
          ],
          const SizedBox(height: Space.m),
          StatusLine(
            icon: LucideIcons.info,
            text:
                'Eaten foods only. Macro share uses 4, 4, and 9 kcal per gram.'
                '${n.estimates > 0 ? ' ${n.estimates} estimates.' : ''}',
          ),
        ],
      ),
    );
  }

  List<double?> _range(List<double?> v) {
    if (v.length <= 31) return v;
    // Group long ranges into weeks so bars stay readable.
    final out = <double?>[];
    for (var i = 0; i < v.length; i += 7) {
      final w = v.sublist(i, i + 7 > v.length ? v.length : i + 7).whereType<double>().toList();
      out.add(w.isEmpty ? null : w.reduce((a, b) => a + b) / w.length);
    }
    return out;
  }
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color, this.n, this.share);
  final String label;
  final Color color;
  final NutrientTotal n;
  final String share;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  n.value == null ? '—' : '${fmtNum(n.value, maxDecimals: 0)} g',
                  style: t.labelMedium?.tabular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(share, textAlign: TextAlign.end, style: t.labelSmall),
          ),
        ],
      ),
    );
  }
}
