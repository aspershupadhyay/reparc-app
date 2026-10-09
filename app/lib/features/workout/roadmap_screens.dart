import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/program_repository.dart';
import '../../data/providers.dart';
import '../../domain/roadmap.dart';
import '../exercises/library/library.dart';
import '../exercises/library/move_browser.dart';
import 'exercise_picker.dart';
import 'start_workout.dart';

IconData goalIcon(RoadmapGoal g) => switch (g) {
  RoadmapGoal.aesthetic => LucideIcons.sparkles,
  RoadmapGoal.bodybuilding => LucideIcons.dumbbell,
  RoadmapGoal.strength => LucideIcons.weight,
  RoadmapGoal.calisthenics => LucideIcons.personStanding,
  RoadmapGoal.leanFit => LucideIcons.flame,
};

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Plan section of the Workout tab: the followed plan's week, then every
/// other plan (handbook 4.12).
class PlanSection extends ConsumerWidget {
  const PlanSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(programsProvider),
      builder: (plans) {
        if (plans.isEmpty) return const _ChooseGoal();
        final followed = plans.where((p) => p.followed).firstOrNull;
        final others = plans.where((p) => !p.followed).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (followed != null) _ActiveRoadmap(prog: followed),
            if (others.isNotEmpty) ...[
              SectionHeader(followed == null ? 'Your plans' : 'Other plans'),
              if (followed == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: Space.s),
                  child: StatusLine(
                    icon: LucideIcons.info,
                    text: 'Follow a plan to see its next day on Home. You can start any day of any plan.',
                  ),
                ),
              for (final o in others) ...[_PlanCard(prog: o), const SizedBox(height: Space.s)],
            ],
            const SizedBox(height: Space.s),
            OutlinedButton.icon(
              onPressed: () => newPlan(context, ref),
              icon: const Icon(LucideIcons.plus, size: IconSizes.s),
              label: const Text('New plan'),
            ),
          ],
        );
      },
    );
  }
}

/// Asks how to make a plan: with the builder, or an empty one.
Future<void> newPlan(BuildContext context, WidgetRef ref) async {
  final choice = await showAppSheet<String>(
    context,
    (context) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('New plan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.m),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, 'build'),
            icon: const Icon(LucideIcons.sparkles, size: IconSizes.s),
            label: const Text('Build for my goal'),
          ),
          const SizedBox(height: Space.s),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, 'own'),
            icon: const Icon(LucideIcons.pencil, size: IconSizes.s),
            label: const Text('Make my own'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted) return;
  if (choice == 'build') {
    await context.push('/workout/plan/new');
  } else if (choice == 'own') {
    await makeOwnPlan(context, ref);
  }
}

