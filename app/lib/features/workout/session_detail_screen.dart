import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/session_time.dart';
import 'session_editor.dart';

/// Review and correct a saved workout (handbook 4.2, step 8).
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionProvider(id));
    final repo = ref.read(workoutRepoProvider);
    final now = ref.watch(clockProvider)().toUtc();
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.session.name ?? 'Workout'),
        actions: [
          if (detail.value != null)
            PopupMenuButton<String>(
              tooltip: 'Workout options',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onSelected: (v) async {
                final s = detail.value!.session;
                if (v == 'rename') {
                  final name = await promptText(context, title: 'Rename workout', label: 'Name', initial: s.name);
                  if (name != null && context.mounted) await guardedWrite(context, () => repo.renameSession(id, name));
                } else if (v == 'delete') {
                  final ok = await confirmAction(
                    context,
                    title: 'Delete this workout?',
                    body: 'This deletes the workout and all its sets from this phone. You cannot undo this.',
                    confirmLabel: 'Delete',
                    destructive: true,
                  );
                  if (!ok || !context.mounted) return;
                  final done = await guardedWrite(context, () async {
                    await repo.deleteSession(id);
                    return true;
                  });
                  if (done == true && context.mounted) {
                    context.go('/workout');
                    showMessage(context, 'Workout deleted.');
                  }
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete workout')),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: detail,
        builder: (d) {
          if (d == null) {
            return const Center(child: Text('This workout was deleted.'));
          }
          final s = d.session;
          final started = s.startedAt.toUtc().add(Duration(minutes: s.utcOffsetMinutes));
          final elapsed = sessionElapsed(
            startedAt: s.startedAt,
            endedAt: s.endedAt,
            pausedAt: s.pausedAt,
            pausedMs: s.pausedMs,
            now: now,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusLine(
                      icon: s.status == SessionStatus.finished ? LucideIcons.circleCheck : LucideIcons.circleAlert,
                      text: s.status.label,
                    ),
                    const SizedBox(height: Space.m),
                    Text(
                      '${fmtDayLong(started)} at ${fmtClockTime(started)} (${s.timeZoneName})',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Space.m),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Metric(
                            label: 'Duration',
                            value: fmtClock(elapsed),
                            semanticValue: speakDuration(elapsed),
                          ),
                        ),
                        Expanded(
                          child: Metric(label: 'Sets done', value: '${d.completedSets} / ${d.totalSets}'),
                        ),
                      ],
                    ),
                    if (s.status.isLive) ...[
                      const SizedBox(height: Space.m),
                      FilledButton(onPressed: () => context.push('/live/$id'), child: const Text('Continue workout')),
                    ],
                  ],
                ),
              ),
              const SectionHeader('Exercises'),
              SessionExerciseList(detail: d, live: false),
              const SectionHeader('Note'),
              _NoteField(sessionId: id, initial: s.note),
            ],
          );
        },
      ),
    );
  }
}

String fmtClockTime(DateTime d) => fmtTime(d);

class _NoteField extends ConsumerStatefulWidget {
  const _NoteField({required this.sessionId, required this.initial});
  final String sessionId;
  final String? initial;

  @override
  ConsumerState<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends ConsumerState<_NoteField> {
  late final _c = TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      minLines: 2,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Add a note about this workout'),
      onChanged: (v) => ref.read(workoutRepoProvider).setSessionNote(widget.sessionId, v),
    );
  }
}
