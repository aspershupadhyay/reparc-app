import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import 'meal_entry_sheet.dart';
import 'meal_style.dart';
import 'slots_sheet.dart';

/// Meal tab. Follows the first supplied reference: a day strip, a daily
/// summary, and a timeline of meals with check circles (handbook 3.3).
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

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _day = dayOf(picked));
  }

  @override
  Widget build(BuildContext context) {
    final key = dayKey(_day);
    final entries = ref.watch(mealDayProvider(key));
    final slots = ref.watch(mealSlotsProvider);
    final settings = ref.watch(currentSettingsProvider);
    final today = dayOf(ref.watch(clockProvider)());
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMealEntrySheet(context, day: key),
        backgroundColor: context.pal.action,
        foregroundColor: context.pal.onAction,
        elevation: 2,
        shape: const StadiumBorder(),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Add food'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 120),
          children: [
            ScreenTitle(
              'Meals',
              subtitle: _day == today ? 'Today' : fmtDayLong(_day),
              actions: [
                RoundButton(
                  icon: LucideIcons.slidersHorizontal,
                  tooltip: 'Edit meal times',
                  onPressed: () => showSlotsSheet(context),
                ),
                RoundButton(icon: LucideIcons.calendar, tooltip: 'Choose a date', onPressed: _pickDate),
              ],
            ),
            _DayStrip(selected: _day, today: today, onSelect: (d) => setState(() => _day = d)),
            const SizedBox(height: Space.l),
            AsyncBody(
              value: entries,
              builder: (list) => _Summary(entries: list, showEnergy: settings.showEnergy),
            ),
            const SizedBox(height: Space.l),
            AsyncBody(
              value: slots,
              builder: (slotList) => AsyncBody(
                value: entries,
                builder: (list) => _Timeline(day: key, slots: slotList, entries: list, showEnergy: settings.showEnergy),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seven day pills. The ring on each date shows how much of that day's
/// food is marked as eaten.
class _DayStrip extends ConsumerWidget {
  const _DayStrip({required this.selected, required this.today, required this.onSelect});
  final DateTime selected;
  final DateTime today;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final start = addDays(selected, -3);
    final range = ref.watch(mealRangeProvider((dayKey(start), dayKey(addDays(start, 6))))).value ?? const <MealEntry>[];
    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(
              builder: (context) {
                final d = addDays(start, i);
                final k = dayKey(d);
                final dayEntries = range.where((e) => e.day == k).toList();
                final done = dayEntries.where((e) => e.status == MealStatus.eaten).length;
                final frac = dayEntries.isEmpty ? 0.0 : done / dayEntries.length;
                final isSel = d == selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Semantics(
                    selected: isSel,
                    button: true,
                    label: '${fmtDayLong(d)}${d == today ? ', today' : ''}. $done of ${dayEntries.length} foods eaten',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: () => onSelect(d),
                      child: AnimatedContainer(
                        duration: motionOf(context, Motion.standard),
                        padding: const EdgeInsets.only(top: Space.m, bottom: 4),
                        decoration: BoxDecoration(
                          color: isSel ? p.brand : p.surface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'MTWTFSS'[d.weekday - 1],
                              style: t.labelSmall?.copyWith(color: isSel ? p.onBrand : p.inkSoft),
                            ),
                            const SizedBox(height: Space.s),
                            Container(
                              decoration: BoxDecoration(
                                color: isSel ? p.surface : p.surfaceAlt,
                                shape: BoxShape.circle,
                              ),
                              child: Ring(
                                value: frac,
                                color: isSel ? p.brand : p.green,
                                track: Colors.transparent,
                                size: 40,
                                stroke: 3,
                                semanticLabel: '',
                                child: Text(
                                  d.day.toString().padLeft(2, '0'),
                                  style: t.labelMedium?.tabular.copyWith(color: p.ink),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.entries, required this.showEnergy});
  final List<MealEntry> entries;
  final bool showEnergy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final totals = totalsOf(entries.map((e) => e.input));
    final eaten = entries.where((e) => e.status == MealStatus.eaten).length;
    final e = totals.energyKcal;

    Widget macro(String label, NutrientTotal n, IconData icon, Color color, Color soft) => Expanded(
      child: Semantics(
        label: '$label ${n.value == null ? missingLabel : '${fmtNum(n.value)} grams'}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(Space.m),
          decoration: BoxDecoration(color: soft, borderRadius: Radii.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(label, style: t.labelSmall?.copyWith(color: p.ink), maxLines: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  n.value == null ? missingText : '${fmtNum(n.value, maxDecimals: 0)} g',
                  style: t.titleMedium?.tabular,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return AppCard(
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: showEnergy
                    ? Metric(
                        label: 'Eaten',
                        value: fmtNum(e.value, maxDecimals: 0),
                        unit: e.value == null ? null : 'kcal',
                        semanticValue: e.value == null ? missingLabel : null,
                        large: true,
                        note: e.missing > 0 && e.counted > 0 ? '${e.missing} without kcal' : null,
                      )
                    : Metric(label: 'Eaten', value: '$eaten', unit: eaten == 1 ? 'food' : 'foods', large: true),
              ),
              Ring(
                value: entries.isEmpty ? 0 : eaten / entries.length,
                color: p.brand,
                size: 84,
                stroke: 9,
                semanticLabel: '$eaten of ${entries.length} foods eaten',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$eaten/${entries.length}', style: t.titleMedium?.tabular),
                    Text('done', style: t.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          Row(
            children: [
              macro('Carbs', totals.carbsG, LucideIcons.wheat, p.orange, p.orangeSoft),
              const SizedBox(width: Space.s),
              macro('Protein', totals.proteinG, LucideIcons.beef, p.coral, p.coralSoft),
              const SizedBox(width: Space.s),
              macro('Fat', totals.fatG, LucideIcons.droplet, p.blue, p.blueSoft),
            ],
          ),
          if (totals.estimates > 0) ...[
            const SizedBox(height: Space.m),
            StatusLine(
              icon: LucideIcons.info,
              text: 'Includes ${totals.estimates} estimate${totals.estimates == 1 ? '' : 's'}',
            ),
          ],
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
    final p = context.pal;
    final shownIds = {for (final s in slots) s.id};
    final orphanIds = entries.map((e) => e.slotId).where((id) => !shownIds.contains(id)).toSet();
    return FutureBuilder<List<MealSlot>>(
      future: orphanIds.isEmpty ? Future.value(const []) : ref.read(mealRepoProvider).allSlots(),
      builder: (context, snap) {
        final all = [...slots, ...(snap.data ?? const <MealSlot>[]).where((s) => orphanIds.contains(s.id))]
          ..sort((a, b) => (a.usualMinute ?? 9999).compareTo(b.usualMinute ?? 9999));
        return AppCard(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
          child: Column(
            children: [
              for (final (i, slot) in all.indexed) ...[
                if (i > 0) Divider(indent: 72, color: p.line),
                _SlotGroup(
                  day: day,
                  slot: slot,
                  entries: entries.where((e) => e.slotId == slot.id).toList(),
                  showEnergy: showEnergy,
                  first: i == 0,
                  last: i == all.length - 1,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SlotGroup extends StatelessWidget {
  const _SlotGroup({
    required this.day,
    required this.slot,
    required this.entries,
    required this.showEnergy,
    required this.first,
    required this.last,
  });

  final String day;
  final MealSlot slot;
  final List<MealEntry> entries;
  final bool showEnergy;
  final bool first;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final m = slot.usualMinute;
    final look = slotLook(p, slot);
    String? hour, ampm;
    if (m != null) {
      final h = m ~/ 60, mm = m % 60;
      hour = '${h % 12 == 0 ? 12 : h % 12}:${mm.toString().padLeft(2, '0')}';
      ampm = h < 12 ? 'AM' : 'PM';
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: Space.m),
              child: Column(
                children: [
                  Text(hour ?? '—', style: t.titleSmall?.tabular),
                  if (ampm != null) Text(ampm, style: t.labelSmall),
                ],
              ),
            ),
          ),
          Container(
            width: 1.5,
            color: p.ink.withValues(alpha: 0.75),
            margin: const EdgeInsets.symmetric(horizontal: Space.s),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.s),
              child: Column(
                children: [
                  for (final e in entries) _EntryPill(entry: e, slot: slot, look: look, showEnergy: showEnergy),
                  _AddPill(day: day, slot: slot, look: look, compact: entries.isNotEmpty),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryPill extends ConsumerWidget {
  const _EntryPill({required this.entry, required this.slot, required this.look, required this.showEnergy});
  final MealEntry entry;
  final MealSlot slot;
  final SlotLook look;
  final bool showEnergy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final eaten = entry.status == MealStatus.eaten;
    final n = entry.input.eaten;
    final sub = showEnergy
        ? (n.energyKcal == null
              ? fmtWithUnit(entry.amount, entry.amountUnit)
              : '${fmtNum(n.energyKcal, maxDecimals: 0)} kcal')
        : fmtWithUnit(entry.amount, entry.amountUnit);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Material(
        color: look.soft,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => showMealEntrySheet(context, day: entry.day, existing: entry),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Row(
              children: [
                IconBadge(look.icon, color: look.color, size: 44),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        '$sub${entry.isEstimate ? ' · est.' : ''}${eaten ? '' : ' · planned'}',
                        style: t.bodySmall?.copyWith(color: p.ink.withValues(alpha: 0.7)),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Semantics(
                  label: '${entry.name} eaten',
                  checked: eaten,
                  button: true,
                  excludeSemantics: true,
                  child: InkResponse(
                    radius: 26,
                    onTap: () => guardedWrite(
                      context,
                      () =>
                          ref.read(mealRepoProvider).setStatus(entry.id, eaten ? MealStatus.planned : MealStatus.eaten),
                    ),
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: motionOf(context, Motion.quick),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: eaten ? look.color : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: look.color, width: 2),
                          ),
                          child: eaten ? Icon(LucideIcons.check, size: 16, color: p.on(look.color)) : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.day, required this.slot, required this.look, required this.compact});
  final String day;
  final MealSlot slot;
  final SlotLook look;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Material(
        color: Colors.transparent,
        shape: StadiumBorder(side: BorderSide(color: look.color.withValues(alpha: 0.45), width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => showMealEntrySheet(context, day: day, slotId: slot.id),
          child: Padding(
            padding: EdgeInsets.all(compact ? 4 : 6),
            child: Row(
              children: [
                compact
                    ? SizedBox.square(dimension: 36, child: Icon(LucideIcons.plus, size: 18, color: look.color))
                    : IconBadge(look.icon, color: look.soft, glyph: look.color, size: 44),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text(
                    compact ? 'Add to ${slot.name.toLowerCase()}' : slot.name,
                    style: compact ? t.labelMedium?.copyWith(color: p.inkSoft) : t.titleSmall,
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.m),
                    child: Icon(LucideIcons.plus, color: look.color),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
