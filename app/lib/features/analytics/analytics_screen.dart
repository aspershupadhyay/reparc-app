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
import '../../data/body_repository.dart';
import '../../data/database.dart';
import '../../data/program_repository.dart';
import '../../data/providers.dart';
import '../../domain/analytics.dart';
import '../../domain/nutrition.dart';
import '../../domain/targets.dart';
import '../exercises/area_style.dart';
import '../exercises/catalog/model.dart';
import '../exercises/library/library.dart';
import '../exercises/muscle_map.dart';
import '../exercises/rig/anatomy.dart';
import 'charts.dart';

enum _Range {
  week(7, 'Week'),
  month(30, 'Month'),
  quarter(90, '3 months');

  const _Range(this.days, this.label);
  final int days;
  final String label;
}

enum _Tab { workout, meal }

/// The user's own progress from saved records (handbook 6). Two parts:
/// Workout and Meal, so each reads on its own. Every number opens the
/// records behind it.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Range _range = _Range.week;
  _Tab _tab = _Tab.workout;

  @override
  Widget build(BuildContext context) {
    final today = dayOf(ref.watch(clockProvider)());
    final from = addDays(today, -(_range.days - 1));
    final prevTo = addDays(from, -1);
    final prevFrom = addDays(prevTo, -(_range.days - 1));
    final now = ref.watch(progressProvider((from, today)));
    final before = ref.watch(progressProvider((prevFrom, prevTo))).value;
    final settings = ref.watch(currentSettingsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            ScreenTitle('Analytics', subtitle: '${fmtDayMonth(from)} – ${fmtDayMonth(today)}'),
            PillTabs<_Tab>(
              values: _Tab.values,
              selected: _tab,
              label: (t) => t == _Tab.workout ? 'Workout' : 'Meal',
              icon: (t) => t == _Tab.workout ? LucideIcons.dumbbell : LucideIcons.utensils,
              onChanged: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: Space.s),
            PillTabs<_Range>(
              values: _Range.values,
              selected: _range,
              label: (r) => r.label,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: Space.l),
            AsyncBody(
              value: now,
              builder: (s) => _tab == _Tab.workout
                  ? _WorkoutTab(s: s, before: before, unit: settings.loadUnit)
                  : _MealTab(s: s, showEnergy: settings.showEnergy, targets: settings.targets),
            ),
          ],
        ),
      ),
    );
  }
}

void _openRecords(BuildContext context, String kind, ProgressSummary s) =>
    context.push('/analytics/sources/$kind?from=${dayKey(s.fromDay)}&to=${dayKey(s.toDay)}');

// ------------------------------------------------------------------ Workout

class _WorkoutTab extends ConsumerWidget {
  const _WorkoutTab({required this.s, required this.before, required this.unit});
  final ProgressSummary s;
  final ProgressSummary? before;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider).value ?? const <PersonalRecord>[];
    final program = ref.watch(activeProgramProvider).value;
    final weights = ref.watch(weightsProvider).value ?? const <BodyWeight>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Consistency(s: s, before: before),
        const SizedBox(height: Space.m),
        _LoadRow(s: s, before: before, unit: unit),
        if (program != null) ...[const SizedBox(height: Space.m), _RoadmapAdherence(s: s, program: program)],
        const SizedBox(height: Space.m),
        _Muscles(s: s),
        const SizedBox(height: Space.m),
        _StrengthTrend(s: s, unit: unit),
        const SizedBox(height: Space.m),
        _Records(records: records, s: s),
        if (s.dayCount > 7) ...[const SizedBox(height: Space.m), _WeeklyVolume(s: s, unit: unit)],
        const SizedBox(height: Space.m),
        _BodyWeight(s: s, weights: weights, unit: unit),
      ],
    );
  }
}

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

class _LoadRow extends StatelessWidget {
  const _LoadRow({required this.s, required this.before, required this.unit});
  final ProgressSummary s;
  final ProgressSummary? before;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final vol = volumeOf(s.sets);
    final prev = before == null ? null : volumeOf(before!.sets);
    final working = workingSets(s.sets);
    final reps = working.fold<int>(0, (a, r) => a + (r.set.reps ?? 0));
    final times = [for (final x in s.sessions) activeTime(x.session)].whereType<Duration>().toList();
    final avg = times.isEmpty ? null : Duration(seconds: times.fold<int>(0, (a, d) => a + d.inSeconds) ~/ times.length);
    Widget tile(IconData icon, Color c, Color soft, String label, String value, String? unitText, String note) =>
        Expanded(
          child: AppCard(
            color: soft,
            padding: const EdgeInsets.all(Space.m),
            onTap: () => _openRecords(context, 'workouts', s),
            semanticLabel: '$label $value ${unitText ?? ''}. $note',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconBadge(icon, color: c, size: 32),
                  const SizedBox(height: Space.s),
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
          fmtCompact(vol.inUnit(unit)),
          unit,
          vol.skipped > 0
              ? '${vol.skipped} sets without weight'
              : (prev == null ? 'weight × reps' : deltaText(vol.kg, prev.kg)),
        ),
        const SizedBox(width: Space.s),
        tile(
          LucideIcons.layers,
          p.green,
          p.greenSoft,
          'Working sets',
          '${working.length}',
          null,
          '${fmtNum(reps)} reps',
        ),
        const SizedBox(width: Space.s),
        tile(
          LucideIcons.timer,
          p.orange,
          p.orangeSoft,
          'Avg session',
          avg == null ? missingText : '${avg.inMinutes}',
          avg == null ? null : 'min',
          'excludes pauses',
        ),
      ],
    );
  }
}

