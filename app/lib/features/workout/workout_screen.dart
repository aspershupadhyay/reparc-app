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

enum _Section { plan, exercises, history }

/// Workout tab: one start card, then plans, the exercise library, and
/// history (decision D-008). Layout follows the second
/// reference.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  _Section _section = _Section.plan;

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
                _Section.plan => 'Plan',
                _Section.exercises => 'Exercises',
                _Section.history => 'History',
              },
              onChanged: (s) => setState(() => _section = s),
            ),
            const SizedBox(height: Space.l),
            switch (_section) {
              _Section.plan => const PlanSection(),
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
      (_?, _) => (
        ref.watch(liveSessionProvider).value?.status == SessionStatus.paused ? 'Paused' : 'Training now',
        null,
        null,
      ),
      (null, final d?) => (
        'Next in your plan',
        d.name,
        [if (d.focus.isNotEmpty) d.focus, '${d.work.length} exercises', '~${d.minutes} min'].join(' · '),
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
                  onPressed: () => context.push('/workout/plan/${prog!.id}/day/${prog.nextDay}'),
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
