import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import 'meal_entry_sheet.dart';
import 'slots_sheet.dart';

/// Meal tab. Layout follows the first supplied reference: day selector,
/// daily summary, and a meal timeline with cards (handbook 3.3).
class MealScreen extends ConsumerStatefulWidget {
  const MealScreen({super.key, this.initialDay});
  final String? initialDay;

  @override
  ConsumerState<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends ConsumerState<MealScreen> {
  late DateTime _day = widget.initialDay == null ? dayOf(ref.read(clockProvider)()) : parseDayKey(widget.initialDay!);

  @override
  void didUpdateWidget(MealScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialDay != null && widget.initialDay != old.initialDay) {
      _day = parseDayKey(widget.initialDay!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final key = dayKey(_day);
    final entries = ref.watch(mealDayProvider(key));
    final slots = ref.watch(mealSlotsProvider);
    final settings = ref.watch(currentSettingsProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(header: true, child: Text('Meal', style: t.headlineSmall)),
                ),
                IconButton(
                  tooltip: 'Edit meal slots',
                  onPressed: () => showSlotsSheet(context),
                  icon: const Icon(LucideIcons.settings),
                ),
                IconButton(
                  tooltip: 'Choose a date',
                  onPressed: () async {
                    final now = ref.read(clockProvider)();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _day,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(now.year + 2),
                    );
                    if (picked != null) setState(() => _day = dayOf(picked));
                  },
                  icon: const Icon(LucideIcons.calendarDays),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            _DayStrip(selected: _day, onSelect: (d) => setState(() => _day = d)),
            const SizedBox(height: Space.l),
            AsyncBody(
              value: entries,
              builder: (list) => _Summary(entries: list, showEnergy: settings.showEnergy, day: _day),
            ),
            AsyncBody(
              value: slots,
              builder: (slotList) => AsyncBody(
                value: entries,
                builder: (list) => _Timeline(
                  day: key,
                  slots: slotList,
                  entries: list,
                  showEnergy: settings.showEnergy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven days around the selected day.
class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.selected, required this.onSelect});
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final today = dayOf(ref.watch(clockProvider)());
    final start = addDays(selected, -3);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                selected == today ? 'Today, ${fmtDayMonth(selected)}' : fmtDayLong(selected),
                style: t.titleSmall,
              ),
            ),
            if (selected != today) TextButton(onPressed: () => onSelect(today), child: const Text('Today')),
          ],
        ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final d = addDays(start, i);
                    final isSel = d == selected;
                    return Semantics(
                      selected: isSel,
                      button: true,
                      label: '${fmtDayLong(d)}${d == today ? ', today' : ''}',
                      excludeSemantics: true,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Material(
                          color: isSel ? AppColors.ink : AppColors.surface,
                          shape: StadiumBorder(
                            side: BorderSide(color: d == today && !isSel ? AppColors.ink : AppColors.border),
                          ),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: () => onSelect(d),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 64),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'MTWTFSS'[d.weekday - 1],
                                    style: t.labelSmall?.copyWith(
                                      color: isSel ? AppColors.border : AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: Space.xs),
                                  Text(
                                    '${d.day}',
                                    style: t.titleSmall?.tabular.copyWith(
                                      color: isSel ? AppColors.lime : AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.entries, required this.showEnergy, required this.day});
  final List<MealEntry> entries;
  final bool showEnergy;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final totals = totalsOf(entries.map((e) => e.input));
    final planned = entries.where((e) => e.status == MealStatus.planned).length;
    final notes = <String>[
      if (totals.entries == 0) 'No food marked as eaten on this day.',
      if (planned > 0) '$planned planned food${planned == 1 ? '' : 's'} not counted until marked as eaten.',
      if (totals.estimates > 0) 'Includes ${totals.estimates} estimated value${totals.estimates == 1 ? '' : 's'}.',
    ];
    String? missingNote(NutrientTotal n) => n.missing == 0 || n.counted == 0 ? null : '${n.missing} without value';

    Widget macro(String label, NutrientTotal n, Color color) => Expanded(
      child: AppCard(
        color: color,
        border: false,
        padding: const EdgeInsets.all(Space.m),
        child: Metric(
          label: label,
          value: fmtNum(n.value, maxDecimals: 1),
          unit: n.value == null ? null : 'g',
          semanticValue: n.value == null ? missingLabel : null,
          note: missingNote(n),
        ),
      ),
    );

    return AppCard(
      color: AppColors.softSurface,
      border: false,
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showEnergy) ...[
            Metric(
              label: 'Energy eaten',
              value: fmtNum(totals.energyKcal.value, maxDecimals: 0),
              unit: totals.energyKcal.value == null ? null : 'kcal',
              semanticValue: totals.energyKcal.value == null ? missingLabel : null,
              large: true,
              note: missingNote(totals.energyKcal) == null
                  ? null
                  : '${totals.energyKcal.missing} food${totals.energyKcal.missing == 1 ? ' has' : 's have'} no energy value. The total is partial.',
            ),
            const SizedBox(height: Space.m),
          ],
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                macro('Carbs', totals.carbsG, AppColors.surface),
                const SizedBox(width: Space.s),
                macro('Protein', totals.proteinG, AppColors.surface),
                const SizedBox(width: Space.s),
                macro('Fat', totals.fatG, AppColors.surface),
              ],
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: Space.m),
            for (final n in notes)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.xs),
                child: StatusLine(icon: LucideIcons.info, text: n),
              ),
          ],
          const SizedBox(height: Space.xs),
          Text('Values come from your entries. Source: $sourceManual.', style: t.bodySmall),
        ],
      ),
    );
  }
}

