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
import '../../domain/guide.dart';
import '../../domain/session_time.dart';
import 'guide_controller.dart';
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
    if (done == true && finished && ref.read(currentSettingsProvider).guideOn) {
      ref.read(guideProvider.notifier).workoutSaved();
    }
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

/// Ink panel with the workout clocks and controls.
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
                    onPressed: () =>
                        guardedWrite(context, () => ref.read(guideProvider.notifier).setPaused(s.id, !paused)),
                    icon: Icon(paused ? LucideIcons.play : LucideIcons.pause),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: Space.m),
                child: ref.watch(currentSettingsProvider).guideOn
                    ? Padding(
                        padding: const EdgeInsets.only(top: Space.s),
                        child: _GuideHero(detail: detail),
                      )
                    : Column(
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
                              Expanded(child: _SetsDone(detail: detail)),
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
          // A pause also pauses the rest.
          now: session.pausedAt ?? clock().toUtc(),
        )!;
        final over = r.isNegative || r == Duration.zero;
        return Metric(
          label: over ? 'Rest over by' : 'Rest left',
          value: fmtClock(r.abs()),
          semanticValue: speakDuration(r.abs()),
          color: over ? context.pal.orange : context.pal.onPanel,
          labelColor: context.pal.onPanelSoft,
        );
      },
    );
  }
}

class _SetsDone extends StatelessWidget {
  const _SetsDone({required this.detail});
  final SessionDetail detail;

  @override
  Widget build(BuildContext context) => Metric(
    label: 'Sets done',
    value: '${detail.completedSets} / ${detail.totalSets}',
    semanticValue: '${detail.completedSets} of ${detail.totalSets}',
    color: context.pal.onPanel,
    labelColor: context.pal.onPanelSoft,
  );
}

