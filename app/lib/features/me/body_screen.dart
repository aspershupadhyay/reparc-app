import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/body_repository.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../../domain/targets.dart';

/// Me → Body and goals: what the user tells the app about themselves, the
/// daily targets that come from it, and body weight check-ins.
///
/// Targets show only when the user turns them on (handbook 5.5).
class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  late Profile _p = ref.read(currentSettingsProvider).profile;
  late final _age = TextEditingController(text: _p.ageYears?.toString() ?? '');
  late final _height = TextEditingController(text: _p.heightCm == null ? '' : fmtNum(_p.heightCm).replaceAll(',', ''));
  final _weight = TextEditingController();
  String? _error;

  @override
  void dispose() {
    for (final c in [_age, _height, _weight]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save(Profile next) async {
    setState(() => _p = next);
    await guardedWrite(context, () => ref.read(settingsRepoProvider).setProfile(next));
  }

  Future<void> _logWeight(String unit) async {
    final v = parseDecimal(_weight.text);
    if (v == null || v <= 0 || v > 700) {
      setState(() => _error = 'Enter your weight, for example 72.5.');
      return;
    }
    setState(() => _error = null);
    final ok = await guardedWrite(context, () async {
      await ref.read(bodyRepoProvider).addWeight(v, unit);
      return true;
    }, success: 'Weight saved.');
    if (ok == true) {
      _weight.clear();
      await _save(_withWeight(toKg(v, unit)));
    }
  }

  Profile _withWeight(double? kg) => Profile(
    sex: _p.sex,
    ageYears: _p.ageYears,
    heightCm: _p.heightCm,
    weightKg: kg,
    activity: _p.activity,
    goal: _p.goal,
    diet: _p.diet,
    proteinPerKg: _p.proteinPerKg,
  );

  Profile _copy({
    Sex? sex,
    int? age,
    double? height,
    Activity? activity,
    BodyGoal? goal,
    Diet? diet,
    double? ratio,
    bool clearRatio = false,
    bool clearAge = false,
    bool clearHeight = false,
  }) => Profile(
    sex: sex ?? _p.sex,
    ageYears: clearAge ? null : (age ?? _p.ageYears),
    heightCm: clearHeight ? null : (height ?? _p.heightCm),
    weightKg: _p.weightKg,
    activity: activity ?? _p.activity,
    goal: goal ?? _p.goal,
    diet: diet ?? _p.diet,
    proteinPerKg: clearRatio ? null : (ratio ?? _p.proteinPerKg),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(currentSettingsProvider);
    final unit = settings.loadUnit;
    final targets = dailyTargets(_p);
    final weights = ref.watch(weightsProvider).value ?? const [];
    Widget label(String s) => Padding(
      padding: const EdgeInsets.only(top: Space.l, bottom: Space.s),
      child: Text(s, style: t.labelMedium),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Body and goals')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text(
            'Used only to work out your daily targets. Saved on this phone. Every field is optional.',
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          label('Body weight'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Metric(
                        label: 'Latest',
                        value: _p.weightKg == null ? missingText : fmtNum(fromKg(_p.weightKg!, unit), maxDecimals: 1),
                        unit: _p.weightKg == null ? null : unit,
                        note: weights.isEmpty ? null : 'Logged ${fmtDayShort(parseDayKey(weights.last.day))}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: 'Today\'s weight', suffixText: unit, errorText: _error),
                      ),
                    ),
                    const SizedBox(width: Space.s),
                    FilledButton(onPressed: () => _logWeight(unit), child: const Text('Log')),
                  ],
                ),
              ],
            ),
          ),
          label('Sex (for the energy formula)'),
          SegmentedButton<Sex>(
            segments: [for (final s in Sex.values) ButtonSegment(value: s, label: Text(s.label))],
            emptySelectionAllowed: true,
            selected: {?_p.sex},
            onSelectionChanged: (s) => s.isEmpty ? null : _save(_copy(sex: s.first)),
          ),
          label('Age and height'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', suffixText: 'years'),
                  onChanged: (v) {
                    final n = int.tryParse(v.trim());
                    _save(n == null || n < 13 || n > 110 ? _copy(clearAge: true) : _copy(age: n));
                  },
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: TextField(
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Height', suffixText: 'cm'),
                  onChanged: (v) {
                    final n = parseDecimal(v);
                    _save(n == null || n < 100 || n > 250 ? _copy(clearHeight: true) : _copy(height: n));
                  },
                ),
              ),
            ],
          ),
          label('How active are you?'),
          RadioGroup<Activity>(
            groupValue: _p.activity,
            onChanged: (v) => _save(_copy(activity: v)),
            child: Column(
              children: [
                for (final a in Activity.values)
                  RadioListTile<Activity>(
                    contentPadding: EdgeInsets.zero,
                    value: a,
                    title: Text(a.label),
                    subtitle: Text(a.hint),
                  ),
              ],
            ),
          ),
          label('Your goal'),
          Wrap(
            spacing: Space.s,
            children: [
              for (final g in BodyGoal.values)
                ChoiceChip(
                  label: Text(g.label),
                  selected: _p.goal == g,
                  onSelected: (_) => _save(_copy(goal: g)),
                ),
            ],
          ),
          label('What do you eat?'),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final d in Diet.values)
                ChoiceChip(
                  label: Text(d.label),
                  selected: _p.diet == d,
                  onSelected: (_) => _save(_copy(diet: d)),
                ),
            ],
          ),
          label('Protein per kg of body weight: ${proteinRatio(_p).toStringAsFixed(1)} g'),
          Slider(
            value: proteinRatio(_p).clamp(1.2, 2.4),
            min: 1.2,
            max: 2.4,
            divisions: 12,
            label: '${proteinRatio(_p).toStringAsFixed(1)} g/kg',
            onChanged: (v) => _save(_copy(ratio: (v * 10).round() / 10)),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Research suggests 1.6 g/kg for most people who lift, and up to 2.2 g/kg when eating less.',
                  style: t.bodySmall,
                ),
              ),
              if (_p.proteinPerKg != null)
                TextButton(onPressed: () => _save(_copy(clearRatio: true)), child: const Text('Use default')),
            ],
          ),
          const SectionHeader('Daily targets'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show targets in Meal'),
            subtitle: const Text('Off by default. You decide.'),
            value: settings.targetsOn,
            onChanged: (v) => ref.read(settingsRepoProvider).setTargetsOn(v),
          ),
          if (targets.isEmpty)
            const StatusLine(icon: LucideIcons.info, text: 'Add your body weight to see a protein target.')
          else ...[
            if (!_p.isComplete)
              const Padding(
                padding: EdgeInsets.only(bottom: Space.s),
                child: StatusLine(
                  icon: LucideIcons.info,
                  text: 'Add sex, age, height, activity, and goal to see energy, carbs, fibre, and fat too.',
                ),
              ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, x) in targets.indexed) ...[
                    if (i > 0) const Divider(indent: Space.l),
                    ListTile(
                      title: Text(x.nutrient.label),
                      subtitle: Text(x.rule),
                      trailing: Text(
                        '${x.isLimit ? 'under ' : ''}${fmtNum(x.amount, maxDecimals: 0)} ${x.nutrient.unit}',
                        style: t.titleSmall?.tabular,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Space.s),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Where these numbers come from', style: t.labelMedium),
              children: [
                for (final x in targets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: StatusLine(icon: LucideIcons.bookOpen, text: '${x.nutrient.label}: ${x.source}'),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.m),
          const StatusLine(
            icon: LucideIcons.info,
            text:
                'General guidance for healthy adults. Not medical or diet advice. If you are pregnant, '
                'under 18, or have a health condition, ask a doctor or dietitian.',
          ),
          if (targets.any((x) => x.nutrient == Nutrient.energy) && _p.weightKg != null) ...[
            const SizedBox(height: Space.s),
            Text(
              'Resting energy: ${fmtNum(restingEnergy(sex: _p.sex!, ageYears: _p.ageYears!, heightCm: _p.heightCm!, weightKg: _p.weightKg!), maxDecimals: 0)} kcal. '
              'Daily burn: ${fmtNum(maintenanceEnergy(_p), maxDecimals: 0)} kcal.',
              style: t.bodySmall?.tabular,
            ),
          ],
        ],
      ),
    );
  }
}
