import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/program_repository.dart';
import '../../data/providers.dart';
import '../../domain/roadmap.dart';
import '../exercises/library/library.dart';
import '../exercises/library/move_browser.dart';

IconData goalIcon(RoadmapGoal g) => switch (g) {
  RoadmapGoal.aesthetic => LucideIcons.sparkles,
  RoadmapGoal.bodybuilding => LucideIcons.dumbbell,
  RoadmapGoal.strength => LucideIcons.weight,
  RoadmapGoal.calisthenics => LucideIcons.personStanding,
  RoadmapGoal.leanFit => LucideIcons.flame,
};

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _rest(int? s) => s == null
    ? ''
    : s >= 60
    ? '${s ~/ 60}${s % 60 == 0 ? '' : ':${(s % 60).toString().padLeft(2, '0')}'} min rest'
    : '$s s rest';

/// Starts the session for one roadmap day and opens the live workout.
Future<void> startRoadmapDay(BuildContext context, WidgetRef ref, String programId, int day) async {
  final repo = ref.read(workoutRepoProvider);
  final live = await repo.liveSession();
  if (!context.mounted) return;
  if (live != null) {
    showMessage(context, 'Finish the workout in progress first.');
    await context.push('/live/${live.id}');
    return;
  }
  final id = await guardedWrite(context, () => repo.startProgramDay(programId: programId, dayIndex: day));
  if (id != null && context.mounted) await context.push('/live/$id');
}

/// Roadmap section of the Workout tab.
class RoadmapSection extends ConsumerWidget {
  const RoadmapSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(activeProgramProvider),
      builder: (prog) => prog == null ? const _ChooseGoal() : _ActiveRoadmap(prog: prog),
    );
  }
}

class _ChooseGoal extends StatelessWidget {
  const _ChooseGoal();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final colors = [p.coral, p.blue, p.orange, p.green, p.brand];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What do you want to work towards?', style: t.titleLarge),
        const SizedBox(height: Space.xs),
        Text(
          'Pick a roadmap. You choose the level, days, and equipment next, and you can change any part later.',
          style: t.bodyMedium?.copyWith(color: p.inkSoft),
        ),
        const SizedBox(height: Space.l),
        for (final (i, g) in RoadmapGoal.values.indexed) ...[
          AppCard(
            onTap: () => context.push('/workout/roadmap/new?goal=${g.name}'),
            semanticLabel: '${g.label}. ${g.summary}',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  IconBadge(goalIcon(g), color: colors[i].withValues(alpha: 0.15), glyph: colors[i], size: 48),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(g.label, style: t.titleMedium),
                        Text(g.summary, style: t.bodySmall),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.s),
        ],
      ],
    );
  }
}

class _ActiveRoadmap extends ConsumerWidget {
  const _ActiveRoadmap({required this.prog});
  final SavedProgram prog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final plan = prog.plan;
    final next = plan.days.isEmpty ? null : plan.days[prog.nextDay];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(Space.xl),
          decoration: BoxDecoration(color: p.panel, borderRadius: Radii.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(goalIcon(plan.goal), color: p.energy, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${plan.title} · ${plan.setup.label}',
                      style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.s),
              Text('Next: ${next?.name ?? '—'}', style: t.titleLarge?.copyWith(color: p.onPanel)),
              if (next != null)
                Text(
                  '${next.focus} · ${next.work.length} exercises · about ${next.minutes} min',
                  style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                ),
              const SizedBox(height: Space.l),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: p.energy, foregroundColor: p.onEnergy),
                      onPressed: next == null
                          ? null
                          : () => context.push('/workout/roadmap/${prog.id}/day/${prog.nextDay}'),
                      icon: const Icon(LucideIcons.play, size: 20),
                      label: const Text('Warm up and start'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SectionHeader(
          'This week',
          action: TextButton.icon(
            onPressed: () => showAppSheet<void>(context, (_) => _RoadmapSettings(prog: prog)),
            icon: const Icon(LucideIcons.slidersHorizontal, size: 18),
            label: const Text('Customize'),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, d) in plan.days.indexed) ...[
                if (i > 0) const Divider(indent: 72),
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == prog.nextDay ? p.energy : p.surfaceAlt,
                      borderRadius: Radii.small,
                    ),
                    child: Text(
                      i < plan.weekdays.length ? _dayNames[(plan.weekdays[i] - 1) % 7] : 'D${i + 1}',
                      style: t.labelMedium?.copyWith(color: i == prog.nextDay ? p.onEnergy : p.ink),
                    ),
                  ),
                  title: Text(d.name),
                  subtitle: Text('${d.focus} · ${d.workSets} sets · ~${d.minutes} min'),
                  trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                  onTap: () => context.push('/workout/roadmap/${prog.id}/day/$i'),
                ),
              ],
            ],
          ),
        ),
        if (plan.showNotes) ...[
          const SectionHeader('How to progress'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusLine(icon: LucideIcons.trendingUp, text: plan.progression, color: p.ink),
                const SizedBox(height: Space.m),
                StatusLine(icon: LucideIcons.batteryCharging, text: plan.deload, color: p.ink),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.m),
        const StatusLine(
          icon: LucideIcons.info,
          text: 'General training guidance for healthy adults. Not medical advice. Stop if you feel sharp pain.',
        ),
      ],
    );
  }
}