/// Guided workout (handbook 4.13). The clock the user needs now is the big
/// one: the set time during a set, the rest during a rest, else the
/// workout time. The user starts each set; the voice and timers follow.
class _GuideHero extends ConsumerWidget {
  const _GuideHero({required this.detail});
  final SessionDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final g = ref.watch(guideProvider);
    final guide = ref.read(guideProvider.notifier);
    final clock = ref.watch(clockProvider);
    final s = detail.session;
    final paused = s.status == SessionStatus.paused;
    final next = nextSet(detail);
    final onInk = t.bodySmall?.copyWith(color: p.onPanelSoft);
    final bigStyle = t.displaySmall!.copyWith(fontSize: 48, color: p.energy).tabular;
    Widget caption(String text) => Semantics(liveRegion: true, child: OneLine(text, style: onInk));
    Widget chip(String label, String semantic, VoidCallback onTap) => Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: ActionChip(
        label: Text(label),
        backgroundColor: p.panelRaised,
        side: BorderSide(color: p.panelRaised),
        labelStyle: t.labelMedium?.copyWith(color: p.onPanel),
        onPressed: onTap,
      ),
    );
    // Stopping is a quiet text button at the far end, away from "+15 s".
    Widget quiet(String label, VoidCallback onTap) => TextButton(
      style: TextButton.styleFrom(foregroundColor: p.onPanelSoft),
      onPressed: onTap,
      child: Text(label),
    );
    final big = FilledButton.styleFrom(
      backgroundColor: p.energy,
      foregroundColor: p.onEnergy,
      minimumSize: const Size.fromHeight(56),
      textStyle: t.titleMedium,
    );
    final metrics = Row(
      children: [
        Expanded(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elapsed', style: onInk),
                const SizedBox(height: 2),
                SessionClock(
                  sessionId: s.id,
                  style: t.titleLarge!.tabular.copyWith(color: p.onPanel),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: _SetsDone(detail: detail)),
      ],
    );
    Widget startButton(String label) => FilledButton.icon(
      style: big,
      onPressed: () {
        unawaited(HapticFeedback.mediumImpact());
        guardedWrite(context, guide.startSet);
      },
      icon: const Icon(LucideIcons.play),
      label: Text(label),
    );

    if (g.phase == GuidePhase.set) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Ticker1s(
            builder: (context) {
              final el = g.elapsedAt(clock().toUtc());
              final target = g.targetSec;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  caption(paused ? 'Paused · ${g.label}' : g.label),
                  Semantics(
                    label: target > 0
                        ? 'Set time ${speakDuration(Duration(seconds: el))} of ${speakDuration(Duration(seconds: target))}'
                        : 'Set time ${speakDuration(Duration(seconds: el))}',
                    excludeSemantics: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(fmtClock(Duration(seconds: el)), style: bigStyle),
                        if (target > 0)
                          Text(
                            '  / ${fmtClock(Duration(seconds: target))}',
                            style: t.titleMedium?.tabular.copyWith(color: p.onPanelSoft),
                          ),
                      ],
                    ),
                  ),
                  if (target > 0) ...[
                    const SizedBox(height: Space.s),
                    ClipRRect(
                      borderRadius: Radii.small,
                      child: LinearProgressIndicator(
                        value: (el / target).clamp(0.0, 1.0),
                        minHeight: 6,
                        color: p.energy,
                        backgroundColor: p.panelRaised,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: Space.l),
          metrics,
          const SizedBox(height: Space.l),
          FilledButton.icon(
            style: big,
            onPressed: () => guardedWrite(context, guide.finishSet),
            icon: const Icon(LucideIcons.check),
            label: const Text('Set done'),
          ),
          const SizedBox(height: Space.xs),
          Row(
            children: [
              if (g.targetSec > 0) chip('+15 s', 'Add 15 seconds to this set', () => guide.addTime(15)),
              const Spacer(),
              quiet('Stop timer', () => guardedWrite(context, guide.stop)),
            ],
          ),
        ],
      );
    }

    if (s.restStartedAt != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Ticker1s(
            builder: (context) {
              final r = restRemaining(
                restStartedAt: s.restStartedAt,
                restTargetSec: s.restTargetSec,
                now: s.pausedAt ?? clock().toUtc(),
              )!;
              final over = r.isNegative || r == Duration.zero;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  caption(paused ? 'Paused · rest' : (over ? 'Rest over by' : 'Rest')),
                  Semantics(
                    label: '${over ? 'Rest over by' : 'Rest left'} ${speakDuration(r.abs())}',
                    excludeSemantics: true,
                    child: Text(fmtClock(r.abs()), style: bigStyle.copyWith(color: over ? p.orange : p.energy)),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: Space.l),
          metrics,
          if (next != null) ...[
            const SizedBox(height: Space.l),
            _NextUp(view: next.$1, set: next.$2),
            const SizedBox(height: Space.s),
            startButton('Start set'),
          ],
          const SizedBox(height: Space.xs),
          Row(
            children: [
              chip('+15 s', 'Add 15 seconds to the rest', () => guardedWrite(context, () => guide.addRest(15))),
              const Spacer(),
              quiet('End rest', () => guardedWrite(context, guide.stop)),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        caption(paused ? 'Paused' : 'Elapsed'),
        SessionClock(sessionId: s.id, style: bigStyle),
        const SizedBox(height: Space.l),
        Row(
          children: [Expanded(child: _SetsDone(detail: detail))],
        ),
        const SizedBox(height: Space.l),
        if (next == null)
          Text(
            detail.exercises.isEmpty ? 'Add an exercise to start the guide.' : 'Every set is done. Finish when ready.',
            style: onInk,
          )
        else ...[
          _NextUp(view: next.$1, set: next.$2),
          const SizedBox(height: Space.s),
          startButton('Start set'),
        ],
      ],
    );
  }
}

/// The next set and what it aims for: "Bench press · set 2 of 4" and
/// "60 kg × 8". Weight and reps come from the set, else the set before.
class _NextUp extends StatelessWidget {
  const _NextUp({required this.view, required this.set});
  final SessionExerciseView view;
  final SetEntry set;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final aim = _aim();
    return Semantics(
      container: true,
      label: 'Next: ${describeSet(view, set)}${aim == null ? '' : ', $aim'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OneLine('Next · ${describeSet(view, set)}', style: t.titleSmall?.copyWith(color: p.onPanel)),
          if (aim != null) Text(aim, style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
        ],
      ),
    );
  }

  String? _aim() {
    if (isTimedSet(set)) {
      return set.durationSec == null ? null : 'Hold ${fmtClock(Duration(seconds: set.durationSec!))}';
    }
    final before = view.sets.takeWhile((x) => x.id != set.id).where((x) => x.setType == set.setType).toList();
    final prev = before.isEmpty ? null : before.last;
    final load = set.load ?? prev?.load;
    final unit = set.load != null ? set.loadUnit : prev?.loadUnit;
    final reps = set.reps ?? prev?.reps ?? targetRepsFromNote(view.item.note);
    if (load == null && reps == null) return null;
    if (load == null) return '$reps reps';
    return [fmtWithUnit(load, unit), ?reps?.toString()].join(' × ');
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
