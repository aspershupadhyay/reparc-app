import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/strength.dart';
import '../../domain/targets.dart';

enum _Mode { fromSet, firstTime }

/// Weight calculator: how much to lift (domain/strength.dart).
///
/// From a set: estimates a one-rep max and the weight for any rep goal.
/// First time: a cautious first weight from experience and body weight,
/// then a simple test to fine-tune it.
class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key, this.initialLoad, this.initialReps});
  final double? initialLoad;
  final int? initialReps;

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  _Mode _mode = _Mode.fromSet;
  late final _load = TextEditingController(text: widget.initialLoad == null ? '' : fmtNum(widget.initialLoad));
  late final _reps = TextEditingController(text: widget.initialReps?.toString() ?? '');
  int _rir = 0;

  Experience _level = Experience.beginner;
  TestLift _lift = TestLift.squat;
  final _bw = TextEditingController();
  bool? _female;
  int? _left;

  @override
  void initState() {
    super.initState();
    final prof = ref.read(currentSettingsProvider).profile;
    final unit = ref.read(currentSettingsProvider).loadUnit;
    if (prof.weightKg != null) {
      _bw.text = fmtNum(unit == 'lb' ? prof.weightKg! / 0.45359237 : prof.weightKg, maxDecimals: 1).replaceAll(',', '');
    }
    _female = prof.sex == null ? null : prof.sex == Sex.female;
  }

  @override
  void dispose() {
    for (final c in [_load, _reps, _bw]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unit = ref.watch(currentSettingsProvider).loadUnit;
    return Scaffold(
      appBar: AppBar(title: const Text('Weight calculator')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          PillTabs<_Mode>(
            values: _Mode.values,
            selected: _mode,
            label: (m) => m == _Mode.fromSet ? 'From a set I did' : 'My first time',
            onChanged: (m) => setState(() => _mode = m),
          ),
          const SizedBox(height: Space.l),
          if (_mode == _Mode.fromSet) ..._fromSet(context, unit) else ..._firstTime(context, unit),
        ],
      ),
    );
  }

  List<Widget> _fromSet(BuildContext context, String unit) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final load = parseDecimal(_load.text);
    final reps = int.tryParse(_reps.text.trim());
    final orm = load == null || reps == null ? null : estimateOneRepMax(load, reps, rir: _rir);
    final step = defaultStep(unit);
    return [
      Text('Enter a hard set you did recently.', style: t.bodyMedium?.copyWith(color: p.inkSoft)),
      const SizedBox(height: Space.m),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _load,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Weight', suffixText: unit),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: TextField(
              controller: _reps,
              onChanged: (_) => setState(() {}),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Reps'),
            ),
          ),
        ],
      ),
      const SizedBox(height: Space.m),
      Text('How many more reps could you have done?', style: t.labelMedium),
      const SizedBox(height: Space.s),
      PillTabs<int>(
        values: const [0, 1, 2, 3, 4],
        selected: _rir,
        label: (v) => v == 0 ? 'None' : (v == 4 ? '4+' : '$v'),
        onChanged: (v) => setState(() => _rir = v),
      ),
      const SizedBox(height: Space.l),
      if (orm == null)
        const StatusLine(icon: LucideIcons.info, text: 'Enter a weight above 0 and between 1 and 30 reps.')
      else ...[
        AppCard(
          color: p.panel,
          child: Metric(
            label: 'Estimated one-rep max',
            value: fmtNum(orm, maxDecimals: 1),
            unit: unit,
            large: true,
            color: p.energy,
            labelColor: p.onPanelSoft,
            note: estimateIsReliable(reps! + _rir)
                ? 'An estimate. Real maxes vary by person and day.'
                : 'Less reliable above 10 reps. Use a heavier set for a better estimate.',
          ),
        ),
        const SectionHeader('Weight for your goal'),
        for (final g in RepGoal.values)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.label, style: t.titleMedium),
                        Text(g.hint, style: t.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  // Leave about 2 reps in reserve at the bottom of the range.
                  Text(
                    '${fmtNum(roundDownToStep(loadForReps(orm, g.low + 2), step), maxDecimals: 1)} $unit',
                    style: t.titleLarge?.tabular,
                  ),
                ],
              ),
            ),
          ),
        const SectionHeader('Rep table'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, r) in const [1, 2, 3, 5, 6, 8, 10, 12, 15].indexed) ...[
                if (i > 0) const Divider(indent: Space.l),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                  child: Row(
                    children: [
                      SizedBox(width: 72, child: Text('$r rep${r == 1 ? '' : 's'}', style: t.bodyMedium)),
                      Expanded(
                        child: Text(
                          '${(loadForReps(orm, r) / orm * 100).round()}%',
                          style: t.bodySmall,
                        ),
                      ),
                      Text(
                        '${fmtNum(roundDownToStep(loadForReps(orm, r), step), maxDecimals: 1)} $unit',
                        style: t.titleSmall?.tabular,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.s),
        StatusLine(
          icon: LucideIcons.info,
          text:
              'Weights are rounded down to the next ${fmtNum(step)} $unit. They are the most you could do for that '
              'many reps. Train 1–3 reps short of that. Formula: average of Epley and Brzycki.',
        ),
      ],
    ];
  }

  List<Widget> _firstTime(BuildContext context, String unit) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final bw = parseDecimal(_bw.text);
    final step = _lift.perHand ? (unit == 'lb' ? 5.0 : 2.0) : defaultStep(unit);
    final first = bw == null || bw <= 0 || _female == null
        ? null
        : roundDownToStep(firstTestWeight(lift: _lift, level: _level, bodyWeight: bw, female: _female!), step);
    return [
      Text('Your experience', style: t.labelMedium),
      const SizedBox(height: Space.s),
      PillTabs<Experience>(
        values: Experience.values,
        selected: _level,
        label: (e) => e.label,
        onChanged: (e) => setState(() => _level = e),
      ),
      const SizedBox(height: Space.xs),
      Text(_level.hint, style: t.bodySmall),
      const SizedBox(height: Space.l),
      Text('Exercise', style: t.labelMedium),
      const SizedBox(height: Space.s),
      Wrap(
        spacing: Space.s,
        runSpacing: Space.s,
        children: [
          for (final l in TestLift.values)
            ChoiceChip(label: Text(l.label), selected: _lift == l, onSelected: (_) => setState(() => _lift = l)),
        ],
      ),
      const SizedBox(height: Space.l),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _bw,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Body weight', suffixText: unit),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Male')),
                ButtonSegment(value: true, label: Text('Female')),
              ],
              emptySelectionAllowed: true,
              selected: {?_female},
              onSelectionChanged: (s) => setState(() => _female = s.isEmpty ? null : s.first),
            ),
          ),
        ],
      ),
      const SizedBox(height: Space.l),
      if (first == null)
        const StatusLine(icon: LucideIcons.info, text: 'Enter your body weight and choose male or female.')
      else ...[
        AppCard(
          color: p.panel,
          child: Metric(
            label: 'Try this for 10 reps${_lift.perHand ? ' (each hand)' : ''}',
            value: fmtNum(first, maxDecimals: 1),
            unit: unit,
            large: true,
            color: p.energy,
            labelColor: p.onPanelSoft,
            note: 'A cautious first guess, not a test of your max. Warm up first.',
          ),
        ),
        const SectionHeader('Then fine-tune it'),
        Text('After 10 reps, how many more could you do with good form?', style: t.bodyMedium),
        const SizedBox(height: Space.s),
        Wrap(
          spacing: Space.s,
          children: [
            for (final v in const [0, 2, 4, 6])
              ChoiceChip(
                label: Text(switch (v) {
                  0 => '0–1',
                  2 => '2–3',
                  4 => '4–5',
                  _ => '6 or more',
                }),
                selected: _left == v,
                onSelected: (_) => setState(() => _left = v),
              ),
          ],
        ),
        if (_left != null) ...[
          const SizedBox(height: Space.m),
          AppCard(
            color: p.brandSoft,
            child: Builder(
              builder: (context) {
                final f = adjustAfterTest(_left!);
                final next = roundDownToStep(first * f, step);
                final words = f == 1
                    ? 'Just right. Train with this weight.'
                    : f < 1
                    ? 'A little heavy. Next set: $next $unit.'
                    : 'Too light. Next set: $next $unit.';
                return Text(words, style: t.titleMedium);
              },
            ),
          ),
        ],
        const SizedBox(height: Space.m),
        const StatusLine(
          icon: LucideIcons.info,
          text:
              'Guide only: share of body weight by level, lower for women to reflect average muscle mass. '
              'Stop if anything hurts. These are not strength standards.',
        ),
      ],
    ];
  }
}
