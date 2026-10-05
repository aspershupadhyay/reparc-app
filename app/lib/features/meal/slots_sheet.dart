import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';

/// Add, rename, set a usual time for, or remove meal slots (handbook 5.6).
Future<void> showSlotsSheet(BuildContext context) => showAppSheet<void>(context, (_) => const _SlotsSheet());

class _SlotsSheet extends ConsumerWidget {
  const _SlotsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final repo = ref.read(mealRepoProvider);
    final slots = ref.watch(mealSlotsProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: AsyncBody(
        value: slots,
        builder: (list) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Meal slots', style: t.titleLarge),
            const SizedBox(height: Space.xs),
            Text('Removing a slot hides it from new days. Saved foods in it stay.', style: t.bodySmall),
            const SizedBox(height: Space.m),
            for (final s in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.name),
                subtitle: Text(
                  s.usualMinute == null
                      ? 'No usual time'
                      : 'Usual time ${TimeOfDay(hour: s.usualMinute! ~/ 60, minute: s.usualMinute! % 60).format(context)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Rename ${s.name}',
                      icon: const Icon(LucideIcons.pencil),
                      onPressed: () async {
                        final name = await promptText(context, title: 'Rename meal', label: 'Name', initial: s.name);
                        if (name != null && context.mounted) {
                          await guardedWrite(
                            context,
                            () => repo.updateSlot(s.id, name: name, usualMinute: s.usualMinute),
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Set usual time for ${s.name}',
                      icon: const Icon(LucideIcons.clock),
                      onPressed: () async {
                        final m = s.usualMinute;
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: m == null
                              ? const TimeOfDay(hour: 12, minute: 0)
                              : TimeOfDay(hour: m ~/ 60, minute: m % 60),
                        );
                        if (picked != null && context.mounted) {
                          await guardedWrite(
                            context,
                            () => repo.updateSlot(s.id, name: s.name, usualMinute: picked.hour * 60 + picked.minute),
                          );
                        }
                      },
                    ),
                    IconButton(
                      tooltip: 'Remove ${s.name}',
                      icon: const Icon(LucideIcons.trash2),
                      onPressed: list.length <= 1 ? null : () => guardedWrite(context, () => repo.archiveSlot(s.id)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Space.m),
            OutlinedButton.icon(
              onPressed: () async {
                final name = await promptText(context, title: 'New meal slot', label: 'Name', confirmLabel: 'Add');
                if (name != null && context.mounted) await guardedWrite(context, () => repo.addSlot(name));
              },
              icon: const Icon(LucideIcons.plus, size: IconSizes.s),
              label: const Text('Add meal slot'),
            ),
          ],
        ),
      ),
    );
  }
}
