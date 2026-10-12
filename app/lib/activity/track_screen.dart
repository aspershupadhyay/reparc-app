import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/clock.dart';
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
import 'location_source.dart';
import 'recorder.dart';
import 'route_map.dart';

/// Starts a run, walk, or ride: explains location the first time, asks
/// the phone, then opens the recording screen (handbook 4.14).
Future<void> startActivity(BuildContext context, WidgetRef ref, ActivityKind kind) async {
  final live = ref.read(liveActivityProvider).value;
  if (live != null) {
    unawaited(context.push('/track/${live.id}'));
    return;
  }
  if (ref.read(liveSessionProvider).value != null) {
    showMessage(context, 'Finish the workout in progress first.');
    return;
  }
  final access = await ref.read(recorderProvider.notifier).start(kind);
  if (!context.mounted) return;
  switch (access) {
    case LocationAccess.allowed:
      unawaited(HapticFeedback.mediumImpact());
      final id = ref.read(liveActivityProvider).value?.id ?? (await ref.read(activityRepoProvider).live())?.id;
      if (id != null && context.mounted) unawaited(context.push('/track/$id'));
    case LocationAccess.denied:
      showMessage(context, 'RepArc needs location to measure distance and pace. Nothing was started.');
    case LocationAccess.deniedForever:
      showMessage(
        context,
        'Location is off for RepArc. Allow it in Settings to record.',
        actionLabel: 'Settings',
        onAction: () => ref.read(locationSourceProvider).openSettings(),
      );
    case LocationAccess.serviceOff:
      showMessage(
        context,
        'Turn on location for the phone to record.',
        actionLabel: 'Turn on',
        onAction: () => ref.read(locationSourceProvider).openSettings(),
      );
  }
}

