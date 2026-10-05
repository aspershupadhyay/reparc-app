import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/analytics.dart';
import '../../domain/nutrition.dart';
import 'day_bars.dart';

/// The user's own progress from saved records (handbook 6).
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final today = dayOf(ref.watch(clockProvider)());
    final from = addDays(today, -(_days - 1));
    final progress = ref.watch(progressProvider((from, today)));
    final records = ref.watch(recordsProvider);
    final showEnergy = ref.watch(currentSettingsProvider).showEnergy;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            Semantics(header: true, child: Text('Analytics', style: t.headlineSmall)),
            const SizedBox(height: Space.xs),
            Text('Your progress from records saved on this phone.', style: t.bodyMedium),
            const SizedBox(height: Space.l),
            Wrap(
              spacing: Space.s,
              children: [
                for (final d in const [7, 30, 90])
                  ChoiceChip(
                    label: Text('$d days'),
                    selected: _days == d,
                    onSelected: (_) => setState(() => _days = d),
                  ),
              ],
            ),
            const SizedBox(height: Space.s),
            Text('${fmtDayMonth(from)} to ${fmtDayMonth(today)}', style: t.bodySmall),
            AsyncBody(
              value: progress,
              builder: (p) => _RangeCards(summary: p, showEnergy: showEnergy),
            ),
            const SectionHeader('Personal records'),
            AsyncBody(
              value: records,
              builder: (list) => _Records(records: list),
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeCards extends StatelessWidget {
  const _RangeCards({required this.summary, required this.showEnergy});
  final ProgressSummary summary;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final p = summary;
    final from = dayKey(p.fromDay);
    final to = dayKey(p.toDay);
    final nutrition = p.nutrition;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Training'),
        _ChartCard(
          onOpen: () => context.go('/analytics/sources/workouts?from=$from&to=$to'),
          openLabel: 'Open the ${p.sessions.length} saved workouts behind this summary',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Metric(label: 'Workouts', value: '${p.sessions.length}'),
                ),
                Expanded(
                  child: Metric(
                    label: 'Training days',
                    value: '${p.trainingDays.length}',
                    note: 'of ${p.dayCount} days',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.l),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Metric(label: 'Completed sets', value: '${p.completedSets}'),
                ),
                Expanded(
                  child: Metric(
                    label: 'Recorded reps',
                    value: fmtNum(p.totalReps),
                    note: p.setsWithoutReps == 0 ? null : '${p.setsWithoutReps} sets have no reps',
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.l),
            DayBars(
              days: p.days,
              values: p.setsByDay.map((k, v) => MapEntry(k, v.toDouble())),
              metric: 'Completed sets',
            ),
            const SizedBox(height: Space.s),
            const _Footnote(
              'Source: your saved workouts. Only sets marked done count. Days without a bar have no record.',
            ),
          ],
        ),
        const SectionHeader('Meals'),
        _ChartCard(
          onOpen: () => context.go('/analytics/sources/meals?from=$from&to=$to'),
          openLabel: 'Open the meal records behind this summary',
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Metric(
                    label: 'Days with meals logged',
                    value: '${p.mealDays.length}',
                    note: 'of ${p.dayCount} days',
                  ),
                ),
                Expanded(
                  child: Metric(label: 'Foods eaten', value: '${nutrition.entries}'),
                ),
              ],
            ),
            if (showEnergy) ...[
              const SizedBox(height: Space.l),
              _NutrientRow(n: nutrition),
              const SizedBox(height: Space.l),
              DayBars(
                days: p.days,
                values: {
                  for (final e in p.nutritionByDay.entries)
                    if (e.value.energyKcal.value != null) e.key: e.value.energyKcal.value!,
                },
                metric: 'Energy eaten',
                unit: 'kcal',
              ),
            ] else ...[
              const SizedBox(height: Space.l),
              const _Footnote('Energy views are hidden. You can show them in Me.'),
            ],
            const SizedBox(height: Space.s),
            _Footnote(
              'Source: your manual entries. Planned foods are not counted.'
              '${nutrition.estimates > 0 ? ' ${nutrition.estimates} foods use estimated values.' : ''}',
            ),
          ],
        ),
      ],
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.n});
  final NutritionTotals n;

  @override
  Widget build(BuildContext context) {
    String? note(NutrientTotal v) => v.missing == 0 || v.counted == 0 ? null : '${v.missing} foods without value';
    Widget m(String label, NutrientTotal v, String unit) => Expanded(
      child: Metric(
        label: label,
        value: fmtNum(v.value, maxDecimals: 0),
        unit: v.value == null ? null : unit,
        semanticValue: v.value == null ? missingLabel : null,
        note: note(v),
      ),
    );
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [m('Energy eaten', n.energyKcal, 'kcal'), m('Protein', n.proteinG, 'g')],
        ),
        const SizedBox(height: Space.l),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [m('Carbs', n.carbsG, 'g'), m('Fat', n.fatG, 'g')]),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.children, required this.onOpen, required this.openLabel});
  final List<Widget> children;
  final VoidCallback onOpen;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...children,
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              label: openLabel,
              button: true,
              excludeSemantics: true,
              child: TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(LucideIcons.list, size: IconSizes.s),
                label: const Text('See records'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footnote extends StatelessWidget {
  const _Footnote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => StatusLine(icon: LucideIcons.info, text: text);
}

class _Records extends StatelessWidget {
  const _Records({required this.records});
  final List<PersonalRecord> records;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (records.isEmpty) {
      return const EmptyState(
        icon: LucideIcons.trophy,
        title: 'No records yet',
        body: 'Complete a set with a load in a saved workout. Rule: $heaviestLoadRule, per exercise and unit.',
      );
    }
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
            child: Text(
              'Rule: $heaviestLoadRule, all time. Each exercise and variation is separate. Units are not converted.',
              style: t.bodySmall,
            ),
          ),
          for (final r in records)
            ListTile(
              title: Text(
                r.source.exercise.variation == null
                    ? r.source.exercise.name
                    : '${r.source.exercise.name} · ${r.source.exercise.variation}',
              ),
              subtitle: Text(
                '${r.source.set.reps == null ? 'Reps not recorded' : '${r.source.set.reps} reps'} · '
                '${fmtDayShort(localDayOfInstant(r.source.session.startedAt, r.source.session.utcOffsetMinutes))}',
              ),
              trailing: Text(fmtWithUnit(r.source.set.load, r.source.set.loadUnit), style: t.titleMedium),
              onTap: () => context.go('/workout/session/${r.source.session.id}'),
            ),
        ],
      ),
    );
  }
}