class _RoadmapAdherence extends StatelessWidget {
  const _RoadmapAdherence({required this.s, required this.program});
  final ProgressSummary s;
  final SavedProgram program;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final since = dayOf(program.row.createdAt.toLocal());
    final planned = plannedDays(from: s.fromDay, to: s.toDay, weekdays: program.plan.weekdays, since: since);
    final done = s.sessions.where((x) => x.session.programId == program.id).length;
    return AppCard(
      child: Row(
        children: [
          Ring(
            value: planned == 0 ? 0 : done / planned,
            color: p.brand,
            size: 64,
            stroke: 7,
            semanticLabel: 'Roadmap: $done of $planned planned workouts',
            child: Text(planned == 0 ? missingText : '$done/$planned', style: t.labelMedium?.tabular),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Roadmap', style: t.titleMedium),
                Text(program.plan.title, style: t.bodySmall),
                Text(
                  planned == 0
                      ? 'No planned days in this range yet.'
                      : '$done of $planned planned workouts done in this range.',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Working sets per muscle per week, against the common 10–20 range for
/// muscle growth (Schoenfeld et al. 2017). Warm-up sets do not count.
class _Muscles extends ConsumerWidget {
  const _Muscles({required this.s});
  final ProgressSummary s;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider).value;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final counts = countSetsBy<Muscle>(s.sets, (r) => targetForCatalogId(r.exercise.catalogId, lib));
    final own = workingSets(s.sets).where((r) => targetForCatalogId(r.exercise.catalogId, lib) == null).length;
    final weeks = s.dayCount / 7;
    final maxV = [...counts.values.map((v) => v / weeks), 20.0].reduce((a, b) => a > b ? a : b);
    final missed = [
      for (final a in BodyArea.values)
        if (!areaMuscles[a]!.any(counts.containsKey)) a,
    ];
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.personStanding, color: p.coral, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Sets per muscle', style: t.titleMedium)),
              Text('per week', style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Most people grow well with 10–20 hard sets a week for each muscle.', style: t.bodySmall),
          const SizedBox(height: Space.m),
          if (counts.isEmpty && own == 0)
            Text('Complete a working set to see this.', style: t.bodyMedium?.copyWith(color: p.inkSoft))
          else ...[
            for (final a in BodyArea.values)
              for (final m in areaMuscles[a]!)
                if (counts[m] case final n?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        MuscleIcon.muscle(m, size: 28, color: areaColors(p, a).$1),
                        const SizedBox(width: Space.s),
                        Expanded(
                          child: HBar(
                            label: m.label,
                            value: n / weeks,
                            max: maxV,
                            color: areaColors(p, a).$1,
                            text: fmtNum(n / weeks, maxDecimals: 1),
                          ),
                        ),
                      ],
                    ),
                  ),
            if (own > 0)
              HBar(label: 'Your own', value: own / weeks, max: maxV, color: p.inkSoft, text: fmtNum(own / weeks)),
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

/// Estimated one-rep max over time for one exercise.
class _StrengthTrend extends ConsumerStatefulWidget {
  const _StrengthTrend({required this.s, required this.unit});
  final ProgressSummary s;
  final String unit;

  @override
  ConsumerState<_StrengthTrend> createState() => _StrengthTrendState();
}

class _StrengthTrendState extends ConsumerState<_StrengthTrend> {
  String? _exerciseId;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final usable = <String, (String, String)>{};
    for (final r in widget.s.sets) {
      if (setEstimate(r) != null && r.set.loadUnit != null) {
        usable.putIfAbsent('${r.exercise.id}|${r.set.loadUnit}', () => (r.exercise.name, r.set.loadUnit!));
      }
    }
    final keys = usable.keys.toList()..sort((a, b) => usable[a]!.$1.compareTo(usable[b]!.$1));
    final key = keys.contains(_exerciseId) ? _exerciseId! : (keys.isEmpty ? null : keys.first);
    final trend = key == null
        ? const <(DateTime, double)>[]
        : estimateTrend(widget.s.sets, exerciseId: key.split('|').first, unit: usable[key]!.$2);
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.trendingUp, color: p.blue, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Strength', style: t.titleMedium)),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Estimated one-rep max from your best set of 1–10 reps each day', style: t.bodySmall),
          if (key == null)
            Padding(
              padding: const EdgeInsets.only(top: Space.m),
              child: Text(
                'Log a set with weight and 1–10 reps to see this.',
                style: t.bodyMedium?.copyWith(color: p.inkSoft),
              ),
            )
          else ...[
            const SizedBox(height: Space.s),
            DropdownButton<String>(
              value: key,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: [
                for (final k in keys) DropdownMenuItem(value: k, child: Text('${usable[k]!.$1} (${usable[k]!.$2})')),
              ],
              onChanged: (v) => setState(() => _exerciseId = v),
            ),
            Row(
              children: [
                Expanded(
                  child: Metric(
                    label: 'Latest',
                    value: fmtNum(trend.last.$2, maxDecimals: 1),
                    unit: usable[key]!.$2,
                    note: fmtDayShort(trend.last.$1),
                  ),
                ),
                if (trend.length > 1)
                  Metric(
                    label: 'Change',
                    value:
                        '${trend.last.$2 >= trend.first.$2 ? '+' : ''}'
                        '${fmtNum(trend.last.$2 - trend.first.$2, maxDecimals: 1)}',
                    unit: usable[key]!.$2,
                    note: 'since ${fmtDayShort(trend.first.$1)}',
                  ),
              ],
            ),
            const SizedBox(height: Space.m),
            LineChart(
              points: trend,
              color: p.blue,
              semanticLabel: 'Estimated one-rep max on ${trend.length} days.',
            ),
          ],
        ],
      ),
    );
  }
}

class _WeeklyVolume extends StatelessWidget {
  const _WeeklyVolume({required this.s, required this.unit});
  final ProgressSummary s;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final byWeek = weeklyVolume(s.sets);
    final first = addDays(s.fromDay, -(s.fromDay.weekday - 1));
    final weeks = <DateTime>[for (var d = first; !d.isAfter(s.toDay); d = addDays(d, 7)) d];
    final factor = unit == 'lb' ? 1 / kgPerLb : 1.0;
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Volume per week', style: t.titleMedium),
          Text('Weight × reps of working sets, in $unit', style: t.bodySmall),
          const SizedBox(height: Space.m),
          Bars(
            values: [for (final w in weeks) byWeek[w] == null ? null : byWeek[w]! * factor],
            labels: [fmtDayMonth(weeks.first), fmtDayMonth(weeks.last)],
            color: p.blue,
            height: 100,
            semanticLabel: 'Volume per week. ${byWeek.length} weeks have data.',
          ),
        ],
      ),
    );
  }
}