/// Creates an empty plan with one day and opens it.
Future<void> makeOwnPlan(BuildContext context, WidgetRef ref) async {
  final name = await promptText(context, title: 'New plan', label: 'Plan name', confirmLabel: 'Create');
  if (name == null || !context.mounted) return;
  final id = await guardedWrite(
    context,
    () => ref.read(programRepoProvider).create(ProgramPlan(days: [emptyDay(1)]), name: name),
  );
  if (id != null && context.mounted) await context.push('/workout/plan/$id');
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.prog});
  final SavedProgram prog;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final days = prog.plan.days.length;
    final sub = [prog.plan.about ?? 'Your own plan', '$days day${days == 1 ? '' : 's'}'].join(' · ');
    return AppCard(
      onTap: () => context.push('/workout/plan/${prog.id}'),
      semanticLabel: '${prog.name}. $sub. Open plan',
      child: ExcludeSemantics(
        child: Row(
          children: [
            IconBadge(
              prog.plan.goal == null ? LucideIcons.clipboardList : goalIcon(prog.plan.goal!),
              color: p.brandSoft,
              glyph: p.brand,
              size: 44,
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(prog.name, style: t.titleMedium),
                  Text(sub, style: t.bodySmall),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _ChooseGoal extends ConsumerWidget {
  const _ChooseGoal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final colors = [p.coral, p.blue, p.orange, p.green, p.brand];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What do you want to work towards?', style: t.titleLarge),
        const SizedBox(height: Space.xs),
        Text(
          'Pick a goal and get a plan for it. You choose the level, days, and equipment next, and you can '
          'change any part later.',
          style: t.bodyMedium?.copyWith(color: p.inkSoft),
        ),
        const SizedBox(height: Space.l),
        for (final (i, g) in RoadmapGoal.values.indexed) ...[
          AppCard(
            onTap: () => context.push('/workout/plan/new?goal=${g.name}'),
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
        TextButton.icon(
          onPressed: () => makeOwnPlan(context, ref),
          icon: const Icon(LucideIcons.pencil, size: IconSizes.s),
          label: const Text('Or make my own plan'),
        ),
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
    // The card at the top of the Workout tab starts the next day.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () => context.push('/workout/plan/${prog.id}'),
          semanticLabel: 'Following ${prog.name}. Open plan',
          padding: const EdgeInsets.all(Space.m),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(plan.goal == null ? LucideIcons.clipboardList : goalIcon(plan.goal!), color: p.brand),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Following', style: t.labelSmall?.copyWith(color: p.brand)),
                      Text(prog.name, style: t.titleMedium),
                      if (_aboutWithoutName(plan.about, prog.name) case final about?) Text(about, style: t.bodySmall),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
              ],
            ),
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
                      color: i == prog.nextDay ? p.energyStrong : p.surfaceAlt,
                      borderRadius: Radii.small,
                    ),
                    child: Text(
                      i < plan.weekdays.length ? _dayNames[(plan.weekdays[i] - 1) % 7] : 'D${i + 1}',
                      style: t.labelMedium?.copyWith(color: i == prog.nextDay ? p.on(p.energyStrong) : p.ink),
                    ),
                  ),
                  title: Text(i == prog.nextDay ? '${d.name} · next' : d.name),
                  subtitle: Text(
                    metaLine([if (d.focus.isNotEmpty) d.focus, '${d.workSets} sets', '~${d.minutes} min']),
                  ),
                  trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                  onTap: () => context.push('/workout/plan/${prog.id}/day/$i'),
                ),
              ],
            ],
          ),
        ),
        if (plan.showNotes && plan.progression.isNotEmpty) ...[
          const SectionHeader('How to progress'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusLine(icon: LucideIcons.trendingUp, text: plan.progression, color: p.ink),
                if (plan.deload.isNotEmpty) ...[
                  const SizedBox(height: Space.m),
                  StatusLine(icon: LucideIcons.batteryCharging, text: plan.deload, color: p.ink),
                ],
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

/// The plan's summary without the words its name already says, so the card
/// does not read "Aesthetic · Beginner / Aesthetic · Beginner · Full gym".
String? _aboutWithoutName(String? about, String name) {
  if (about == null || about.isEmpty) return null;
  if (!about.startsWith(name)) return about;
  final rest = about.substring(name.length).replaceFirst(RegExp(r'^\s*·\s*'), '').trim();
  return rest.isEmpty ? null : rest;
}

/// Weekday picker. Changes are kept here until the number of days matches
/// the roadmap, then saved, so the roadmap never has fewer days than it needs.
class _TrainingDays extends StatefulWidget {
  const _TrainingDays({super.key, required this.saved, required this.needed, required this.onSave});
  final List<int> saved;
  final int needed;
  final ValueChanged<List<int>> onSave;

  @override
  State<_TrainingDays> createState() => _TrainingDaysState();
}

class _TrainingDaysState extends State<_TrainingDays> {
  late final Set<int> _picked = {...widget.saved};

  void _toggle(int d, bool on) {
    setState(() => on ? _picked.add(d) : _picked.remove(d));
    if (_picked.length == widget.needed) widget.onSave(_picked.toList()..sort());
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.needed - _picked.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seven equal day buttons on one row, Monday first, like the Home
        // week strip. No wrapping onto a second ragged row.
        Row(
          children: [
            for (var d = 1; d <= 7; d++)
              Expanded(
                child: Builder(
                  builder: (context) {
                    final p = context.pal;
                    final on = _picked.contains(d);
                    return Semantics(
                      button: true,
                      toggled: on,
                      label: _dayNames[d - 1],
                      excludeSemantics: true,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _toggle(d, !on),
                        child: SizedBox(
                          height: minTarget,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: on ? p.ink : Colors.transparent,
                                shape: BoxShape.circle,
                                border: on ? null : Border.all(color: p.line, width: 1.5),
                              ),
                              child: Text(
                                _dayNames[d - 1].substring(0, 2),
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: on ? p.surface : p.ink),
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
        if (diff != 0) ...[
          const SizedBox(height: Space.s),
          Semantics(
            liveRegion: true,
            child: StatusLine(
              icon: LucideIcons.info,
              text: diff > 0
                  ? 'Pick $diff more ${diff == 1 ? 'day' : 'days'}, one for each plan day. Saved when it adds up.'
                  : 'Remove ${-diff} ${diff == -1 ? 'day' : 'days'}. This plan has ${widget.needed} days a week.',
            ),
          ),
        ],
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
          Text('Customize plan', style: t.titleLarge),
          const SizedBox(height: Space.l),
          Text('SHOW ON EACH DAY', style: sectionLabelStyle(context)),
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
          const SizedBox(height: Space.xl),
          Text('TRAINING DAYS · ${plan.days.length} A WEEK', style: sectionLabelStyle(context)),
          const SizedBox(height: Space.xs),
          _TrainingDays(
            key: ValueKey(plan.weekdays.join(',')),
            saved: plan.weekdays,
            needed: plan.days.length,
            onSave: (days) => save(plan.copyWith(weekdays: days)),
          ),
          const SizedBox(height: Space.xl),
          Text('NEXT DAY TO TRAIN', style: sectionLabelStyle(context)),
          const SizedBox(height: Space.s),
          // A short check list reads better than six chips on three rows.
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in plan.days.indexed) ...[
                  if (i > 0) const Divider(indent: Space.l),
                  Semantics(
                    selected: live.nextDay == i,
                    button: true,
                    label: d.name,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => guardedWrite(context, () => repo.setNextDay(prog.id, i)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                        child: Row(
                          children: [
                            Expanded(child: Text(d.name, style: t.bodyLarge)),
                            if (live.nextDay == i) Icon(LucideIcons.check, size: IconSizes.s, color: context.pal.brand),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/workout/plan/new${plan.goal == null ? '' : '?goal=${plan.goal!.name}'}');
            },
            icon: const Icon(LucideIcons.refreshCw, size: IconSizes.s),
            label: const Text('Build a new plan'),
          ),
          // The destructive action sits apart, below a rule, so it is not
          // tapped by mistake for the button above.
          const SizedBox(height: Space.xl),
          const Divider(),
          const SizedBox(height: Space.s),
          TextButton(
            onPressed: () async {
              final ok = await confirmAction(
                context,
                title: 'Stop following this plan?',
                body: 'It stays saved in Other plans with your workout history. You can follow any plan again.',
                confirmLabel: 'Stop',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              await guardedWrite(context, () => repo.stop(prog.id));
              if (context.mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: context.pal.error),
            child: const Text('Stop following this plan'),
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

  /// Keeps the chosen days a week unless the new goal does not offer them.
  void _keepDays() {
    if (!_goal.dayOptions.contains(_days)) _days = _goal.defaultDays(_level);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final plan = buildProgram(goal: _goal, level: _level, setup: _setup, days: _days);
    return Scaffold(
      appBar: AppBar(title: const Text('Build a plan')),
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
                      success: 'Plan saved and followed. You can change any part of it.',
                    );
                    if (!context.mounted) return;
                    setState(() => _saving = false);
                    if (id != null) context.pop();
                  },
            child: const Text('Follow this plan'),
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
                    _keepDays();
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
            onChanged: (l) => setState(() => _level = l),
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
                  onSelected: (_) => setState(() => _days = d),
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
      final rowId = await pickExercise(context);
      if (rowId == null || !context.mounted) return;
      final row = await ref.read(workoutRepoProvider).exercise(rowId);
      if (row == null || !context.mounted) return;
      final items = [...d.items];
      final at = items.lastIndexWhere((i) => i.kind != ItemKind.cooldown) + 1;
      items.insert(
        at,
        PlanItem(
          kind: ItemKind.accessory,
          exerciseId: row.catalogId ?? userRef(row.id),
          name: row.name,
          sets: 3,
          repsLow: 10,
          repsHigh: 12,
          restSec: 90,
          rir: 2,
        ),
      );
      await saveDay(d.copyWith(items: items));
    }

    List<Widget> rowsOf(Iterable<(int, PlanItem)> rows) => [
      for (final (n, (i, it)) in rows.indexed) ...[
        if (n > 0) const Divider(indent: Space.l),
        _ItemRow(item: it, onTap: () => editItem(i)),
      ],
    ];

    final indexed = d.items.indexed.toList();
    final rampUp = d.work.where((i) => i.rampUp).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Day options',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (v) async {
              switch (v) {
                case 'rename':
                  final name = await promptText(context, title: 'Rename day', label: 'Day name', initial: d.name);
                  if (name != null) await saveDay(d.copyWith(name: name));
                case 'earlier' || 'later':
                  final to = v == 'earlier' ? day - 1 : day + 1;
                  final days = [...plan.days]..removeAt(day);
                  days.insert(to, d);
                  await guardedWrite(context, () => repo.save(programId, plan.copyWith(days: days)));
                  if (context.mounted) context.pushReplacement('/workout/plan/$programId/day/$to');
                case 'remove':
                  final ok = await confirmAction(
                    context,
                    title: 'Remove ${d.name}?',
                    body: 'Saved workouts from this day do not change.',
                    confirmLabel: 'Remove',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  final days = [...plan.days]..removeAt(day);
                  if (context.mounted) context.pop();
                  await repo.save(programId, plan.copyWith(days: days));
                  if (prog.nextDay >= days.length) await repo.setNextDay(programId, 0);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'rename', child: Text('Rename day')),
              if (day > 0) const PopupMenuItem(value: 'earlier', child: Text('Move day earlier')),
              if (day < plan.days.length - 1) const PopupMenuItem(value: 'later', child: Text('Move day later')),
              if (plan.days.length > 1) const PopupMenuItem(value: 'remove', child: Text('Remove day')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: p.energy, foregroundColor: p.onEnergy),
          onPressed: d.work.isEmpty ? null : () => startWorkout(context, ref, programId: programId, programDay: day),
          icon: const Icon(LucideIcons.play, size: 20),
          label: Text(ref.watch(liveSessionProvider).value == null ? 'Start workout' : 'Continue workout'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          // The day is the subject of the page, so it gets the large title
          // (visual review, 2026-10-09).
          Semantics(header: true, child: Text(d.name, style: t.displaySmall)),
          const SizedBox(height: Space.xs),
          Text(
            metaLine([
              if (d.focus.isNotEmpty) d.focus,
              '${d.work.length} exercises',
              '${d.workSets} sets',
              'about ${d.minutes} min',
            ]),
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          const SizedBox(height: Space.l),
          if (d.items.isEmpty)
            const EmptyState(
              icon: LucideIcons.listPlus,
              title: 'This day is empty',
              body: 'Add exercises in the order you train them.',
            ),
          if (plan.showWarmup && d.warmup.isNotEmpty) ...[
            _FoldedSection(
              icon: LucideIcons.flame,
              title: 'Warm-up',
              summary: metaLine(['${d.warmup.length} moves', 'about ${d.warmupMinutes} min']),
              children: rowsOf(indexed.where((e) => e.$2.kind == ItemKind.warmup)),
            ),
            const SizedBox(height: Space.m),
          ],
          if (d.work.isNotEmpty)
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: rowsOf(
                  indexed.where((e) => e.$2.kind != ItemKind.warmup && e.$2.kind != ItemKind.cooldown),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: addExercise,
              icon: const Icon(LucideIcons.plus, size: IconSizes.s),
              label: const Text('Add exercise'),
            ),
          ),
          if (plan.showCooldown && d.cooldown.isNotEmpty) ...[
            _FoldedSection(
              icon: LucideIcons.wind,
              title: 'Cool-down',
              summary: metaLine(['${d.cooldown.length} stretches', 'not logged']),
              children: rowsOf(indexed.where((e) => e.$2.kind == ItemKind.cooldown)),
            ),
            const SizedBox(height: Space.m),
          ],
          // One link instead of three paragraphs between the sections.
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: p.inkSoft),
              onPressed: () => showAppSheet<void>(
                context,
                (context) => _DayHelp(
                  lines: [
                    if (plan.showWarmup && d.warmup.isNotEmpty) ...[
                      'Each warm-up move is a warm-up set to tick off in your workout.',
                      if (rampUp != null)
                        '${rampUp.name} starts with lighter ramp-up sets: ${rampUpText(plan.level)} of your working weight.',
                      'Warm-up sets never count toward volume or records.',
                    ],
                    if (plan.showCooldown && d.cooldown.isNotEmpty)
                      'Stretch after you finish. Cool-down stretches are not logged in the workout.',
                    'Tap any exercise to change sets, reps, rest, or swap it for one that fits your gym.',
                  ],
                ),
              ),
              icon: const Icon(LucideIcons.info, size: IconSizes.s),
              label: const Text('How this day works'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A warm-up or cool-down block, folded to one summary row by default, so
/// the main work is on the first screen. Opens in place.
class _FoldedSection extends StatefulWidget {
  const _FoldedSection({required this.icon, required this.title, required this.summary, required this.children});
  final IconData icon;
  final String title;
  final String summary;
  final List<Widget> children;

  @override
  State<_FoldedSection> createState() => _FoldedSectionState();
}

class _FoldedSectionState extends State<_FoldedSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: '${widget.title}. ${widget.summary}',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                child: Row(
                  children: [
                    Icon(widget.icon, size: IconSizes.s, color: p.inkSoft),
                    const SizedBox(width: Space.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: t.titleSmall),
                          Text(widget.summary, style: t.bodySmall),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.25 : 0,
                      duration: motionOf(context, Motion.quick),
                      child: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open) ...[const Divider(indent: Space.l), ...widget.children],
        ],
      ),
    );
  }
}

class _DayHelp extends StatelessWidget {
  const _DayHelp({required this.lines});
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How this day works', style: t.titleLarge),
            const SizedBox(height: Space.m),
            for (final l in lines) ...[
              StatusLine(icon: LucideIcons.dot, text: l, color: context.pal.ink),
              const SizedBox(height: Space.s),
            ],
          ],
        ),
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
    final details = item.details;
    final main = item.kind == ItemKind.main;
    // The main lift is the big item on the page: a lime label and a larger
    // name. The rest share one quieter row. Each row shows only sets × reps;
    // rest and reps in reserve are in the edit sheet and the screen-reader
    // label (visual review, 2026-10-09).
    return Semantics(
      button: true,
      label: '${item.name}. ${item.kind.label}. $details. Edit',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.l, vertical: main ? Space.l : Space.m),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (main)
                      Text(
                        'MAIN LIFT',
                        style: t.labelSmall?.copyWith(color: p.energyStrong, letterSpacing: 0.6).w(FontWeight.w700),
                      ),
                    Row(
                      children: [
                        Flexible(child: Text(item.name, style: main ? t.titleLarge : t.bodyLarge)),
                        if (item.rampUp) ...[
                          const SizedBox(width: Space.s),
                          Tag('Ramp up', color: p.surfaceAlt),
                        ],
                      ],
                    ),
                    if (item.note != null && item.kind == ItemKind.warmup) Text(item.note!, style: t.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: Space.m),
              Text(
                item.target,
                style: (main ? t.titleSmall : t.bodyMedium)?.tabular.copyWith(color: main ? p.ink : p.inkSoft),
              ),
              const SizedBox(width: Space.xs),
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
                // The plan's own rest, such as 1:15, shows as a choice too.
                for (final s in ({45, 60, 90, 120, 180, 240, ?_it.restSec}.toList()..sort()))
                  ChoiceChip(
                    label: Text(restText(s)),
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
