import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/meal_plan.dart';
import '../../domain/nutrition.dart';
import '../../domain/targets.dart';
import 'meal_style.dart';

/// Builds a day of meals for the user's diet and targets. Nothing is saved
/// until the user taps Add; then the foods go in as planned, not eaten.
Future<void> showPlanDaySheet(BuildContext context, {required String day}) =>
    showAppSheet<void>(context, (_) => _PlanDaySheet(day: day));

class _PlanDaySheet extends ConsumerStatefulWidget {
  const _PlanDaySheet({required this.day});
  final String day;

  @override
  ConsumerState<_PlanDaySheet> createState() => _PlanDaySheetState();
}

class _PlanDaySheetState extends ConsumerState<_PlanDaySheet> {
  late Diet _diet = ref.read(currentSettingsProvider).profile.diet ?? Diet.nonVeg;
  late int _seed = parseDayKey(widget.day).weekday;
  bool _saving = false;

  Future<void> _add(DayPlan plan) async {
    setState(() => _saving = true);
    final repo = ref.read(mealRepoProvider);
    final slots = ref.read(mealSlotsProvider).value ?? await repo.allSlots();
    if (!mounted) return;
    String slotFor(MealKind k) {
      for (final s in slots) {
        if (slotKind(s) == k.name) return s.id;
      }
      return slots.first.id;
    }

    final ok = await guardedWrite(context, () async {
      for (final m in plan.meals) {
        for (final part in m.parts) {
          final f = part.food;
          await repo.addEntry(
            day: widget.day,
            slotId: slotFor(m.kind),
            food: FoodValues(
              name: f.name,
              servingAmount: 100,
              servingUnit: 'g',
              energyKcal: f.per100g['kcal'],
              proteinG: f.per100g['protein'],
              carbsG: f.per100g['carbs'],
              fatG: f.per100g['fat'],
              fiberG: f.per100g['fiber'],
              sugarG: f.per100g['sugar'],
              sodiumMg: f.per100g['sodium'],
              source: f.source,
              note: m.name,
            ),
            amount: part.grams,
            amountUnit: 'g',
            status: MealStatus.planned,
          );
        }
      }
      return true;
    }, success: 'Added as planned. Tick each food when you eat it.');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(currentSettingsProvider);
    final byN = {for (final x in settings.targets) x.nutrient: x};
    final lib = ref.watch(foodLibraryProvider);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: AsyncBody<FoodLibrary>(
        value: lib,
        builder: (lib) {
          final plan = planDay(
            lib: lib,
            diet: _diet,
            energy: byN[Nutrient.energy]?.amount,
            protein: byN[Nutrient.protein]?.amount,
            seed: _seed,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
            children: [
              Text('Plan my day', style: t.titleLarge),
              Text(fmtDayLong(parseDayKey(widget.day)), style: t.bodySmall),
              const SizedBox(height: Space.l),
              Text('What do you eat?', style: t.labelMedium),
              const SizedBox(height: Space.s),
              Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  for (final d in Diet.values)
                    ChoiceChip(
                      label: Text(d.label),
                      selected: _diet == d,
                      onSelected: (_) => setState(() => _diet = d),
                    ),
                ],
              ),
              const SizedBox(height: Space.xs),
              Text(_diet.hint, style: t.bodySmall),
              const SizedBox(height: Space.m),
              if (byN.isEmpty)
                const StatusLine(
                  icon: LucideIcons.info,
                  text:
                      'No targets set, so portions are standard sizes. Set targets in Me → Body and goals '
                      'to size the plan for you.',
                )
              else
                StatusLine(
                  icon: LucideIcons.target,
                  text:
                      'Sized for your targets: '
                      '${byN[Nutrient.energy] == null ? '' : '${fmtNum(byN[Nutrient.energy]!.amount, maxDecimals: 0)} kcal, '}'
                      '${fmtNum(byN[Nutrient.protein]!.amount, maxDecimals: 0)} g protein.',
                ),
              const SizedBox(height: Space.m),
              for (final m in plan.meals) ...[
                _MealCard(meal: m, showEnergy: settings.showEnergy),
                const SizedBox(height: Space.s),
              ],
              _Totals(plan: plan, targets: byN, showEnergy: settings.showEnergy),
              for (final n in plan.notes) ...[
                const SizedBox(height: Space.s),
                StatusLine(icon: LucideIcons.info, text: n),
              ],
              const SizedBox(height: Space.s),
              Text(
                'Values: USDA FoodData Central (public domain). A general guide, not medical or diet advice.',
                style: t.bodySmall,
              ),
              const SizedBox(height: Space.l),
              FilledButton.icon(
                onPressed: _saving || plan.meals.isEmpty ? null : () => _add(plan),
                icon: const Icon(LucideIcons.calendarPlus, size: 20),
                label: Text(_saving ? 'Adding' : 'Add to this day as planned'),
              ),
              const SizedBox(height: Space.s),
              OutlinedButton.icon(
                onPressed: () => setState(() => _seed++),
                icon: const Icon(LucideIcons.shuffle, size: 18),
                label: const Text('Show other meals'),
              ),
              const SizedBox(height: Space.s),
              Text(
                'You can change or remove any food after adding it.',
                style: t.bodySmall?.copyWith(color: p.inkSoft),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.showEnergy});
  final PlannedMeal meal;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final (color, soft) = switch (meal.kind) {
      MealKind.breakfast => (p.blue, p.blueSoft),
      MealKind.lunch => (p.green, p.greenSoft),
      MealKind.snack => (p.orange, p.orangeSoft),
      MealKind.dinner => (p.coral, p.coralSoft),
    };
    final kcal = meal.total(Nutrient.energy);
    final prot = meal.total(Nutrient.protein);
    final fib = meal.total(Nutrient.fiber);
    return AppCard(
      color: soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(meal.kind.label, color: color, textColor: p.on(color)),
              const SizedBox(width: Space.s),
              Expanded(child: Text(meal.name, style: t.titleSmall)),
            ],
          ),
          const SizedBox(height: Space.s),
          for (final part in meal.parts)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                children: [
                  Expanded(child: Text(part.food.name, style: t.bodyMedium)),
                  Text(part.amountText, style: t.bodySmall?.tabular),
                ],
              ),
            ),
          const SizedBox(height: Space.xs),
          Text(
            [
              if (showEnergy && kcal != null) '${fmtNum(kcal, maxDecimals: 0)} kcal',
              if (prot != null) '${fmtNum(prot, maxDecimals: 0)} g protein',
              if (fib != null) '${fmtNum(fib, maxDecimals: 0)} g fibre',
            ].join(' · '),
            style: t.labelMedium?.tabular,
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.plan, required this.targets, required this.showEnergy});
  final DayPlan plan;
  final Map<Nutrient, Target> targets;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final rows = [
      if (showEnergy) Nutrient.energy,
      Nutrient.protein,
      Nutrient.carbs,
      Nutrient.fiber,
      Nutrient.fat,
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Day total', style: t.titleMedium),
          const SizedBox(height: Space.s),
          for (final n in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(n.label, style: t.bodyMedium)),
                  Text(
                    '${fmtNum(plan.total(n), maxDecimals: 0)}'
                    '${targets[n] == null ? '' : ' / ${fmtNum(targets[n]!.amount, maxDecimals: 0)}'} ${n.unit}',
                    style: t.labelMedium?.tabular,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