/// What the user sees in the roadmap, training days, and stop.
class _RoadmapSettings extends ConsumerWidget {
  const _RoadmapSettings({required this.prog});
  final SavedProgram prog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final live = ref.watch(programProvider(prog.id)).value ?? prog;
    final plan = live.plan;
    final repo = ref.read(programRepoProvider);
    Future<void> save(ProgramPlan next) => guardedWrite(context, () => repo.save(prog.id, next));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Customize roadmap', style: t.titleLarge),
          const SizedBox(height: Space.m),
          Text('Show on each day', style: t.labelMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Warm-up'),
            value: plan.showWarmup,
            onChanged: (v) => save(plan.copyWith(showWarmup: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cool-down stretches'),
            value: plan.showCooldown,
            onChanged: (v) => save(plan.copyWith(showCooldown: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Progress tips'),
            value: plan.showNotes,
            onChanged: (v) => save(plan.copyWith(showNotes: v)),
          ),
          const SizedBox(height: Space.s),
          Text('Training days (${plan.days.length} a week)', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(_dayNames[d - 1]),
                  selected: plan.weekdays.contains(d),
                  onSelected: (on) {
                    final next = {...plan.weekdays};
                    on ? next.add(d) : next.remove(d);
                    if (next.length != plan.days.length) {
                      showMessage(context, 'Pick ${plan.days.length} days, one for each roadmap day.');
                    }
                    save(plan.copyWith(weekdays: next.toList()..sort()));
                  },
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          Text('Next day to train', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final (i, d) in plan.days.indexed)
                ChoiceChip(
                  label: Text(d.name),
                  selected: live.nextDay == i,
                  onSelected: (_) => guardedWrite(context, () => repo.setNextDay(prog.id, i)),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/workout/roadmap/new?goal=${plan.goal.name}');
            },
            icon: const Icon(LucideIcons.refreshCw, size: IconSizes.s),
            label: const Text('Build a new roadmap'),
          ),
          const SizedBox(height: Space.s),
          TextButton(
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Stop this roadmap?',
                body: 'It stays saved with your workout history. You can pick a new roadmap any time.',
                confirmLabel: 'Stop',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await guardedWrite(context, () => repo.stop(prog.id));
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: context.pal.error),
            child: const Text('Stop following this roadmap'),
          ),
        ],
      ),
    );
  }
}

/// Build a roadmap: goal, level, days, equipment, then a preview.
class RoadmapBuilderScreen extends ConsumerStatefulWidget {
  const RoadmapBuilderScreen({super.key, this.goal});
  final RoadmapGoal? goal;

  @override
  ConsumerState<RoadmapBuilderScreen> createState() => _RoadmapBuilderScreenState();
}

class _RoadmapBuilderScreenState extends ConsumerState<RoadmapBuilderScreen> {
  late RoadmapGoal _goal = widget.goal ?? RoadmapGoal.aesthetic;
  RoadmapLevel _level = RoadmapLevel.beginner;
  GymSetup _setup = GymSetup.fullGym;
  late int _days = _goal.defaultDays(_level);
  bool _saving = false;