class _BodyWeight extends StatelessWidget {
  const _BodyWeight({required this.s, required this.weights, required this.unit});
  final ProgressSummary s;
  final List<BodyWeight> weights;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final inRange = [
      for (final w in weights)
        if (!parseDayKey(w.day).isBefore(s.fromDay) && !parseDayKey(w.day).isAfter(s.toDay))
          (parseDayKey(w.day), fromKg(toKg(w.value, w.unit), unit)),
    ];
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      onTap: () => context.push('/me/body'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.scale, color: p.green, size: 36),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Body weight', style: t.titleMedium)),
              if (inRange.length > 1)
                Text(
                  '${inRange.last.$2 >= inRange.first.$2 ? '+' : ''}'
                  '${fmtNum(inRange.last.$2 - inRange.first.$2, maxDecimals: 1)} $unit',
                  style: t.titleSmall?.tabular,
                ),
            ],
          ),
          const SizedBox(height: Space.m),
          if (inRange.isEmpty)
            Text('Log your weight in Me → Body and goals.', style: t.bodyMedium?.copyWith(color: p.inkSoft))
          else
            LineChart(
              points: inRange,
              color: p.green,
              height: 100,
              semanticLabel: '${inRange.length} weight check-ins in this range.',
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------- Meal

class _MealTab extends StatelessWidget {
  const _MealTab({required this.s, required this.showEnergy, required this.targets});
  final ProgressSummary s;
  final bool showEnergy;
  final List<Target> targets;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final byDay = s.nutritionByDay;
    final byN = {for (final x in targets) x.nutrient: x};
    final logged = s.mealDays.length;
    final rows = [
      if (showEnergy) (Nutrient.energy, p.brand),
      (Nutrient.protein, p.coral),
      (Nutrient.carbs, p.orange),
      (Nutrient.fiber, p.green),
      (Nutrient.fat, p.blue),
      (Nutrient.sugar, p.inkSoft),
      (Nutrient.sodium, p.inkSoft),
    ];
    List<double?> daily(Nutrient n) => [for (final d in s.days) byDay[dayKey(d)]?.of(n).value];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: p.panel,
          onTap: () => _openRecords(context, 'meals', s),
          semanticLabel: 'Food logged on $logged of ${s.dayCount} days. Open meal records',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Metric(
                    label: 'Days with food logged',
                    value: '$logged',
                    unit: 'of ${s.dayCount}',
                    large: true,
                    color: p.onPanel,
                    labelColor: p.onPanelSoft,
                    note: 'Eaten foods only. Planned foods do not count.',
                  ),
                ),
                Ring(
                  value: logged / s.dayCount,
                  color: p.energy,
                  track: p.panelRaised,
                  size: 72,
                  stroke: 8,
                  semanticLabel: '',
                  child: Text(
                    '${(logged / s.dayCount * 100).round()}%',
                    style: t.labelMedium?.tabular.copyWith(color: p.onPanel),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.m),
        AppCard(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Daily average', style: t.titleMedium),
              Text('Over days that have a value. Empty days are not counted as zero.', style: t.bodySmall),
              const SizedBox(height: Space.m),
              for (final (n, color) in rows)
                Builder(
                  builder: (context) {
                    final avg = dailyAverage(byDay, n);
                    final target = byN[n];
                    final hit = target == null ? null : daysOnTarget(byDay, n, target.amount, limit: target.isLimit);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
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
                                Text(n.label, style: t.labelMedium),
                                Text(
                                  hit == null
                                      ? (avg.days == 0 ? 'No values yet' : 'on ${avg.days} days')
                                      : '${target!.isLimit ? 'Under' : 'Reached'} on ${hit.$1} of ${hit.$2} days',
                                  style: t.labelSmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${fmtNum(avg.value, maxDecimals: 0)}'
                            '${target == null ? '' : ' / ${fmtNum(target.amount, maxDecimals: 0)}'} ${n.unit}',
                            style: t.labelMedium?.tabular,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.m),
        for (final (n, color) in [(Nutrient.protein, p.coral), (Nutrient.fiber, p.green)]) ...[
          AppCard(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${n.label} per day', style: t.titleMedium),
                Text(
                  byN[n] == null ? 'Grams eaten' : 'Line: your target of ${fmtNum(byN[n]!.amount, maxDecimals: 0)} g',
                  style: t.bodySmall,
                ),
                const SizedBox(height: Space.m),
                Bars(
                  values: _group(daily(n)),
                  labels: [fmtDayMonth(s.fromDay), fmtDayMonth(s.toDay)],
                  color: color,
                  goal: s.dayCount <= 31 ? byN[n]?.amount : null,
                  height: 100,
                  semanticLabel: '${n.label} per day. ${daily(n).whereType<double>().length} days have values.',
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
        ],
        _Nutrition(s: s, showEnergy: showEnergy),
      ],
    );
  }
}

/// Long ranges show weekly averages so bars stay readable.
List<double?> _group(List<double?> v) {
  if (v.length <= 31) return v;
  final out = <double?>[];
  for (var i = 0; i < v.length; i += 7) {
    final w = v.sublist(i, i + 7 > v.length ? v.length : i + 7).whereType<double>().toList();
    out.add(w.isEmpty ? null : w.reduce((a, b) => a + b) / w.length);
  }
  return out;
}

/// Macro split by energy, and energy per day.
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
    final avg = dailyAverage(byDay, Nutrient.energy).value;
    final pk = (n.proteinG.value ?? 0) * 4, ck = (n.carbsG.value ?? 0) * 4, fk = (n.fatG.value ?? 0) * 9;
    final total = pk + ck + fk;
    String pct(double v) => total == 0 ? missingText : '${(v / total * 100).round()}%';
    final daily = [for (final d in s.days) byDay[dayKey(d)]?.energyKcal.value];
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      onTap: () => _openRecords(context, 'meals', s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Where your energy comes from', style: t.titleMedium),
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
                          Text(avg == null ? missingText : fmtNum(avg, maxDecimals: 0), style: t.titleLarge?.tabular),
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
              values: _group(daily),
              labels: [fmtDayMonth(s.fromDay), fmtDayMonth(s.toDay)],
              color: p.brand,
              height: 90,
              semanticLabel: 'Energy eaten per day. ${daily.whereType<double>().length} days have values.',
            ),
          ],
          const SizedBox(height: Space.m),
          StatusLine(
            icon: LucideIcons.info,
            text:
                'Eaten foods only. Share uses 4 kcal per gram for protein and carbs, 9 for fat.'
                '${n.estimates > 0 ? ' ${n.estimates} estimates.' : ''}',
          ),
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
