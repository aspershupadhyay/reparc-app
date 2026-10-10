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
import 'ring_clock.dart';
import 'session_clock.dart';

/// "Set 2 of 3", "Warm-up", or "Ramp-up".
String describeSetShort(SessionExerciseView e, SetEntry s) {
  if (s.setType == SetType.warmup) return isWarmupMove(e) ? 'Warm-up' : 'Ramp-up';
  final working = e.sets.where((x) => x.setType != SetType.warmup).toList();
  return 'Set ${working.indexWhere((x) => x.id == s.id) + 1} of ${working.length}';
}

/// What a set aims for: "60 kg × 8", "8 reps", "Hold 0:30", or "8 reps at
/// 50%" for a ramp-up set. Weight and reps come from the set, else the set
/// before, else the plan target.
String? aimFor(SessionExerciseView view, SetEntry set) {
  if (isTimedSet(set)) {
    final sec = set.targetSec ?? set.durationSec;
    if (sec == null) return null;
    // "Hold" suits a plank, not 5 minutes on the bike.
    return set.setType == SetType.warmup
        ? fmtClock(Duration(seconds: sec))
        : 'Hold ${fmtClock(Duration(seconds: sec))}';
  }
  if (rampUp(view, set) case final r? when set.reps == null && set.load == null) {
    return '${r.reps} reps at ${r.percent}%';
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

/// The top row of the live workout: leave, the workout name, the workout
/// time, and pause.
class LiveTopBar extends ConsumerWidget {
  const LiveTopBar({super.key, required this.session, this.showTime = true});
  final WorkoutSession session;
  final bool showTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const p = Palette.dark;
    final t = Theme.of(context).textTheme;
    final s = session;
    final paused = s.status == SessionStatus.paused;
    final repo = ref.read(workoutRepoProvider);
    return Row(
      children: [
        IconButton(
          tooltip: 'Leave screen. The workout keeps running.',
          onPressed: () => context.canPop() ? context.pop() : context.go('/workout'),
          icon: Icon(LucideIcons.chevronDown, color: Palette.dark.onPanel),
        ),
        Expanded(
          child: Semantics(
            button: true,
            label: 'Workout name ${s.name}. Rename',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: Radii.small,
              onTap: () async {
                final name = await promptText(context, title: 'Rename workout', label: 'Name', initial: s.name);
                if (name != null && context.mounted) {
                  await guardedWrite(context, () => repo.renameSession(s.id, name));
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Space.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.name,
                      style: t.titleSmall?.copyWith(color: p.onPanel),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showTime)
                      SessionClock(
                        sessionId: s.id,
                        style: t.bodySmall!.tabular.copyWith(color: p.onPanelSoft),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: paused ? 'Continue workout' : 'Pause workout',
          style: IconButton.styleFrom(backgroundColor: p.panelRaised, foregroundColor: p.onPanel),
          onPressed: () => guardedWrite(context, () => ref.read(guideProvider.notifier).setPaused(s.id, !paused)),
          icon: Icon(paused ? LucideIcons.play : LucideIcons.pause),
        ),
      ],
    );
  }
}

/// The guided workout header (handbook 4.13). Open, it shows the two-ring
/// clock, the exercise, one line about the set, and the controls. As the
/// sets scroll up it folds to one slim row with a small ring, so the clock
/// never leaves the screen and never covers the sets.
class GuidedHeaderDelegate extends SliverPersistentHeaderDelegate {
  GuidedHeaderDelegate({required this.detail, required this.top, required this.textScale, required this.width});

  final SessionDetail detail;

  /// Status bar height.
  final double top;
  final double textScale;
  final double width;

  static const _bar = 56.0;
  static const _compact = 76.0;

  double get ring => (width * 0.6).clamp(180.0, 248.0);

  @override
  double get maxExtent =>
      top + _bar + Space.s + ring + Space.m + 30 * textScale + 24 * textScale + Space.l + 56 + Space.l;

  @override
  double get minExtent => top + _compact;

  @override
  bool shouldRebuild(GuidedHeaderDelegate old) => true;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final f = (shrinkOffset / range).clamp(0.0, 1.0);
    return _GuidedHeader(detail: detail, fold: f, top: top, ring: ring, maxHeight: maxExtent);
  }
}

/// What the header shows now.
typedef _Now = ({
  RingPhase phase,
  String label,
  String time,
  String semantic,
  double? progress,
  String title,
  String? line,
});

class _GuidedHeader extends ConsumerWidget {
  const _GuidedHeader({
    required this.detail,
    required this.fold,
    required this.top,
    required this.ring,
    required this.maxHeight,
  });

  final SessionDetail detail;

  /// 0 open, 1 folded.
  final double fold;
  final double top;
  final double ring;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const p = Palette.dark;
    final g = ref.watch(guideProvider);
    final clock = ref.watch(clockProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        // A quiet depth, not a flat card: the panel darkens toward the sets.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.panelRaised, p.panel],
        ),
        border: Border(
          bottom: BorderSide(color: p.line.withValues(alpha: fold)),
        ),
      ),
      child: Ticker1s(
        builder: (context) {
          final now = _compute(g, clock().toUtc());
          return Stack(
            children: [
              if (fold < 0.6)
                Opacity(
                  opacity: (1 - fold / 0.6).clamp(0.0, 1.0),
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: maxHeight,
                      minHeight: maxHeight,
                      // Large text can make the open view taller than planned;
                      // it is clipped while it folds, never an error.
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: _open(context, ref, now, g),
                      ),
                    ),
                  ),
                ),
              if (fold > 0.4)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: GuidedHeaderDelegate._compact,
                  child: Opacity(
                    opacity: ((fold - 0.4) / 0.6).clamp(0.0, 1.0),
                    child: _folded(context, ref, now, g),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  int get _current => detail.completedSets;

  _Now _compute(GuideState g, DateTime now) {
    final s = detail.session;
    final paused = s.status == SessionStatus.paused;
    final next = nextSet(detail);
    if (g.phase == GuidePhase.set) {
      final view = detail.exercises.where((e) => e.sets.any((x) => x.id == g.setId)).firstOrNull;
      final set = view?.sets.firstWhere((x) => x.id == g.setId);
      final el = g.elapsedAt(now);
      final target = g.targetSec;
      final left = (target - el).clamp(0, target);
      final warm = view != null && isWarmupMove(view);
      return (
        phase: paused ? RingPhase.paused : (warm ? RingPhase.warmup : RingPhase.set),
        label: paused ? 'Paused' : (view == null || set == null ? 'Set' : describeSetShort(view, set)),
        time: fmtClock(Duration(seconds: target > 0 ? left : el)),
        semantic: target > 0
            ? 'Set time left ${speakDuration(Duration(seconds: left))}'
            : 'Set time ${speakDuration(Duration(seconds: el))}',
        progress: target > 0 ? el / target : null,
        title: view?.exercise.name ?? g.label,
        line: view == null || set == null ? null : aimFor(view, set),
      );
    }
    if (s.restStartedAt != null) {
      final r = restRemaining(restStartedAt: s.restStartedAt, restTargetSec: s.restTargetSec, now: s.pausedAt ?? now)!;
      final over = r.isNegative || r == Duration.zero;
      final total = s.restTargetSec ?? 0;
      return (
        phase: paused ? RingPhase.paused : RingPhase.rest,
        label: paused ? 'Paused' : (over ? 'Rest over' : 'Rest'),
        time: fmtClock(r.abs()),
        semantic: '${over ? 'Rest over by' : 'Rest left'} ${speakDuration(r.abs())}',
        progress: total > 0 ? 1 - r.inSeconds / total : null,
        title: next?.$1.exercise.name ?? 'Rest',
        line: next == null ? null : ['Next', ?aimFor(next.$1, next.$2)].join(' · '),
      );
    }
    final elapsed = sessionElapsed(
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      pausedAt: s.pausedAt,
      pausedMs: s.pausedMs,
      now: now,
    );
    final empty = detail.exercises.isEmpty;
    return (
      phase: paused ? RingPhase.paused : RingPhase.ready,
      label: paused ? 'Paused' : (next == null && !empty ? 'Done' : 'Ready'),
      time: fmtClock(elapsed),
      semantic: 'Elapsed ${speakDuration(elapsed)}',
      progress: null,
      title: empty ? 'Add an exercise to start' : (next?.$1.exercise.name ?? 'Every set is done'),
      line: next == null
          ? (empty ? null : 'Finish when you are ready')
          : [describeSetShort(next.$1, next.$2), ?aimFor(next.$1, next.$2)].join(' · '),
    );
  }

  Widget _open(BuildContext context, WidgetRef ref, _Now now, GuideState g) {
    const p = Palette.dark;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(Space.s, top, Space.s, Space.l),
      child: Column(
        children: [
          SizedBox(
            height: GuidedHeaderDelegate._bar,
            child: LiveTopBar(session: detail.session),
          ),
          const SizedBox(height: Space.s),
          RingClock(
            phase: now.phase,
            done: detail.completedSets,
            total: detail.totalSets,
            current: g.phase == GuidePhase.set || detail.session.restStartedAt != null ? _current : null,
            progress: now.progress,
            time: now.time,
            label: now.label,
            semantic: now.semantic,
            size: ring,
          ),
          const SizedBox(height: Space.m),
          Semantics(
            liveRegion: true,
            container: true,
            child: Column(
              children: [
                Text(
                  now.title,
                  style: t.titleLarge?.copyWith(color: p.onPanel, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(
                  height: 24 * MediaQuery.textScalerOf(context).scale(1),
                  child: now.line == null
                      ? null
                      : Text(
                          now.line!,
                          style: t.bodyMedium?.copyWith(color: p.onPanelSoft),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.s),
            child: _Controls(detail: detail, g: g, phase: now.phase),
          ),
        ],
      ),
    );
  }

  Widget _folded(BuildContext context, WidgetRef ref, _Now now, GuideState g) {
    const p = Palette.dark;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.m, Space.s),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave screen. The workout keeps running.',
            onPressed: () => context.canPop() ? context.pop() : context.go('/workout'),
            icon: Icon(LucideIcons.chevronDown, color: Palette.dark.onPanel),
          ),
          ExcludeSemantics(
            child: RingClock(
              phase: now.phase,
              done: detail.completedSets,
              total: detail.totalSets,
              current: _current,
              progress: now.progress,
              time: '',
              label: '',
              semantic: '',
              size: 52,
              showText: false,
            ),
          ),
          const SizedBox(width: Space.m),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    now.time,
                    style: t.titleLarge!.tabular.copyWith(color: p.onPanel, fontWeight: FontWeight.w700, height: 1.1),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      '${now.label} · ${now.title}',
                      style: t.bodySmall?.copyWith(color: ringColors(now.phase).first),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _PrimaryButton(detail: detail, g: g, compact: true),
        ],
      ),
    );
  }
}

/// +15 s, the one main button, and stop: the same three places in a set
/// and a rest, so the thumb learns them.
class _Controls extends ConsumerWidget {
  const _Controls({required this.detail, required this.g, required this.phase});
  final SessionDetail detail;
  final GuideState g;
  final RingPhase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guide = ref.read(guideProvider.notifier);
    final inSet = g.phase == GuidePhase.set;
    final inRest = !inSet && detail.session.restStartedAt != null;
    Widget side(IconData icon, String tip, VoidCallback? onTap) => SizedBox.square(
      dimension: 56,
      child: onTap == null
          ? null
          : IconButton(
              tooltip: tip,
              onPressed: onTap,
              style: IconButton.styleFrom(
                backgroundColor: Palette.dark.panelRaised,
                foregroundColor: Palette.dark.onPanel,
                minimumSize: const Size.square(56),
              ),
              icon: Icon(icon),
            ),
    );
    return Row(
      children: [
        if (inSet)
          side(
            LucideIcons.timerReset,
            'Add 15 seconds to this set',
            g.targetSec > 0 ? () => guide.addTime(15) : null,
          )
        else if (inRest)
          side(
            LucideIcons.timerReset,
            'Add 15 seconds to the rest',
            () => guardedWrite(context, () => guide.addRest(15)),
          )
        else
          side(LucideIcons.timerReset, '', null),
        const SizedBox(width: Space.m),
        Expanded(
          child: _PrimaryButton(detail: detail, g: g),
        ),
        const SizedBox(width: Space.m),
        if (inSet)
          side(LucideIcons.square, 'Stop timer', () => guardedWrite(context, guide.stop))
        else if (inRest)
          side(LucideIcons.square, 'End rest', () => guardedWrite(context, guide.stop))
        else
          side(LucideIcons.square, '', null),
      ],
    );
  }
}

/// Set done in a set, Skip rest in a rest, Start before the first set.
class _PrimaryButton extends ConsumerWidget {
  const _PrimaryButton({required this.detail, required this.g, this.compact = false});
  final SessionDetail detail;
  final GuideState g;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const p = Palette.dark;
    final t = Theme.of(context).textTheme;
    final guide = ref.read(guideProvider.notifier);
    final next = nextSet(detail);
    final (String label, IconData icon, VoidCallback? onTap) = switch (g.phase) {
      GuidePhase.set => ('Set done', LucideIcons.check, () => guardedWrite(context, guide.tapSetDone)),
      _ when next == null => ('Start', LucideIcons.play, null),
      _ when detail.session.restStartedAt != null => (
        'Skip rest',
        LucideIcons.skipForward,
        () async {
          final done = await guardedWrite(context, guide.tapSkipRest);
          if (done ?? false) unawaited(HapticFeedback.mediumImpact());
        },
      ),
      _ => (
        detail.completedSets == 0 ? 'Start workout' : 'Start set',
        LucideIcons.play,
        () {
          unawaited(HapticFeedback.mediumImpact());
          guardedWrite(context, guide.startSet);
        },
      ),
    };
    if (onTap == null) return const SizedBox.shrink();
    if (compact) {
      return IconButton.filled(
        tooltip: label,
        style: IconButton.styleFrom(backgroundColor: p.onPanel, foregroundColor: p.panel),
        onPressed: onTap,
        icon: Icon(icon),
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: p.onPanel,
        foregroundColor: p.panel,
        minimumSize: const Size.fromHeight(56),
        textStyle: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