  void _fixDays() {
    if (!_goal.dayOptions.contains(_days)) _days = _goal.defaultDays(_level);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final plan = buildProgram(goal: _goal, level: _level, setup: _setup, days: _days);
    return Scaffold(
      appBar: AppBar(title: const Text('New roadmap')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
          child: FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    setState(() => _saving = true);
                    final id = await guardedWrite(
                      context,
                      () => ref.read(programRepoProvider).adopt(plan),
                      success: 'Roadmap saved. You can change any part of it.',
                    );
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    if (id != null) context.pop();
                  },
            child: const Text('Use this roadmap'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text('Goal', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final g in RoadmapGoal.values)
                ChoiceChip(
                  avatar: Icon(goalIcon(g), size: 16),
                  label: Text(g.label),
                  selected: _goal == g,
                  onSelected: (_) => setState(() {
                    _goal = g;
                    _days = g.defaultDays(_level);
                  }),
                ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text(_goal.summary, style: t.bodySmall),
          const SizedBox(height: Space.l),
          Text('Level', style: t.labelMedium),
          const SizedBox(height: Space.s),
          PillTabs<RoadmapLevel>(
            values: RoadmapLevel.values,
            selected: _level,
            label: (l) => l.label,
            onChanged: (l) => setState(() {
              _level = l;
              _days = _goal.defaultDays(l);
            }),
          ),
          const SizedBox(height: Space.xs),
          Text(_level.hint, style: t.bodySmall),
          const SizedBox(height: Space.l),
          Text('Days a week', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            children: [
              for (final d in _goal.dayOptions)
                ChoiceChip(
                  label: Text('$d'),
                  selected: _days == d,
                  onSelected: (_) => setState(() {
                    _days = d;
                    _fixDays();
                  }),
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          Text('Where you train', style: t.labelMedium),
          const SizedBox(height: Space.s),
          for (final s in GymSetup.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: AppCard(
                onTap: () => setState(() => _setup = s),
                semanticLabel: '${s.label}. ${s.hint}${_setup == s ? '. Selected' : ''}',
                padding: const EdgeInsets.all(Space.m),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(
                        _setup == s ? LucideIcons.circleCheck : LucideIcons.circle,
                        color: _setup == s ? p.brand : p.inkSoft,
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.label, style: t.titleSmall),
                            Text(s.hint, style: t.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SectionHeader('Your week'),
          for (final (i, d) in plan.days.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Tag(_dayNames[(plan.weekdays[i] - 1) % 7], color: p.brandSoft),
                        const SizedBox(width: Space.s),
                        Expanded(child: Text(d.name, style: t.titleMedium)),
                        Text('~${d.minutes} min', style: t.bodySmall),
                      ],
                    ),
                    const SizedBox(height: Space.xs),
                    Text('Warm-up, then:', style: t.bodySmall),
                    for (final it in d.work)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('• ${it.name}  ${it.target}', style: t.bodyMedium),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: Space.s),
          StatusLine(icon: LucideIcons.trendingUp, text: plan.progression),
        ],
      ),
    );
  }
}

/// One roadmap day: warm-up, exercises with targets, cool-down. Every part
/// can be edited. Start opens a live workout with these exercises.
class RoadmapDayScreen extends ConsumerWidget {
  const RoadmapDayScreen({super.key, required this.programId, required this.day});
  final String programId;
  final int day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final prog = ref.watch(programProvider(programId)).value;
    if (prog == null || day >= prog.plan.days.length) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final plan = prog.plan;
    final d = plan.days[day];
    final repo = ref.read(programRepoProvider);

    Future<void> saveDay(PlanDay next) {
      final days = [...plan.days]..[day] = next;
      return guardedWrite(context, () => repo.save(programId, plan.copyWith(days: days)));
    }

    Future<void> editItem(int index) async {
      final result = await showAppSheet<_ItemEdit>(context, (_) => _ItemSheet(item: d.items[index]));
      if (result == null || !context.mounted) return;
      final items = [...d.items];
      if (result.remove) {
        final removed = items.removeAt(index);
        await saveDay(d.copyWith(items: items));
        if (context.mounted) {
          showMessage(
            context,
            '${removed.name} removed.',
            actionLabel: 'Undo',
            onAction: () => saveDay(d.copyWith(items: [...items]..insert(index, removed))),
          );
        }
        return;
      }
      if (result.moveBy != 0) {
        final to = index + result.moveBy;
        if (to < 0 || to >= items.length) return;
        final it = items.removeAt(index);
        items.insert(to, it);
      } else {
        items[index] = result.item!;
      }
      await saveDay(d.copyWith(items: items));
    }

    Future<void> addExercise() async {
      final m = await pickMove(context);
      if (m == null || !context.mounted) return;
      final items = [...d.items];
      final at = items.lastIndexWhere((i) => i.kind != ItemKind.cooldown) + 1;
      items.insert(
        at,
        PlanItem(
          kind: ItemKind.accessory,
          exerciseId: m.catalogId,
          name: m.name,
          sets: 3,
          repsLow: 10,
          repsHigh: 12,
          restSec: 90,
          rir: 2,
        ),
      );
      await saveDay(d.copyWith(items: items));
    }

    Widget section(String title, Iterable<(int, PlanItem)> rows) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (n, (i, it)) in rows.indexed) ...[
                if (n > 0) const Divider(indent: Space.l),
                _ItemRow(item: it, onTap: () => editItem(i)),
              ],
            ],
          ),
        ),
      ],
    );

    final indexed = d.items.indexed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(d.name),
        actions: [
          IconButton(
            tooltip: 'Rename day',
            icon: const Icon(LucideIcons.pencil),
            onPressed: () async {
              final name = await promptText(context, title: 'Rename day', label: 'Day name', initial: d.name);
              if (name != null) await saveDay(d.copyWith(name: name));
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: p.energy, foregroundColor: p.onEnergy),
            onPressed: d.work.isEmpty ? null : () => startRoadmapDay(context, ref, programId, day),
            icon: const Icon(LucideIcons.play, size: 20),
            label: const Text('Start workout'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          Text(
            '${d.focus} · ${d.workSets} sets · about ${d.minutes} min',
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          if (plan.showWarmup && d.warmup.isNotEmpty) ...[
            section('1. Warm-up (about 8 min)', indexed.where((e) => e.$2.kind == ItemKind.warmup)),
            const SizedBox(height: Space.s),
            const StatusLine(
              icon: LucideIcons.flame,
              text:
                  'Then do 2–3 lighter sets of the first lift (about 50%, 70%, and 85% of your working weight). '
                  'They are already in your workout as warm-up sets.',
            ),
          ],
          section(
            plan.showWarmup ? '2. Workout' : 'Workout',
            indexed.where((e) => e.$2.kind != ItemKind.warmup && e.$2.kind != ItemKind.cooldown),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: addExercise,
              icon: const Icon(LucideIcons.plus, size: IconSizes.s),
              label: const Text('Add exercise'),
            ),
          ),
          if (plan.showCooldown && d.cooldown.isNotEmpty)
            section('3. Cool-down', indexed.where((e) => e.$2.kind == ItemKind.cooldown)),
          const SizedBox(height: Space.m),
          const StatusLine(
            icon: LucideIcons.info,
            text: 'Tap any exercise to change sets, reps, rest, or swap it for one that fits your gym.',
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});
  final PlanItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final details = [
      if (item.target.isNotEmpty) item.target,
      if (item.kind == ItemKind.warmup && item.repsLow != null && item.sets == 1) '${item.repsLow} reps',
      if (item.restSec != null && item.kind != ItemKind.warmup) _rest(item.restSec),
      if (item.rir != null) item.rir == 0 ? 'to failure' : '${item.rir} reps left',
    ].where((s) => s.isNotEmpty).toSet().join(' · ');
    return Semantics(
      button: true,
      label: '${item.name}. ${item.kind.label}. $details. Edit',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(item.name, style: t.titleSmall)),
                        if (item.rampUp) ...[
                          const SizedBox(width: Space.s),
                          Tag('Ramp up', color: p.orangeSoft),
                        ],
                      ],
                    ),
                    if (details.isNotEmpty) Text(details, style: t.bodySmall),
                    if (item.note != null) Text(item.note!, style: t.bodySmall?.copyWith(color: p.brand)),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemEdit {
  const _ItemEdit.save(PlanItem this.item) : remove = false, moveBy = 0;
  const _ItemEdit.remove() : item = null, remove = true, moveBy = 0;
  const _ItemEdit.move(this.moveBy) : item = null, remove = false;
  final PlanItem? item;
  final bool remove;
  final int moveBy;
}

