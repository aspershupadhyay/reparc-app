import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/dates.dart';
import '../core/format.dart';
import '../core/palette.dart';
import '../core/theme.dart';
import '../core/tokens.dart';
import '../core/widgets.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/providers.dart';
import '../domain/track.dart';
import '../features/workout/session_clock.dart';
import 'activity_format.dart';
import 'track_screen.dart';

IconData activityIcon(ActivityKind k) => switch (k) {
  ActivityKind.run => LucideIcons.footprints,
  ActivityKind.walk => LucideIcons.personStanding,
  ActivityKind.ride => LucideIcons.bike,
};

/// Run, Walk, Ride: three equal buttons on the Workout tab. While one
/// records, a card shows its time and opens it (handbook 4.14).
class ActivityStartRow extends ConsumerWidget {
  const ActivityStartRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final live = ref.watch(liveActivityProvider).value;
    if (live != null) return LiveActivityCard(activity: live);
    return Row(
      children: [
        for (final (i, k) in ActivityKind.values.indexed) ...[
          if (i > 0) const SizedBox(width: Space.s),
          Expanded(
            child: Semantics(
              button: true,
              label: 'Record a ${k.label.toLowerCase()} with GPS',
              excludeSemantics: true,
              child: AppCard(
                padding: const EdgeInsets.symmetric(vertical: Space.m),
                onTap: () => startActivity(context, ref, k),
                child: Column(
                  children: [
                    Icon(activityIcon(k), color: p.brand),
                    const SizedBox(height: Space.xs),
                    Text(k.label, style: t.titleSmall),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// The activity being recorded: kind, time, and a way back to it.
class LiveActivityCard extends ConsumerWidget {
  const LiveActivityCard({super.key, required this.activity});
  final GpsActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final paused = activity.status == ActivityStatus.paused;
    return AppCard(
      color: p.panel,
      padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.m, Space.m),
      onTap: () => context.push('/track/${activity.id}'),
      child: Row(
        children: [
          Icon(activityIcon(activity.kind), color: p.energy),
          const SizedBox(width: Space.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (paused ? 'Paused' : 'Recording ${activity.kind.label.toLowerCase()}').toUpperCase(),
                  style: t.labelSmall?.copyWith(color: p.energy, letterSpacing: 0.6),
                ),
                Ticker1s(
                  builder: (_) => Text(
                    fmtActivityTime(ref.read(activityRepoProvider).elapsed(activity)),
                    style: t.titleLarge?.tabular.copyWith(color: p.onPanel),
                  ),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronRight, color: p.onPanelSoft),
        ],
      ),
    );
  }
}

/// A saved activity in History.
class ActivityHistoryCard extends ConsumerWidget {
  const ActivityHistoryCard({super.key, required this.activity});
  final GpsActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final unit = ref.watch(currentSettingsProvider).distanceUnit;
    final a = activity;
    final d = localDayOfInstant(a.startedAt, a.utcOffsetMinutes);
    final distance = a.distanceM == null ? null : distanceParts(a.distanceM!, unit);
    final moving = a.movingSec == null ? null : Duration(seconds: a.movingSec!);
    final pace = a.distanceM == null || moving == null || a.distanceM! < 10
        ? null
        : paceOrSpeed(a.kind, metresPerSec: a.distanceM! / moving.inSeconds.clamp(1, 1 << 30), unit: unit);
    return AppCard(
      padding: const EdgeInsets.all(Space.m),
      onTap: () => context.push('/workout/activity/${a.id}'),
      semanticLabel: [
        a.name,
        fmtDayLong(d),
        if (distance != null) '${distance.$1} ${distance.$2}',
        if (moving != null) speakDuration(moving),
      ].join(', '),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: p.greenSoft, borderRadius: Radii.medium),
              child: Icon(activityIcon(a.kind), color: p.green),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    metaLine([
                      fmtDayMonth(d),
                      if (distance != null) '${distance.$1} ${distance.$2}',
                      if (moving != null) fmtActivityTime(moving),
                      if (pace != null) '${pace.$1} ${pace.$2}',
                    ]),
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
          ],
        ),
      ),
    );
  }
}
