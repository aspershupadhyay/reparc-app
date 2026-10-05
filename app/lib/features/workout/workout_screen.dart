import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import 'exercise_form.dart';
import 'session_clock.dart';
import 'start_workout.dart';
import '../../core/theme.dart';

enum _Section { plans, library, history }

/// Workout tab: plans, exercise library, history, and the way into live
/// logging (decision D-008).
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  _Section _section = _Section.plans;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final live = ref.watch(liveSessionProvider).value;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
              sliver: SliverList.list(
                children: [
                  Semantics(header: true, child: Text('Workout', style: t.headlineSmall)),
                  const SizedBox(height: Space.l),
                  _StartCard(liveId: live?.id),
                  const SizedBox(height: Space.l),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final s in _Section.values)
                          Padding(
                            padding: const EdgeInsets.only(right: Space.s),
                            child: ChoiceChip(
                              label: Text(switch (s) {
                                _Section.plans => 'Plans',
                                _Section.library => 'Exercise library',
                                _Section.history => 'History',
                              }),
                              selected: _section == s,
                              onSelected: (_) => setState(() => _section = s),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Space.l),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
              sliver: SliverToBoxAdapter(
                child: switch (_section) {
                  _Section.plans => const _Plans(),
                  _Section.library => const _Library(),
                  _Section.history => const _History(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StartCard extends ConsumerWidget {
  const _StartCard({required this.liveId});
  final String? liveId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.ink,
      border: false,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveId == null ? 'Empty workout' : 'Workout in progress',
                  style: t.titleMedium?.copyWith(color: AppColors.surface),
                ),
                if (liveId != null)
                  SessionClock(
                    sessionId: liveId!,
                    style: t.titleLarge!.tabular.copyWith(color: AppColors.lime),
                  )
                else
                  Text('Add exercises as you go.', style: t.bodySmall?.copyWith(color: AppColors.border)),
              ],
            ),
          ),
          FilledButton(
            onPressed: liveId == null ? () => startWorkout(context, ref) : () => context.push('/live/$liveId'),
            child: Text(liveId == null ? 'Start' : 'Continue'),
          ),
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
    return AsyncBody(
      value: ref.watch(templatesProvider),
      builder: (plans) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plans.isEmpty)
            const EmptyState(
              icon: LucideIcons.clipboardList,
              title: 'No plans yet',
              body: 'A plan is an ordered list of exercises. Starting a plan creates a new workout.',
            ),
          for (final (plan, count) in plans) ...[
            AppCard(
              color: AppColors.lavender,
              border: false,
              onTap: () => context.go('/workout/plan/${plan.id}'),
              semanticLabel: '${plan.name}, $count exercise${count == 1 ? '' : 's'}. Open plan',
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: t.titleMedium),
                        Text(
                          '$count exercise${count == 1 ? '' : 's'}',
                          style: t.bodySmall?.copyWith(color: AppColors.ink),
                        ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    excluding: false,
                    child: IconButton.filled(
                      tooltip: 'Start ${plan.name}',
                      style: IconButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: AppColors.lime),
                      onPressed: count == 0 ? null : () => startWorkout(context, ref, templateId: plan.id),
                      icon: const Icon(LucideIcons.play),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.m),
          ],
          const SizedBox(height: Space.s),
          OutlinedButton.icon(
            onPressed: () async {
              final name = await promptText(context, title: 'New plan', label: 'Plan name', confirmLabel: 'Create');
              if (name == null || !context.mounted) return;
              final id = await guardedWrite(context, () => ref.read(workoutRepoProvider).createTemplate(name));
              if (id != null && context.mounted) context.go('/workout/plan/$id');
            },
            icon: const Icon(LucideIcons.plus, size: IconSizes.s),
            label: const Text('New plan'),
          ),
        ],
      ),
    );
  }
}

class _Library extends ConsumerWidget {
  const _Library();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(exercisesProvider),
      builder: (list) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (list.isEmpty)
            const EmptyState(
              icon: LucideIcons.library,
              title: 'Your library is empty',
              body: 'Create the exercises you train. You can also add one during a workout.',
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final (i, e) in list.indexed) ...[
                    if (i > 0) const Divider(indent: Space.l),
                    ListTile(
                      title: Text(exerciseTitle(e)),
                      subtitle: e.equipment == null && e.targetMuscles == null
                          ? null
                          : Text([?e.equipment, ?e.targetMuscles].join(' · ')),
                      trailing: const Icon(LucideIcons.chevronRight, size: IconSizes.s),
                      onTap: () => context.go('/workout/exercise/${e.id}'),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: Space.l),
          OutlinedButton.icon(
            onPressed: () => showExerciseForm(context),
            icon: const Icon(LucideIcons.plus, size: IconSizes.s),
            label: const Text('New exercise'),
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
    return AsyncBody(
      value: ref.watch(historyProvider),
      builder: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: LucideIcons.history,
            title: 'No saved workouts',
            body: 'Finished and incomplete workouts appear here. You can open one to correct it.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final h in list) ...[
              AppCard(
                onTap: () => context.go('/workout/session/${h.session.id}'),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.session.name, style: t.titleMedium),
                          Text(
                            '${fmtDayShort(localDayOfInstant(h.session.startedAt, h.session.utcOffsetMinutes))} · '
                            '${h.exerciseCount} exercise${h.exerciseCount == 1 ? '' : 's'} · '
                            '${h.completedSets} set${h.completedSets == 1 ? '' : 's'} done',
                            style: t.bodySmall,
                          ),
                          if (h.session.status == SessionStatus.incomplete)
                            Text('Saved as incomplete', style: t.bodySmall?.copyWith(color: AppColors.warning)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: IconSizes.s),
                  ],
                ),
              ),
              const SizedBox(height: Space.s),
            ],
          ],
        );
      },
    );
  }
}
