import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/workout_repository.dart';
import '../../domain/session_time.dart';
import 'session_clock.dart';
import 'session_editor.dart';

/// Focused full-screen workout (handbook 3.1 and 3.4).
///
/// Leaving this screen does not end the session. The tab bar shows a
/// control that returns here.
class LiveSessionScreen extends ConsumerWidget {
  const LiveSessionScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(sessionProvider(id));
    return Scaffold(
      body: AsyncBody(
        value: detail,
        builder: (d) {
          if (d == null) {
            return _Gone(message: 'This workout was deleted.');
          }
          if (!d.session.status.isLive) {
            return _Gone(message: 'This workout is saved.', sessionId: id);
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Hero(detail: d)),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
                sliver: SliverList.list(
                  children: [
                    SessionExerciseList(detail: d, live: true),
                    const SizedBox(height: Space.xl),
                    FilledButton.icon(
                      onPressed: () => _finish(context, ref, d),
                      icon: const Icon(LucideIcons.flag, size: IconSizes.s),
                      label: const Text('Finish workout'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, SessionDetail d) async {
    final choice = await showAppSheet<String>(context, (_) => _FinishSheet(detail: d));
    if (choice == null || !context.mounted) return;
    final repo = ref.read(workoutRepoProvider);
    if (choice == 'discard') {
      final ok = await confirmAction(
        context,
        title: 'Discard this workout?',
        body: 'This deletes the workout and all ${d.totalSets} sets. You cannot undo this.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      final done = await guardedWrite(context, () async {
        await repo.deleteSession(d.session.id);
        return true;
      });
      if (done == true && context.mounted) {
        context.go('/workout');
        showMessage(context, 'Workout discarded.');
      }
      return;
    }
    final finished = choice == 'finish';
    final done = await guardedWrite(context, () async {
      await repo.end(d.session.id, finished: finished);
      return true;
    });
    if (done == true && context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      context.go('/workout/session/${d.session.id}');
      showMessage(context, finished ? 'Workout saved.' : 'Workout saved as incomplete.');
    }
  }
}

class _Gone extends StatelessWidget {
  const _Gone({required this.message, this.sessionId});
  final String message;
  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: Space.l),
            FilledButton(
              onPressed: () => context.go(sessionId == null ? '/workout' : '/workout/session/$sessionId'),
              child: Text(sessionId == null ? 'Back to Workout' : 'Open saved workout'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ink panel with elapsed time, rest time, and set count as separate values.
class _Hero extends ConsumerWidget {
  const _Hero({required this.detail});
  final SessionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = detail.session;
    final paused = s.status == SessionStatus.paused;
    final repo = ref.read(workoutRepoProvider);
    final onInk = t.bodySmall?.copyWith(color: context.pal.onPanelSoft);
    return Container(
      decoration: BoxDecoration(
        color: context.pal.panel,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(Radii.l)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.l, Space.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Leave screen. The workout keeps running.',
                    onPressed: () => context.canPop() ? context.pop() : context.go('/workout'),
                    icon: Icon(LucideIcons.chevronDown, color: context.pal.onPanel),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Workout name ${s.name}. Rename',
                      excludeSemantics: true,
                      child: InkWell(
                        borderRadius: Radii.small,
                        onTap: () async {
                          final name = await promptText(
                            context,
                            title: 'Rename workout',
                            label: 'Name',
                            initial: s.name,
                          );
                          if (name != null && context.mounted) {
                            await guardedWrite(context, () => repo.renameSession(s.id, name));
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: Space.s),
                          child: Text(
                            s.name,
                            style: t.titleLarge?.copyWith(color: context.pal.onPanel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: paused ? 'Continue workout' : 'Pause workout',
                    style: IconButton.styleFrom(
                      backgroundColor: context.pal.energy,
                      foregroundColor: context.pal.onEnergy,
                    ),
                    onPressed: () => guardedWrite(context, () => paused ? repo.resume(s.id) : repo.pause(s.id)),
                    icon: Icon(paused ? LucideIcons.play : LucideIcons.pause),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: Space.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Space.s),
                    Semantics(
                      liveRegion: true,
                      child: Text(paused ? 'Paused' : 'Elapsed', style: onInk),
                    ),
                    SessionClock(
                      sessionId: s.id,
                      style: t.displaySmall!.copyWith(fontSize: 48, color: context.pal.energy).tabular,
                    ),
                    SizedBox(height: Space.l),
                    Row(
                      children: [
                        Expanded(child: _RestValue(session: s)),
                        Expanded(
                          child: Metric(
                            label: 'Sets done',
                            value: '${detail.completedSets} / ${detail.totalSets}',
                            semanticValue: '${detail.completedSets} of ${detail.totalSets}',
                            color: context.pal.onPanel,
                            labelColor: context.pal.onPanelSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.m),
                    _RestControls(session: s),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestValue extends ConsumerWidget {
  const _RestValue({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clock = ref.watch(clockProvider);
    if (session.restStartedAt == null) {
      return Metric(label: 'Rest', value: 'Off', color: context.pal.onPanel, labelColor: context.pal.onPanelSoft);
    }
    return Ticker1s(
      builder: (_) {
        final r = restRemaining(
          restStartedAt: session.restStartedAt,
          restTargetSec: session.restTargetSec,
          now: clock().toUtc(),
        )!;
        final over = r.isNegative || r == Duration.zero;
        return Metric(
          label: over ? 'Rest over by' : 'Rest left',
          value: fmtClock(r.abs()),
          semanticValue: speakDuration(r.abs()),
          color: over ? context.pal.amber : context.pal.onPanel,
          labelColor: context.pal.onPanelSoft,
        );
      },
    );
  }
}

class _RestControls extends ConsumerWidget {
  const _RestControls({required this.session});
  final WorkoutSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(workoutRepoProvider);
    final running = session.restStartedAt != null;
    final chipStyle = Theme.of(context).textTheme.labelMedium;
    Widget chip(String label, VoidCallback onTap) => ActionChip(
      label: Text(label),
      backgroundColor: context.pal.panelRaised,
      side: BorderSide(color: context.pal.panelRaised),
      labelStyle: chipStyle?.copyWith(color: context.pal.onPanel),
      onPressed: onTap,
    );
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: running
          ? [
              chip('Stop rest', () => guardedWrite(context, () => repo.stopRest(session.id))),
              chip('+30 s', () {
                final target = (session.restTargetSec ?? 0) + 30;
                guardedWrite(context, () => repo.setRestTarget(session.id, target));
              }),
            ]
          : [
              for (final sec in const [60, 90, 120, 180])
                chip(
                  'Rest ${sec < 120 ? '$sec s' : '${sec ~/ 60} min'}',
                  () => guardedWrite(context, () => repo.startRest(session.id, sec)),
                ),
            ],
    );
  }
}

class _FinishSheet extends StatelessWidget {
  const _FinishSheet({required this.detail});
  final SessionDetail detail;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final open = detail.totalSets - detail.completedSets;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Finish workout', style: t.titleLarge),
          SizedBox(height: Space.s),
          Text(
            '${detail.completedSets} of ${detail.totalSets} sets done in ${detail.exercises.length} '
            'exercise${detail.exercises.length == 1 ? '' : 's'}.'
            '${open > 0 ? ' Sets that are not done stay in the record as not done.' : ''}',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.l),
          FilledButton(onPressed: () => Navigator.pop(context, 'finish'), child: const Text('Finish and save')),
          const SizedBox(height: Space.s),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, 'incomplete'),
            child: const Text('Save as incomplete'),
          ),
          const SizedBox(height: Space.s),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep going')),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            style: TextButton.styleFrom(foregroundColor: context.pal.error),
            child: const Text('Discard workout'),
          ),
        ],
      ),
    );
  }
}
