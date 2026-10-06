import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../exercises/library_screen.dart';
import 'roadmap_screens.dart';
import 'session_clock.dart';
import 'start_workout.dart';

enum _Section { roadmap, plans, exercises, history }

/// Workout tab: one start card, then the roadmap, plans, the exercise
/// library, and history (decision D-008). Layout follows the second
/// reference.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  _Section _section = _Section.roadmap;

  @override
  Widget build(BuildContext context) {
    final live = ref.watch(liveSessionProvider).value;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            const ScreenTitle('Workout'),
            _StartCard(liveId: live?.id),
            const SizedBox(height: Space.l),
            PillTabs<_Section>(
              values: _Section.values,
              selected: _section,
              label: (s) => switch (s) {
                _Section.roadmap => 'Roadmap',
                _Section.plans => 'Plans',
                _Section.exercises => 'Exercises',
                _Section.history => 'History',
              },
              onChanged: (s) => setState(() => _section = s),
            ),
            const SizedBox(height: Space.l),
            switch (_section) {
              _Section.roadmap => const RoadmapSection(),
              _Section.plans => const _Plans(),
              _Section.exercises => const LibraryBody(),
              _Section.history => const _History(),
            },
          ],
        ),
      ),
    );
  }
}

/// The one way to start: continue the live workout, start the next roadmap
/// day, or start an empty workout.
class _StartCard extends ConsumerWidget {
  const _StartCard({required this.liveId});
  final String? liveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final prog = ref.watch(activeProgramProvider).value;
    final next = liveId != null || prog == null || prog.plan.days.isEmpty ? null : prog.plan.days[prog.nextDay];
    final (String eyebrow, String? title, String? sub) = switch ((liveId, next)) {
      (_?, _) => ('Training now', null, null),
      (null, final d?) => (
        'Next on your roadmap',
        d.name,
        '${d.focus} · ${d.work.length} exercises · ~${d.minutes} min',
      ),
      _ => ('Free workout', 'Add exercises as you go', null),
    };
    return Container(
      padding: const EdgeInsets.all(Space.xl),
      decoration: BoxDecoration(color: p.panel, borderRadius: Radii.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(eyebrow, style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
                    const SizedBox(height: Space.xs),
                    if (liveId != null)
                      SessionClock(
                        sessionId: liveId!,
                        style: t.displaySmall!.tabular.copyWith(color: p.energy),
                      )
                    else
                      OneLine(title!, style: t.titleMedium?.copyWith(color: p.onPanel)),
                    if (sub != null) Text(sub, style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
                  ],
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: p.energy, foregroundColor: p.onEnergy),
                onPressed: switch ((liveId, next)) {
                  (final id?, _) => () => context.push('/live/$id'),
                  (null, _?) => () => startWorkout(context, ref, programId: prog!.id, programDay: prog.nextDay),
                  _ => () => startWorkout(context, ref),
                },
                icon: Icon(liveId == null ? LucideIcons.play : LucideIcons.arrowRight, size: 20),
                label: Text(liveId == null ? 'Start' : 'Open'),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: Space.s),
            Wrap(
              spacing: Space.s,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: p.onPanel),
                  onPressed: () => context.push('/workout/roadmap/${prog!.id}/day/${prog.nextDay}'),
                  child: const Text('See the day'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: p.onPanelSoft),
                  onPressed: () => startWorkout(context, ref),
                  child: const Text('Empty workout'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final colors = [
      (p.energy, p.onEnergy),
      (p.brandSoft, p.ink),
      (p.orangeSoft, p.ink),
      (p.greenSoft, p.ink),
      (p.blueSoft, p.ink),
    ];
    return AsyncBody(
      value: ref.watch(templatesProvider),
      builder: (plans) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plans.isEmpty)
            const EmptyState(
              icon: LucideIcons.clipboardList,
              title: 'No plans yet',
              body: 'A plan is one workout you repeat. Your roadmap plans the whole week.',
            ),
          for (final (i, (plan, count)) in plans.indexed) ...[
            Builder(
              builder: (context) {
                final (bg, fg) = colors[i % colors.length];
                return AppCard(
                  color: bg,
                  padding: const EdgeInsets.all(Space.xl),
                  onTap: () => context.push('/workout/plan/${plan.id}'),
                  semanticLabel: '${plan.name}, $count exercise${count == 1 ? '' : 's'}. Open plan',
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plan.name, style: t.titleLarge?.copyWith(color: fg)),
                            const SizedBox(height: Space.s),
                            Tag(
                              '$count exercise${count == 1 ? '' : 's'}',
                              color: fg.withValues(alpha: 0.1),
                              textColor: fg,
                              icon: LucideIcons.dumbbell,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Start ${plan.name}',
                        style: IconButton.styleFrom(
                          backgroundColor: p.panel,
                          foregroundColor: p.energy,
                          fixedSize: const Size(56, 56),
                        ),
                        onPressed: count == 0 ? null : () => startWorkout(context, ref, templateId: plan.id),
                        icon: const Icon(LucideIcons.play),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: Space.m),
          ],
          OutlinedButton.icon(
            onPressed: () async {
              final name = await promptText(context, title: 'New plan', label: 'Plan name', confirmLabel: 'Create');
              if (name == null || !context.mounted) return;
              final id = await guardedWrite(context, () => ref.read(workoutRepoProvider).createTemplate(name));
              if (id != null && context.mounted) await context.push('/workout/plan/$id');
            },
            icon: const Icon(LucideIcons.plus, size: IconSizes.s),
            label: const Text('New plan'),
          ),
        ],
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return AsyncBody(
      value: ref.watch(historyProvider),
      builder: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.history,
            title: 'No workouts yet',
            body: 'Finished workouts show up here.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final h in list) ...[
              Builder(
                builder: (context) {
                  final d = localDayOfInstant(h.session.startedAt, h.session.utcOffsetMinutes);
                  final incomplete = h.session.status == SessionStatus.incomplete;
                  return AppCard(
                    padding: const EdgeInsets.all(Space.m),
                    onTap: () => context.push('/workout/session/${h.session.id}'),
                    semanticLabel:
                        '${h.session.name}, ${fmtDayLong(d)}, ${h.completedSets} sets${incomplete ? ', incomplete' : ''}',
                    child: ExcludeSemantics(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(color: p.brandSoft, borderRadius: Radii.medium),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${d.day}', style: t.titleLarge?.copyWith(color: p.brand, height: 1)),
                                Text(
                                  fmtDayMonth(d).split(' ').last.toUpperCase(),
                                  style: t.labelSmall?.copyWith(color: p.brand),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.session.name, style: t.titleSmall),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    Tag('${h.exerciseCount} exercises'),
                                    Tag('${h.completedSets} sets'),
                                    if (incomplete) Tag('Incomplete', color: p.orangeSoft),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: Space.s),
            ],
          ],
        );
      },
    );
  }
}
