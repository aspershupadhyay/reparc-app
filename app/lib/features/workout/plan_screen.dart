import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/roadmap.dart';
import 'start_workout.dart';

/// One plan: its days, Follow, and plan options (handbook 4.12). Saved
/// workouts do not change when the plan changes.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final value = ref.watch(programProvider(id));
    final repo = ref.read(programRepoProvider);
    final prog = value.value;
    return Scaffold(
      appBar: AppBar(
        title: Text(prog?.name ?? 'Plan'),
        actions: [
          if (prog != null)
            PopupMenuButton<String>(
              tooltip: 'Plan options',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onSelected: (v) async {
                switch (v) {
                  case 'rename':
                    final name = await promptText(
                      context,
                      title: 'Rename plan',
                      label: 'Plan name',
                      initial: prog.name,
                    );
                    if (name != null && context.mounted) await guardedWrite(context, () => repo.rename(id, name));
                  case 'copy':
                    final newId = await guardedWrite(context, () => repo.copy(id), success: 'Plan copied.');
                    if (newId != null && context.mounted) context.pushReplacement('/workout/plan/$newId');
                  case 'stop':
                    await guardedWrite(context, () => repo.stop(id), success: 'You no longer follow this plan.');
                  case 'delete':
                    final ok = await confirmAction(
                      context,
                      title: 'Delete this plan?',
                      body: prog.followed
                          ? 'You follow this plan. After you delete it, you follow no plan. Saved workouts do not change.'
                          : 'Saved workouts that used this plan do not change.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    context.pop();
                    await repo.delete(id);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'copy', child: Text('Copy plan')),
                if (prog.followed) const PopupMenuItem(value: 'stop', child: Text('Stop following')),
                const PopupMenuItem(value: 'delete', child: Text('Delete plan')),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: value,
        builder: (prog) {
          if (prog == null) return const Center(child: Text('This plan was deleted.'));
          final plan = prog.plan;
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            children: [
              if (plan.about case final about?) Text(about, style: t.bodyMedium?.copyWith(color: p.inkSoft)),
              const SizedBox(height: Space.s),
              if (prog.followed)
                StatusLine(
                  icon: LucideIcons.circleCheck,
                  text: 'You follow this plan. Its next day is on Home and at the top of Workout.',
                  color: p.brand,
                )
              else
                FilledButton.icon(
                  onPressed: () =>
                      guardedWrite(context, () => repo.follow(id), success: 'You now follow ${prog.name}.'),
                  icon: const Icon(LucideIcons.circleCheck, size: IconSizes.s),
                  label: const Text('Follow this plan'),
                ),
              const SectionHeader('Days'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, d) in plan.days.indexed) ...[
                      if (i > 0) const Divider(indent: Space.l),
                      ListTile(
                        title: Text(prog.followed && i == prog.nextDay ? '${d.name} · next' : d.name),
                        subtitle: Text(
                          [
                            if (d.focus.isNotEmpty) d.focus,
                            '${d.work.length} exercise${d.work.length == 1 ? '' : 's'}',
                            '~${d.minutes} min',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          tooltip: 'Start ${d.name}',
                          onPressed: d.work.isEmpty
                              ? null
                              : () => startWorkout(context, ref, programId: id, programDay: i),
                          icon: Icon(LucideIcons.play, color: d.work.isEmpty ? p.inkSoft : p.brand),
                        ),
                        onTap: () => context.push('/workout/plan/$id/day/$i'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Space.s),
              if (plan.days.length < 7)
                OutlinedButton.icon(
                  onPressed: () async {
                    final days = [...plan.days, emptyDay(plan.days.length + 1)];
                    final ok = await guardedWrite(context, () async {
                      await repo.save(id, plan.copyWith(days: days));
                      return true;
                    });
                    if (ok == true && context.mounted) await context.push('/workout/plan/$id/day/${days.length - 1}');
                  },
                  icon: const Icon(LucideIcons.plus, size: IconSizes.s),
                  label: const Text('Add day'),
                ),
              const SizedBox(height: Space.m),
              const StatusLine(
                icon: LucideIcons.info,
                text: 'Tap a day to change its exercises, sets, reps, and rest. The play button starts that day.',
              ),
            ],
          );
        },
      ),
    );
  }
}