class _Timeline extends ConsumerWidget {
  const _Timeline({required this.day, required this.slots, required this.entries, required this.showEnergy});
  final String day;
  final List<MealSlot> slots;
  final List<MealEntry> entries;
  final bool showEnergy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show archived slots only when they still hold entries for this day.
    final shownIds = {for (final s in slots) s.id};
    final orphanIds = entries.map((e) => e.slotId).where((id) => !shownIds.contains(id)).toSet();
    return FutureBuilder<List<MealSlot>>(
      future: orphanIds.isEmpty ? Future.value(const []) : ref.read(mealRepoProvider).allSlots(),
      builder: (context, snap) {
        final extra = (snap.data ?? const <MealSlot>[]).where((s) => orphanIds.contains(s.id));
        final all = [...slots, ...extra];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Meals'),
            for (final slot in all)
              _SlotRow(
                day: day,
                slot: slot,
                entries: entries.where((e) => e.slotId == slot.id).toList(),
                showEnergy: showEnergy,
              ),
          ],
        );
      },
    );
  }
}

class _SlotRow extends ConsumerWidget {
  const _SlotRow({required this.day, required this.slot, required this.entries, required this.showEnergy});
  final String day;
  final MealSlot slot;
  final List<MealEntry> entries;
  final bool showEnergy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final m = slot.usualMinute;
    final time = m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);
    final totals = totalsOf(entries.map((e) => e.input));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: Space.l),
              child: Text(time ?? '', style: t.labelSmall?.copyWith(color: AppColors.secondaryText)),
            ),
          ),
          Container(
            width: 1,
            color: AppColors.border,
            margin: const EdgeInsets.only(right: Space.m),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.name, style: t.titleMedium),
                              if (entries.isNotEmpty && showEnergy && totals.energyKcal.value != null)
                                Text(
                                  '${fmtNum(totals.energyKcal.value, maxDecimals: 0)} kcal eaten'
                                  '${totals.energyKcal.missing > 0 ? ' (partial)' : ''}',
                                  style: t.bodySmall,
                                ),
                              if (entries.isEmpty) Text('Nothing planned or logged', style: t.bodySmall),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          tooltip: 'Add food to ${slot.name}',
                          style: IconButton.styleFrom(backgroundColor: AppColors.lime, foregroundColor: AppColors.ink),
                          onPressed: () => showMealEntrySheet(context, day: day, slotId: slot.id),
                          icon: const Icon(LucideIcons.plus),
                        ),
                      ],
                    ),
                    for (final e in entries) _EntryTile(entry: e, showEnergy: showEnergy),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.showEnergy});
  final MealEntry entry;
  final bool showEnergy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final eaten = entry.status == MealStatus.eaten;
    final n = entry.input.eaten;
    final amount = fmtWithUnit(entry.amount, entry.amountUnit, maxDecimals: 2);
    final energy = !showEnergy
        ? null
        : n.energyKcal == null
        ? 'Energy not recorded'
        : '${fmtNum(n.energyKcal, maxDecimals: 0)} kcal${entry.isEstimate ? ' (estimate)' : ''}';
    return AnimatedSize(
      duration: motionOf(context, Motion.standard),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: Radii.small,
              onTap: () => showMealEntrySheet(context, day: entry.day, existing: entry),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: t.bodyLarge?.weight(FontWeight.w600)),
                    Text(
                      [amount, ?energy, if (!eaten) 'Planned'].join(' · '),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            label: '${entry.name} eaten',
            checked: eaten,
            button: true,
            excludeSemantics: true,
            child: IconButton(
              tooltip: eaten ? 'Mark as planned, not eaten' : 'Mark as eaten',
              style: IconButton.styleFrom(
                backgroundColor: eaten ? AppColors.ink : AppColors.surface,
                side: const BorderSide(color: AppColors.border),
              ),
              onPressed: () => guardedWrite(
                context,
                () => ref.read(mealRepoProvider).setStatus(entry.id, eaten ? MealStatus.planned : MealStatus.eaten),
              ),
              icon: Icon(
                eaten ? LucideIcons.check : LucideIcons.circle,
                color: eaten ? AppColors.lime : AppColors.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
