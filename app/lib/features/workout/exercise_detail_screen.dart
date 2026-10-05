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
import '../../data/providers.dart';
import '../../domain/analytics.dart';
import 'exercise_form.dart';

/// Exercise details and its history of completed sets.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final ex = ref.watch(exerciseProvider(id));
    final history = ref.watch(exerciseHistoryProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(ex.value?.name ?? 'Exercise'),
        actions: [
          if (ex.value != null) ...[
            IconButton(
              tooltip: 'Edit exercise',
              onPressed: () => showExerciseForm(context, existing: ex.value),
              icon: const Icon(LucideIcons.squarePen),
            ),
            IconButton(
              tooltip: 'Remove from library',
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Remove from library?',
                  body: 'Saved workouts keep this exercise and its sets. It will not appear in the library or picker.',
                  confirmLabel: 'Remove',
                );
                if (!ok || !context.mounted) return;
                final done = await guardedWrite(context, () async {
                  await ref.read(workoutRepoProvider).archiveExercise(id);
                  return true;
                });
                if (done == true && context.mounted) context.go('/workout');
              },
              icon: const Icon(LucideIcons.trash2),
            ),
          ],
        ],
      ),
      body: AsyncBody(
        value: ex,
        builder: (e) {
          if (e == null) return const Center(child: Text('Exercise not found.'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (label, value) in [
                      ('Variation', e.variation),
                      ('Equipment', e.equipment),
                      ('Target muscles', e.targetMuscles),
                      ('Note', e.note),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: Space.s),
                        child: Semantics(
                          label: '$label: ${value ?? missingLabel}',
                          excludeSemantics: true,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(width: 128, child: Text(label, style: t.bodySmall)),
                              Expanded(child: Text(value ?? missingText, style: t.bodyMedium)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SectionHeader('History'),
              AsyncBody(
                value: history,
                builder: (sets) {
                  if (sets.isEmpty) {
                    return const EmptyState(
                      icon: LucideIcons.history,
                      title: 'No completed sets yet',
                      body: 'Completed sets from saved workouts appear here.',
                    );
                  }
                  final records = heaviestLoads(sets);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final r in records) ...[
                        AppCard(
                          color: context.pal.energy,
                          onTap: () => context.go('/workout/session/${r.source.session.id}'),
                          child: Row(
                            children: [
                              const ExcludeSemantics(child: Icon(LucideIcons.trophy)),
                              const SizedBox(width: Space.m),
                              Expanded(
                                child: Metric(
                                  label: r.rule,
                                  value: fmtWithUnit(r.source.set.load, r.source.set.loadUnit),
                                  note:
                                      '${r.source.set.reps == null ? 'Reps not recorded' : '${r.source.set.reps} reps'} · '
                                      '${fmtDayShort(localDayOfInstant(r.source.session.startedAt, r.source.session.utcOffsetMinutes))}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: Space.s),
                      ],
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (final (i, r) in sets.indexed) ...[
                              if (i > 0) const Divider(indent: Space.l),
                              ListTile(
                                title: Text(
                                  [
                                    fmtWithUnit(r.set.load, r.set.loadUnit),
                                    if (r.set.reps != null) '× ${r.set.reps}',
                                    if (r.set.durationSec != null) fmtClock(Duration(seconds: r.set.durationSec!)),
                                  ].join(' '),
                                  style: t.bodyLarge?.tabular,
                                ),
                                subtitle: Text(
                                  '${fmtDayShort(localDayOfInstant(r.session.startedAt, r.session.utcOffsetMinutes))} · ${r.session.name}',
                                ),
                                onTap: () => context.go('/workout/session/${r.session.id}'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
