import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../data/workout_repository.dart';
import 'exercise_form.dart';
import 'exercise_picker.dart';
import 'start_workout.dart';

/// Edit a plan. Changes do not affect workouts already saved (handbook 4.6).
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(templateProvider(id));
    final repo = ref.read(workoutRepoProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(plan.value?.template.name ?? 'Plan'),
        actions: [
          if (plan.value != null)
            PopupMenuButton<String>(
              tooltip: 'Plan options',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onSelected: (v) async {
                final p = plan.value!.template;
                switch (v) {
                  case 'rename':
                    final name = await promptText(context, title: 'Rename plan', label: 'Plan name', initial: p.name);
                    if (name != null && context.mounted) {
                      await guardedWrite(context, () => repo.renameTemplate(id, name));
                    }
                  case 'copy':
                    final newId = await guardedWrite(context, () => repo.copyTemplate(id), success: 'Plan copied.');
                    if (newId != null && context.mounted) context.go('/workout/plan/$newId');
                  case 'delete':
                    final ok = await confirmAction(
                      context,
                      title: 'Delete this plan?',
                      body: 'Saved workouts that used this plan do not change.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );
                    if (!ok || !context.mounted) return;
                    final done = await guardedWrite(context, () async {
                      await repo.deleteTemplate(id);
                      return true;
                    });
                    if (done == true && context.mounted) {
                      context.go('/workout');
                      showMessage(context, 'Plan deleted.');
                    }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'copy', child: Text('Copy plan')),
                PopupMenuItem(value: 'delete', child: Text('Delete plan')),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: plan,
        builder: (p) {
          if (p == null) return const Center(child: Text('This plan was deleted.'));
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            children: [
              FilledButton.icon(
                onPressed: p.items.isEmpty ? null : () => startWorkout(context, ref, templateId: id),
                icon: const Icon(LucideIcons.play, size: IconSizes.s),
                label: const Text('Start this plan'),
              ),
              const SectionHeader('Exercises'),
              if (p.items.isEmpty)
                const EmptyState(
                  icon: LucideIcons.listPlus,
                  title: 'This plan is empty',
                  body: 'Add exercises in the order you train them. Targets are optional.',
                ),
              for (final (i, item) in p.items.indexed) ...[
                _PlanItem(planId: id, view: item, index: i, count: p.items.length),
                const SizedBox(height: Space.s),
              ],
              const SizedBox(height: Space.s),
              OutlinedButton.icon(
                onPressed: () async {
                  final exId = await pickExercise(context);
                  if (exId != null && context.mounted) {
                    await guardedWrite(context, () => repo.addTemplateExercise(id, exId));
                  }
                },
                icon: const Icon(LucideIcons.plus, size: IconSizes.s),
                label: const Text('Add exercise'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanItem extends ConsumerWidget {
  const _PlanItem({required this.planId, required this.view, required this.index, required this.count});
  final String planId;
  final TemplateItemView view;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final repo = ref.read(workoutRepoProvider);
    final i = view.item;
    final target = [
      if (i.targetSets != null) '${i.targetSets} sets',
      if (i.targetReps != null) '${i.targetReps} reps',
    ];
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseTitle(view.exercise), style: t.titleSmall),
                Text(target.isEmpty ? 'No target' : 'Target: ${target.join(' × ')}', style: t.bodySmall),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Options for ${view.exercise.name}',
            icon: const Icon(LucideIcons.ellipsisVertical),
            onSelected: (v) async {
              switch (v) {
                case 'up':
                  await guardedWrite(context, () => repo.moveTemplateExercise(planId, index, index - 1));
                case 'down':
                  await guardedWrite(context, () => repo.moveTemplateExercise(planId, index, index + 1));
                case 'target':
                  await showAppSheet<void>(context, (_) => _TargetForm(view: view));
                case 'remove':
                  await guardedWrite(context, () => repo.removeTemplateExercise(i.id));
              }
            },
            itemBuilder: (_) => [
              if (index > 0) const PopupMenuItem(value: 'up', child: Text('Move up')),
              if (index < count - 1) const PopupMenuItem(value: 'down', child: Text('Move down')),
              const PopupMenuItem(value: 'target', child: Text('Set target')),
              const PopupMenuItem(value: 'remove', child: Text('Remove from plan')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TargetForm extends ConsumerStatefulWidget {
  const _TargetForm({required this.view});
  final TemplateItemView view;

  @override
  ConsumerState<_TargetForm> createState() => _TargetFormState();
}

class _TargetFormState extends ConsumerState<_TargetForm> {
  late final _sets = TextEditingController(text: widget.view.item.targetSets?.toString() ?? '');
  late final _reps = TextEditingController(text: widget.view.item.targetReps?.toString() ?? '');
  String? _error;

  @override
  void dispose() {
    _sets.dispose();
    _reps.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final sets = parseWhole(_sets.text);
    final reps = parseWhole(_reps.text);
    if ((sets != null && (sets < 0 || sets > 50)) || (reps != null && reps < 0)) {
      setState(() => _error = 'Use whole numbers. Sets must be 50 or less.');
      return;
    }
    final ok = await guardedWrite(context, () async {
      await ref
          .read(workoutRepoProvider)
          .updateTemplateTargets(widget.view.item.id, targetSets: sets, targetReps: reps);
      return true;
    });
    if (ok == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Target for ${widget.view.exercise.name}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.s),
          Text(
            'Targets create empty set rows when you start the plan. They are not saved as completed values.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: Space.l),
          TextField(
            controller: _sets,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Sets (optional)'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Reps per set (optional)', errorText: _error),
          ),
          const SizedBox(height: Space.l),
          FilledButton(onPressed: _save, child: const Text('Save target')),
        ],
      ),
    );
  }
}