/// The recording screen: time, distance, and pace in large type, the route,
/// and one main button. Built to read at a glance while moving.
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final detail = ref.watch(activityDetailProvider(id));
    final rec = ref.watch(recorderProvider);
    final unit = ref.watch(currentSettingsProvider).distanceUnit;
    final d = detail.value;
    if (d == null) {
      return Scaffold(
        appBar: AppBar(),
        body: detail.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(icon: LucideIcons.route, title: 'Not found', body: 'This activity was deleted.'),
      );
    }
    final a = d.activity;
    if (a.status == ActivityStatus.finished) {
      // Finished elsewhere (for example from the notification or a restore).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/workout/activity/$id');
      });
    }
    final paused = a.status == ActivityStatus.paused;
    final kind = a.kind;
    final (dist, distUnit) = distanceParts(d.stats.distance, unit);
    final avg = paceOrSpeed(kind, secPerKm: d.stats.paceSecPerKm, metresPerSec: d.stats.avgSpeed, unit: unit);
    final now = paceOrSpeed(kind, secPerKm: currentPace(d.stats.used), unit: unit);
    final signal = GpsSignal.of(rec.lastFix, kind, ref.watch(clockProvider)().toUtc());

    Widget big(String label, String value, String unit, {bool hero = false}) => Semantics(
      label: '$label $value $unit',
      excludeSemantics: true,
      child: Column(
        children: [
          Text(label.toUpperCase(), style: t.labelSmall?.copyWith(color: p.onPanelSoft, letterSpacing: 0.8)),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: (hero ? t.displayLarge : t.headlineMedium)?.tabular.copyWith(
                color: p.onPanel,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(unit, style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: p.panel,
      appBar: AppBar(
        backgroundColor: p.panel,
        foregroundColor: p.onPanel,
        title: Text(a.name),
        leading: IconButton(
          tooltip: 'Minimise. Recording goes on',
          icon: const Icon(LucideIcons.chevronDown),
          onPressed: () => context.canPop() ? context.pop() : context.go('/workout'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
          children: [
            Row(
              children: [
                Icon(
                  switch (signal) {
                    GpsSignal.good => LucideIcons.signalHigh,
                    GpsSignal.weak => LucideIcons.signalLow,
                    GpsSignal.none => LucideIcons.signalZero,
                  },
                  size: IconSizes.s,
                  color: signal == GpsSignal.good ? p.energy : p.orange,
                ),
                const SizedBox(width: Space.xs),
                Text(
                  paused ? 'Paused · GPS off' : (rec.lost ? 'GPS lost. Is location on?' : signal.label),
                  style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                ),
              ],
            ),
            const SizedBox(height: Space.s),
            RouteMap(points: d.stats.used, follow: !paused, height: 220),
            const SizedBox(height: Space.l),
            Ticker1s(
              builder: (_) => big(
                'Time',
                fmtActivityTime(ref.read(activityRepoProvider).elapsed(a)),
                paused ? 'paused' : 'moving ${fmtActivityTime(d.stats.moving)}',
                hero: true,
              ),
            ),
            const SizedBox(height: Space.l),
            Row(
              children: [
                Expanded(child: big('Distance', dist, distUnit)),
                Expanded(child: big(kind.showsSpeed ? 'Speed' : 'Pace', now.$1, now.$2)),
                Expanded(child: big(kind.showsSpeed ? 'Average' : 'Avg pace', avg.$1, avg.$2)),
              ],
            ),
            const SizedBox(height: Space.xl),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: p.energy,
                      foregroundColor: p.onEnergy,
                      minimumSize: const Size.fromHeight(64),
                    ),
                    onPressed: () async {
                      unawaited(HapticFeedback.selectionClick());
                      final r = ref.read(recorderProvider.notifier);
                      paused ? await r.resume(a) : await r.pause();
                    },
                    icon: Icon(paused ? LucideIcons.play : LucideIcons.pause, size: 26),
                    label: Text(paused ? 'Resume' : 'Pause', style: t.titleMedium?.copyWith(color: p.onEnergy)),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.onPanel,
                      side: BorderSide(color: p.onPanelSoft),
                      minimumSize: const Size.fromHeight(64),
                    ),
                    onPressed: () => _finish(context, ref, a, d.stats),
                    icon: const Icon(LucideIcons.flag, size: 22),
                    label: const Text('Finish'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish(BuildContext context, WidgetRef ref, GpsActivity a, TrackStats stats) async {
    final choice = await showAppSheet<String>(context, (ctx) {
      final t = Theme.of(ctx).textTheme;
      final empty = stats.distance < 10;
      return Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(empty ? 'No distance yet' : 'Finish ${a.kind.label.toLowerCase()}', style: t.titleLarge),
            const SizedBox(height: Space.s),
            Text(
              empty
                  ? 'GPS has not measured any distance. Keep going, or end without saving.'
                  : 'Saves the route, distance, and times on this phone.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Space.l),
            if (!empty) FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Finish and save')),
            if (!empty) const SizedBox(height: Space.s),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep going')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'discard'),
              style: TextButton.styleFrom(foregroundColor: ctx.pal.error),
              child: Text(empty ? 'End without saving' : 'Discard'),
            ),
          ],
        ),
      );
    });
    if (!context.mounted || choice == null) return;
    final rec = ref.read(recorderProvider.notifier);
    if (choice == 'discard') {
      if (stats.distance >= 10) {
        final sure = await confirmAction(
          context,
          title: 'Discard this ${a.kind.label.toLowerCase()}?',
          body: 'The route and times are deleted. This cannot be undone.',
          confirmLabel: 'Discard',
          destructive: true,
        );
        if (!sure || !context.mounted) return;
      }
      await rec.discard(a.id);
      if (context.mounted) {
        context.go('/workout');
        showMessage(context, '${a.kind.label} discarded.');
      }
      return;
    }
    await rec.finish(a.id);
    unawaited(HapticFeedback.heavyImpact());
    if (context.mounted) {
      context.go('/workout/activity/${a.id}');
      showMessage(context, '${a.kind.label} saved.');
    }
  }
}