class _ItemSheet extends ConsumerStatefulWidget {
  const _ItemSheet({required this.item});
  final PlanItem item;

  @override
  ConsumerState<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends ConsumerState<_ItemSheet> {
  late PlanItem _it = widget.item;

  Widget _stepper(
    String label,
    int? value,
    int min,
    int max,
    ValueChanged<int> onChanged, {
    String unit = '',
    int step = 1,
  }) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: t.bodyLarge)),
        IconButton(
          tooltip: 'Less $label',
          onPressed: value == null || value <= min ? null : () => onChanged(value - step),
          icon: const Icon(LucideIcons.minus),
        ),
        SizedBox(
          width: 64,
          child: Text(value == null ? '—' : '$value$unit', textAlign: TextAlign.center, style: t.titleMedium),
        ),
        IconButton(
          tooltip: 'More $label',
          onPressed: value != null && value >= max ? null : () => onChanged(value == null ? min : value + step),
          icon: const Icon(LucideIcons.plus),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final alts = alternativesFor(_it).where((a) => a.$1 != _it.exerciseId).toList();
    final timed = _it.seconds != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_it.name, style: t.titleLarge),
          Text(_it.kind.label, style: t.bodySmall),
          const SizedBox(height: Space.m),
          _stepper('Sets', _it.sets, 1, 10, (v) => setState(() => _it = _it.copyWith(sets: v))),
          if (timed)
            _stepper(
              'Time',
              _it.seconds,
              15,
              3600,
              (v) => setState(() => _it = _it.copyWith(seconds: v)),
              unit: ' s',
              step: 15,
            )
          else ...[
            _stepper('Fewest reps', _it.repsLow, 1, 50, (v) {
              setState(() => _it = _it.copyWith(repsLow: v, repsHigh: (_it.repsHigh ?? v) < v ? v : _it.repsHigh));
            }),
            _stepper('Most reps', _it.repsHigh ?? _it.repsLow, _it.repsLow ?? 1, 50, (v) {
              setState(() => _it = _it.copyWith(repsHigh: v));
            }),
          ],
          if (_it.kind != ItemKind.warmup && _it.kind != ItemKind.cooldown) ...[
            _stepper('Reps left in the tank', _it.rir, 0, 5, (v) => setState(() => _it = _it.copyWith(rir: v))),
            const SizedBox(height: Space.s),
            Text('Rest between sets', style: t.labelMedium),
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.s,
              children: [
                for (final s in const [45, 60, 90, 120, 180, 240])
                  ChoiceChip(
                    label: Text(s < 60 ? '$s s' : (s % 60 == 0 ? '${s ~/ 60} min' : '1:30')),
                    selected: _it.restSec == s,
                    onSelected: (_) => setState(() => _it = _it.copyWith(restSec: s)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: Space.l),
          Text('Swap exercise', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final (id, name) in alts)
                ActionChip(
                  label: Text(name),
                  onPressed: () => setState(() => _it = _it.copyWith(exerciseId: id, name: name)),
                ),
              ActionChip(
                avatar: const Icon(LucideIcons.search, size: 16),
                label: const Text('Search all exercises'),
                onPressed: () async {
                  final m = await pickMove(context);
                  if (m != null) setState(() => _it = _it.copyWith(exerciseId: m.catalogId, name: m.name));
                },
              ),
            ],
          ),
          const SizedBox(height: Space.l),
          FilledButton(onPressed: () => Navigator.pop(context, _ItemEdit.save(_it)), child: const Text('Save')),
          const SizedBox(height: Space.s),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, const _ItemEdit.move(-1)),
                  icon: const Icon(LucideIcons.arrowUp, size: 18),
                  label: const Text('Move up'),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, const _ItemEdit.move(1)),
                  icon: const Icon(LucideIcons.arrowDown, size: 18),
                  label: const Text('Move down'),
                ),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, const _ItemEdit.remove()),
            style: TextButton.styleFrom(foregroundColor: context.pal.error),
            icon: const Icon(LucideIcons.trash2, size: IconSizes.s),
            label: const Text('Remove from this day'),
          ),
        ],
      ),
    );
  }
}

/// Picks any movement from the library. Returns null when cancelled.
Future<Move?> pickMove(BuildContext context) => showAppSheet<Move>(
  context,
  (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.85,
    child: MoveBrowser(onTap: (m) => Navigator.pop(context, m), trailingIcon: LucideIcons.plus, autofocus: true),
  ),
);
