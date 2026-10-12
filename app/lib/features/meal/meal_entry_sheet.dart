import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/meal_plan.dart';
import '../../domain/nutrition.dart';

/// Adds or edits a food in a meal slot (handbook 5.2).
Future<void> showMealEntrySheet(BuildContext context, {required String day, String? slotId, MealEntry? existing}) {
  return showAppSheet<void>(context, (_) => _EntrySheet(day: day, slotId: slotId, existing: existing));
}

const _servingUnits = ['g', 'ml', 'oz', 'piece', 'cup', 'tbsp', 'tsp'];

class _EntrySheet extends ConsumerStatefulWidget {
  const _EntrySheet({required this.day, this.slotId, this.existing});
  final String day;
  final String? slotId;
  final MealEntry? existing;

  @override
  ConsumerState<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<_EntrySheet> {
  late final MealEntry? _e = widget.existing;
  late String? _slotId = _e?.slotId ?? widget.slotId;
  String? _foodId;
  late final _name = TextEditingController(text: _e?.name ?? '');
  late final _brand = TextEditingController(text: _e?.brand ?? '');
  late final _serving = TextEditingController(text: _n(_e?.servingAmount));
  late String _servingUnit = _e?.servingUnit ?? 'g';
  late final _kcal = TextEditingController(text: _n(_e?.energyKcal));
  late final _protein = TextEditingController(text: _n(_e?.proteinG));
  late final _carbs = TextEditingController(text: _n(_e?.carbsG));
  late final _fat = TextEditingController(text: _n(_e?.fatG));
  late final _fiber = TextEditingController(text: _n(_e?.fiberG));
  late final _sugar = TextEditingController(text: _n(_e?.sugarG));
  late final _sodium = TextEditingController(text: _n(_e?.sodiumMg));
  late final _amount = TextEditingController(text: _e == null ? '' : _n(_e.amount));
  late String _amountUnit = _e?.amountUnit ?? 'serving';
  late bool _estimate = _e?.isEstimate ?? false;
  late MealStatus _status = _e?.status ?? _defaultStatus();
  late String _source = _e?.source ?? sourceManual;

  /// Household portions of the picked list food ("1 katori", "1 roti").
  List<Portion> _portions = const [];
  bool _saveFood = false;

  /// The user chose to type a food in by hand.
  bool _manual = false;
  final _search = TextEditingController();
  String? _error;
  bool _saving = false;

  static String _n(double? v) => v == null ? '' : fmtNum(v, maxDecimals: 3).replaceAll(',', '');

  MealStatus _defaultStatus() {
    final today = dayKey(dayOf(ref.read(clockProvider)()));
    return widget.day.compareTo(today) > 0 ? MealStatus.planned : MealStatus.eaten;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _brand,
      _serving,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber,
      _sugar,
      _sodium,
      _amount,
      _search,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _useFood(Food f) {
    setState(() {
      _foodId = f.id;
      _name.text = f.name;
      _brand.text = f.brand ?? '';
      _serving.text = _n(f.servingAmount);
      _servingUnit = f.servingUnit ?? 'g';
      _kcal.text = _n(f.energyKcal);
      _protein.text = _n(f.proteinG);
      _carbs.text = _n(f.carbsG);
      _fat.text = _n(f.fatG);
      _fiber.text = _n(f.fiberG);
      _sugar.text = _n(f.sugarG);
      _sodium.text = _n(f.sodiumMg);
      _estimate = f.isEstimate;
      _source = f.source;
      _portions = const [];
      _search.clear();
      _saveFood = false;
    });
  }

  /// Fills the form from a food logged before, with the amount used then.
  void _useRecent(MealEntry e) {
    setState(() {
      _foodId = e.foodId;
      _name.text = e.name;
      _brand.text = e.brand ?? '';
      _serving.text = _n(e.servingAmount);
      _servingUnit = e.servingUnit ?? 'g';
      _kcal.text = _n(e.energyKcal);
      _protein.text = _n(e.proteinG);
      _carbs.text = _n(e.carbsG);
      _fat.text = _n(e.fatG);
      _fiber.text = _n(e.fiberG);
      _sugar.text = _n(e.sugarG);
      _sodium.text = _n(e.sodiumMg);
      _amount.text = _n(e.amount);
      _amountUnit = e.amountUnit ?? 'serving';
      _estimate = e.isEstimate;
      _source = e.source;
      _portions = const [];
      _search.clear();
      _saveFood = false;
    });
  }

  /// Fills the form from the bundled USDA list: values per 100 g, and the
  /// usual portion as the amount.
  void _useUsda(FoodItem f) {
    String v(String k) => _n(f.per100g[k]);
    setState(() {
      _foodId = null;
      _name.text = f.name;
      _brand.text = '';
      _serving.text = '100';
      _servingUnit = 'g';
      _kcal.text = v('kcal');
      _protein.text = v('protein');
      _carbs.text = v('carbs');
      _fat.text = v('fat');
      _fiber.text = v('fiber');
      _sugar.text = v('sugar');
      _sodium.text = v('sodium');
      _estimate = f.estimate;
      _source = f.source;
      _portions = f.allPortions;
      _amount.text = _n(_portions.first.grams);
      _amountUnit = 'g';
      _search.clear();
      _saveFood = false;
    });
  }

  /// Parses an optional, non-negative number. Throws on bad input.
  double? _opt(TextEditingController c, String label) {
    final v = parseDecimal(c.text);
    if (v != null && (v.isNaN || v < 0)) throw FormatException('$label must be a number of 0 or more.');
    return v;
  }

  FoodValues _values() => FoodValues(
    name: _name.text,
    brand: _brand.text,
    servingAmount: _opt(_serving, 'Serving size'),
    servingUnit: _serving.text.trim().isEmpty ? null : _servingUnit,
    energyKcal: _opt(_kcal, 'Energy'),
    proteinG: _opt(_protein, 'Protein'),
    carbsG: _opt(_carbs, 'Carbs'),
    fatG: _opt(_fat, 'Fat'),
    fiberG: _opt(_fiber, 'Fibre'),
    sugarG: _opt(_sugar, 'Sugar'),
    sodiumMg: _opt(_sodium, 'Sodium'),
    isEstimate: _estimate,
    source: _source,
  );

  Future<void> _save() async {
    final FoodValues v;
    final double? amount;
    try {
      if (_name.text.trim().isEmpty) throw const FormatException('Enter a food name.');
      if (_slotId == null) throw const FormatException('Choose a meal.');
      v = _values();
      amount = _opt(_amount, 'Amount eaten');
      if (amount == null || amount == 0) throw const FormatException('Enter the amount.');
    } on FormatException catch (e) {
      setState(() => _error = e.message);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final repo = ref.read(mealRepoProvider);
    final e = _e;
    final ok = await guardedWrite(
      context,
      () async {
        String? foodId = _foodId;
        if (_saveFood) foodId = await repo.saveFood(v);
        if (e == null) {
          await repo.addEntry(
            day: widget.day,
            slotId: _slotId!,
            food: v,
            amount: amount!,
            amountUnit: _amountUnit,
            status: _status,
            foodId: foodId,
          );
        } else {
          await repo.updateEntry(e.id, slotId: _slotId!, food: v, amount: amount!, amountUnit: _amountUnit);
          if (e.status != _status) await repo.setStatus(e.id, _status);
        }
        return true;
      },
      success: e == null ? 'Food saved.' : 'Changes saved.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final repo = ref.read(mealRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final removed = await guardedWrite(context, () => repo.deleteEntry(_e!.id));
    if (!mounted) return;
    Navigator.pop(context);
    if (removed != null) {
      messenger.showSnackBar(
        messageBar('${removed.name} deleted.', actionLabel: 'Undo', onAction: () => repo.restoreEntry(removed)),
      );
    }
  }

  String _preview() {
    try {
      final v = _values();
      final input = NutritionInput(
        servingAmount: v.servingAmount,
        servingUnit: v.servingUnit,
        amount: _opt(_amount, 'Amount'),
        amountUnit: _amountUnit,
        energyKcal: v.energyKcal,
        proteinG: v.proteinG,
        carbsG: v.carbsG,
        fatG: v.fatG,
        fiberG: v.fiberG,
        sugarG: v.sugarG,
        sodiumMg: v.sodiumMg,
        isEstimate: v.isEstimate,
        status: _status,
      );
      if (input.amount == null) return 'Enter the amount to see the values for what you ate.';
      final hasAny = [v.energyKcal, v.proteinG, v.carbsG, v.fatG, v.fiberG, v.sugarG, v.sodiumMg].any((x) => x != null);
      if (!hasAny) return 'No nutrition values entered. The food is still saved.';
      final f = servingFactor(
        servingAmount: v.servingAmount,
        servingUnit: v.servingUnit,
        amount: input.amount,
        amountUnit: _amountUnit,
      );
      if (f == null) {
        return 'Cannot calculate values: the amount unit does not match the serving. '
            'Use "serving" or the serving unit ($_servingUnit).';
      }
      final n = input.eaten;
      final parts = [
        if (n.energyKcal != null) '${fmtNum(n.energyKcal, maxDecimals: 0)} kcal',
        if (n.proteinG != null) 'protein ${fmtNum(n.proteinG)} g',
        if (n.carbsG != null) 'carbs ${fmtNum(n.carbsG)} g',
        if (n.fiberG != null) 'fibre ${fmtNum(n.fiberG)} g',
        if (n.fatG != null) 'fat ${fmtNum(n.fatG)} g',
        if (n.sugarG != null) 'sugar ${fmtNum(n.sugarG)} g',
        if (n.sodiumMg != null) 'sodium ${fmtNum(n.sodiumMg, maxDecimals: 0)} mg',
      ];
      return 'For this amount: ${parts.join(', ')}${v.isEstimate ? ' (estimate)' : ''}.';
    } on FormatException catch (e) {
      return e.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final slots = ref.watch(mealSlotsProvider).value ?? const <MealSlot>[];
    if (_slotId == null && slots.isNotEmpty) {
      // Default to the meal closest to the current time.
      final now = ref.read(clockProvider)();
      final m = now.hour * 60 + now.minute;
      final timed = slots.where((s) => s.usualMinute != null).toList()
        ..sort((a, b) => (a.usualMinute! - m).abs().compareTo((b.usualMinute! - m).abs()));
      _slotId = (timed.isEmpty ? slots.first : timed.first).id;
    }
    final foods = ref.watch(foodsProvider).value ?? const <Food>[];
    final q = _search.text.trim().toLowerCase();
    final matches = q.isEmpty
        ? const <Food>[]
        : foods.where((f) => '${f.name} ${f.brand ?? ''}'.toLowerCase().contains(q)).take(6).toList();
    final diet = ref.watch(currentSettingsProvider).profile.diet;
    // The user's country first, then common foods, then other countries.
    final usda =
        ref.watch(foodLibraryProvider).value?.search(q, country: ref.watch(foodCountryProvider), diet: diet) ??
        const <FoodItem>[];
    final adding = _e == null;
    // Before a search, the last foods logged: most meals repeat.
    final recentFoods = ref.watch(recentFoodsProvider).value ?? const <MealEntry>[];
    final recent = q.isEmpty && _name.text.isEmpty && !_manual ? recentFoods : const <MealEntry>[];
    final settings = ref.watch(currentSettingsProvider);
    // Search first. The long form shows once a food is picked, or when the
    // user asks to type one in (visual review, 2026-10-09).
    final showForm = !adding || _manual || _name.text.isNotEmpty;

    InputDecoration num(String label, String? suffix) =>
        InputDecoration(labelText: label, suffixText: suffix, helperText: null);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(adding ? 'Add food' : 'Edit food', style: t.titleLarge),
          Text(fmtDayLong(parseDayKey(widget.day)), style: t.bodySmall),
          const SizedBox(height: Space.l),
          // Up to four meals fit one segmented row; more fall back to chips.
          if (slots.length <= 4 && slots.any((s) => s.id == _slotId))
            PillTabs<String>(
              values: [for (final s in slots) s.id],
              selected: _slotId!,
              label: (id) => slots.firstWhere((s) => s.id == id).name,
              onChanged: (id) => setState(() => _slotId = id),
            )
          else
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final s in slots)
                  ChoiceChip(
                    label: Text(s.name),
                    selected: _slotId == s.id,
                    onSelected: (_) => setState(() => _slotId = s.id),
                  ),
              ],
            ),
          const SizedBox(height: Space.s),
          PillTabs<MealStatus>(
            values: const [MealStatus.eaten, MealStatus.planned],
            selected: _status,
            label: (s) => s == MealStatus.eaten ? 'Ate it' : 'Plan it',
            icon: (s) => s == MealStatus.eaten ? LucideIcons.check : LucideIcons.clock,
            onChanged: (s) => setState(() => _status = s),
          ),
          if (adding) ...[
            const SizedBox(height: Space.l),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search, size: IconSizes.s),
                labelText: 'Find a food',
                helperText: 'Your foods and a list of common foods, your country first',
              ),
            ),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: Space.s),
              Text('Recent', style: t.labelMedium),
              for (final e in recent)
                ListTile(
                  title: Text(e.name),
                  subtitle: Text(
                    [
                      ?e.brand,
                      if (e.amount != null) fmtWithUnit(e.amount, e.amountUnit),
                      if (e.input.eaten.proteinG case final g?) '${fmtNum(g)} g protein',
                    ].join(' · '),
                  ),
                  trailing: e.isEstimate ? const Tag('Estimate') : null,
                  onTap: () => _useRecent(e),
                ),
            ],
            for (final f in usda)
              ListTile(
                title: Text(f.name),
                subtitle: Text(
                  [
                    '${f.portion} (${fmtNum(f.portionG)} g)',
                    if (settings.showEnergy && f.per100g['kcal'] != null)
                      '${fmtNum(f.per100g['kcal']! * f.portionG / 100, maxDecimals: 0)} kcal',
                    if (f.per100g['protein'] != null) '${fmtNum(f.per100g['protein']! * f.portionG / 100)} g protein',
                  ].join(' · '),
                ),
                trailing: Tag(f.estimate ? 'Estimate' : 'USDA'),
                onTap: () => _useUsda(f),
              ),
            for (final f in matches)
              ListTile(
                title: Text(f.name),
                subtitle: Text(
                  [
                    ?f.brand,
                    if (f.servingAmount != null) 'per ${fmtWithUnit(f.servingAmount, f.servingUnit)}',
                    if (f.energyKcal != null && settings.showEnergy) '${fmtNum(f.energyKcal, maxDecimals: 0)} kcal',
                  ].join(' · '),
                ),
                onTap: () => _useFood(f),
              ),
            if (!showForm) ...[
              const SizedBox(height: Space.s),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _manual = true),
                  icon: const Icon(LucideIcons.pencil, size: IconSizes.s),
                  label: const Text('Can\'t find it? Enter it yourself'),
                ),
              ),
            ],
          ],
          if (showForm) ...[
            const SizedBox(height: Space.l),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 160,
              // The limit stays; the 0/160 counter is noise.
              decoration: const InputDecoration(labelText: 'Food name', counterText: ''),
            ),
            const SizedBox(height: Space.s),
            TextField(
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Brand (optional)'),
            ),
            const SizedBox(height: Space.l),
            Text('Values for one serving (optional)', style: t.labelMedium),
            const SizedBox(height: Space.xs),
            Text('Leave a value empty if you do not know it. Empty is not zero.', style: t.bodySmall),
            const SizedBox(height: Space.s),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _serving,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Serving size', null),
                  ),
                ),
                const SizedBox(width: Space.s),
                DropdownButton<String>(
                  value: _servingUnit,
                  icon: pickerIcon(context),
                  underline: const SizedBox.shrink(),
                  items: [for (final u in _servingUnits) DropdownMenuItem(value: u, child: Text(u))],
                  onChanged: (v) => setState(() => _servingUnit = v!),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kcal,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Energy', 'kcal'),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: TextField(
                    controller: _protein,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Protein', 'g'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _carbs,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Carbs', 'g'),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: TextField(
                    controller: _fat,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Fat', 'g'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fiber,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Fibre', 'g'),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: TextField(
                    controller: _sugar,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Sugar', 'g'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            TextField(
              controller: _sodium,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: num('Sodium', 'mg'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('These values are estimates'),
              value: _estimate,
              onChanged: (v) => setState(() => _estimate = v),
            ),
            const SizedBox(height: Space.s),
            Text('Amount eaten or planned', style: t.labelMedium),
            const SizedBox(height: Space.s),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: num('Amount', null),
                  ),
                ),
                const SizedBox(width: Space.s),
                DropdownButton<String>(
                  value: _amountUnit,
                  icon: pickerIcon(context),
                  underline: const SizedBox.shrink(),
                  items: [for (final u in Units.amountUnits) DropdownMenuItem(value: u, child: Text(u))],
                  onChanged: (v) => setState(() => _amountUnit = v!),
                ),
              ],
            ),
            // Household sizes of a list food: one tap sets the grams.
            if (_portions.length > 1 || (_portions.length == 1 && _portions.first.label != '100 g'))
              Padding(
                padding: const EdgeInsets.only(top: Space.s),
                child: Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    for (final p in _portions)
                      ChoiceChip(
                        label: Text('${p.label} · ${fmtNum(p.grams)} g'),
                        selected: _amountUnit == 'g' && parseDecimal(_amount.text) == p.grams,
                        onSelected: (_) => setState(() {
                          _amount.text = _n(p.grams);
                          _amountUnit = 'g';
                        }),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: Space.m),
            Semantics(
              liveRegion: true,
              child: StatusLine(icon: LucideIcons.info, text: _preview()),
            ),
            const SizedBox(height: Space.xs),
            StatusLine(icon: LucideIcons.fileText, text: 'Source: $_source'),
            if (adding && _foodId == null)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Save to my foods for next time'),
                value: _saveFood,
                onChanged: (v) => setState(() => _saveFood = v ?? false),
              ),
            if (_error != null) ...[
              const SizedBox(height: Space.s),
              Semantics(
                liveRegion: true,
                child: StatusLine(icon: LucideIcons.circleAlert, text: _error!, color: context.pal.error),
              ),
            ],
            const SizedBox(height: Space.l),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving' : 'Save')),
          ],
          if (!adding) ...[
            const SizedBox(height: Space.s),
            TextButton.icon(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: context.pal.error),
              icon: const Icon(LucideIcons.trash2, size: IconSizes.s),
              label: const Text('Delete food from this day'),
            ),
          ],
        ],
      ),
    );
  }
}
