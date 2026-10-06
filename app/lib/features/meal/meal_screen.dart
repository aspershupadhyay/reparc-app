import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../domain/targets.dart';
import 'meal_entry_sheet.dart';
import 'plan_day_sheet.dart';
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
              builder: (list) =>
                  _Summary(entries: list, showEnergy: settings.showEnergy, targets: settings.targets, day: key),
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

/// Today's eating against the user's own targets. Protein, carbs, fibre,
/// and fat always show; sugar and salt show as limits. Without targets it
/// shows totals and a way to set targets (handbook 5.5: never by default).
class _Summary extends StatelessWidget {
  const _Summary({required this.entries, required this.showEnergy, required this.targets, required this.day});
  final List<MealEntry> entries;
  final bool showEnergy;
  final List<Target> targets;
  final String day;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final totals = totalsOf(entries.map((e) => e.input));
    final planned = plannedTotalsOf(entries.map((e) => e.input));
    final eaten = entries.where((e) => e.status == MealStatus.eaten).length;
    final byN = {for (final x in targets) x.nutrient: x};
    final e = totals.energyKcal;
    final eTarget = byN[Nutrient.energy];

    Widget bar(Nutrient n, Color color) {
      final v = totals.of(n);
      final target = byN[n];
      final frac = target?.progress(v.value);
      final valueText = v.value == null ? missingText : fmtNum(v.value, maxDecimals: 0);
      final text = target == null
          ? '$valueText ${n.unit}'
          : '$valueText / ${fmtNum(target.amount, maxDecimals: 0)} ${n.unit}';
      return Semantics(
        label:
            '${n.label}: ${v.value == null ? missingLabel : '${fmtNum(v.value)} ${n.unit}'}'
            '${target == null ? '' : ' of ${fmtNum(target.amount)} target'}'
            '${v.missing > 0 && v.counted > 0 ? '. ${v.missing} foods have no value' : ''}',
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: Space.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(n.label, style: t.labelMedium)),
                  Text(text, style: t.labelMedium?.tabular),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: frac == null ? 0 : frac.clamp(0.0, 1.0),
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
              if (v.missing > 0 && v.counted > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('${v.missing} food${v.missing == 1 ? '' : 's'} without a value', style: t.labelSmall),
                ),
            ],
          ),
        ),
      );
    }

    String limitText(Nutrient n) {
      final v = totals.of(n).value;
      final target = byN[n];
      final unit = n.unit;
      final value = v == null ? missingText : '${fmtNum(v, maxDecimals: 0)} $unit';
      return target == null ? value : '$value (under ${fmtNum(target.amount, maxDecimals: 0)})';
    }

    final plannedProtein = planned.proteinG.value;
    return AppCard(
      padding: const EdgeInsets.all(Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: showEnergy
                    ? Metric(
                        label: eTarget == null ? 'Eaten' : 'Eaten of ${fmtNum(eTarget.amount, maxDecimals: 0)} kcal',
                        value: fmtNum(e.value, maxDecimals: 0),
                        unit: e.value == null ? null : 'kcal',
                        semanticValue: e.value == null ? missingLabel : null,
                        large: true,
                        note: e.missing > 0 && e.counted > 0 ? '${e.missing} without kcal' : null,
                      )
                    : Metric(label: 'Eaten', value: '$eaten', unit: eaten == 1 ? 'food' : 'foods', large: true),
              ),
              Ring(
                value: showEnergy && eTarget != null
                    ? (eTarget.progress(e.value) ?? 0)
                    : (entries.isEmpty ? 0 : eaten / entries.length),
                color: p.brand,
                size: 76,
                stroke: 8,
                semanticLabel: showEnergy && eTarget != null
                    ? 'Energy: ${((eTarget.progress(e.value) ?? 0) * 100).round()}% of target'
                    : '$eaten of ${entries.length} foods eaten',
                child: Text(
                  showEnergy && eTarget != null
                      ? '${((eTarget.progress(e.value) ?? 0) * 100).round()}%'
                      : '$eaten/${entries.length}',
                  style: t.titleSmall?.tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          bar(Nutrient.protein, p.coral),
          bar(Nutrient.carbs, p.amber),
          bar(Nutrient.fiber, p.green),
          bar(Nutrient.fat, p.blue),
          Row(
            children: [
              Expanded(
                child: Text('Sugar: ${limitText(Nutrient.sugar)}', style: t.bodySmall),
              ),
              Expanded(
                child: Text('Salt: ${limitText(Nutrient.sodium)}', style: t.bodySmall, textAlign: TextAlign.end),
              ),
            ],
          ),
          if (plannedProtein != null && plannedProtein > 0) ...[
            const SizedBox(height: Space.s),
            StatusLine(
              icon: LucideIcons.clock,
              text:
                  'Planned, not eaten yet: ${fmtNum(plannedProtein, maxDecimals: 0)} g protein'
                  '${planned.energyKcal.value != null && showEnergy ? ', ${fmtNum(planned.energyKcal.value, maxDecimals: 0)} kcal' : ''}.',
            ),
          ],
          if (totals.estimates > 0) ...[
            const SizedBox(height: Space.s),
            StatusLine(
              icon: LucideIcons.info,
              text: 'Includes ${totals.estimates} estimate${totals.estimates == 1 ? '' : 's'}',
            ),
          ],
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showPlanDaySheet(context, day: day),
                  icon: const Icon(LucideIcons.wandSparkles, size: 18),
                  label: const Text('Plan my day'),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/me/body'),
                  icon: Icon(targets.isEmpty ? LucideIcons.target : LucideIcons.slidersHorizontal, size: 18),
                  label: Text(targets.isEmpty ? 'Set targets' : 'Targets'),
                ),
              ),
            ],
          ),
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
    final sub = [
      showEnergy && n.energyKcal != null
          ? '${fmtNum(n.energyKcal, maxDecimals: 0)} kcal'
          : fmtWithUnit(entry.amount, entry.amountUnit),
      if (n.proteinG != null) '${fmtNum(n.proteinG, maxDecimals: 0)} g protein',
    ].join(' · ');
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
