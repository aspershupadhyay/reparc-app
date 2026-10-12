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
import '../data/activity_repository.dart';
import '../data/providers.dart';
import '../domain/track.dart';
import 'activity_format.dart';
import 'route_map.dart';

/// A saved run, walk, or ride (handbook 4.14).
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(activityDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.activity.name ?? 'Activity'),
        actions: [
          if (detail.value != null)
            PopupMenuButton<String>(
              tooltip: 'Activity options',
              icon: const Icon(LucideIcons.ellipsisVertical),
              onSelected: (v) =>
                  v == 'rename' ? _rename(context, ref, detail.value!) : _delete(context, ref, detail.value!),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: AsyncBody(
        value: detail,
        builder: (d) => d == null
            ? const EmptyState(icon: LucideIcons.route, title: 'Not found', body: 'This activity was deleted.')
            : _Body(d),
      ),
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, ActivityDetail d) async {
    final name = await promptText(context, title: 'Rename', label: 'Name', initial: d.activity.name);
    if (name != null && context.mounted) {
      await guardedWrite(context, () => ref.read(activityRepoProvider).rename(d.activity.id, name));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ActivityDetail d) async {
    final sure = await confirmAction(
      context,
      title: 'Delete ${d.activity.name}?',
      body: 'The route, distance, and times are deleted from this phone. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!sure || !context.mounted) return;
    await ref.read(activityRepoProvider).delete(d.activity.id);
    if (context.mounted) {
      context.pop();
      showMessage(context, '${d.activity.kind.label} deleted.');
    }
  }
}

class _Body extends ConsumerWidget {
  const _Body(this.d);
  final ActivityDetail d;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final unit = ref.watch(currentSettingsProvider).distanceUnit;
    final a = d.activity;
    final s = d.stats;
    final day = localDayOfInstant(a.startedAt, a.utcOffsetMinutes);
    final start = a.startedAt.toUtc().add(Duration(minutes: a.utcOffsetMinutes));
    final (dist, distUnit) = distanceParts(s.distance, unit);
    final avg = paceOrSpeed(a.kind, secPerKm: s.paceSecPerKm, metresPerSec: s.avgSpeed, unit: unit);
    final elapsed = ref.read(activityRepoProvider).elapsed(a);
    final miles = unit == 'mi';

    Widget stat(String label, String value, [String? unit]) => Expanded(
      child: Metric(label: label, value: value, unit: unit),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
      children: [
        Text(
          '${fmtDayLong(day)} · ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}',
          style: t.bodySmall,
        ),
        const SizedBox(height: Space.m),
        RouteMap(
          points: s.used,
          height: 280,
          semanticLabel: 'Map of the route, ${speakDistance(s.distance, unit)}.',
        ),
        const SizedBox(height: Space.l),
        AppCard(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            children: [
              Row(
                children: [
                  stat('Distance', dist, distUnit),
                  stat(a.kind.showsSpeed ? 'Avg speed' : 'Avg pace', avg.$1, avg.$2),
                ],
              ),
              const SizedBox(height: Space.l),
              Row(
                children: [
                  stat('Moving time', fmtActivityTime(s.moving)),
                  stat('Elapsed', fmtActivityTime(elapsed)),
                ],
              ),
              const SizedBox(height: Space.l),
              Row(
                children: [
                  stat(
                    'Climb',
                    s.elevationGain == null
                        ? '–'
                        : fmtNum(miles ? s.elevationGain! * 3.28084 : s.elevationGain!, maxDecimals: 0),
                    s.elevationGain == null ? null : (miles ? 'ft' : 'm'),
                  ),
                  stat(
                    'Top speed',
                    s.maxSpeed == null ? '–' : (miles ? s.maxSpeed! * 2.236936 : s.maxSpeed! * 3.6).toStringAsFixed(1),
                    s.maxSpeed == null ? null : (miles ? 'mph' : 'km/h'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (s.splits.length > 1) ...[
          const SectionHeader('Splits'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
            child: Column(
              children: [
                for (final sp in s.splits)
                  _SplitRow(
                    label: sp.metres < (miles ? 1609 : 1000)
                        ? '${(sp.metres / (miles ? 1609.344 : 1000)).toStringAsFixed(2)} ${miles ? 'mi' : 'km'}'
                        : '${miles ? 'Mile' : 'Km'} ${sp.index}',
                    value: paceOrSpeed(
                      a.kind,
                      metresPerSec: sp.time.inMilliseconds == 0 ? null : sp.metres / (sp.time.inMilliseconds / 1000),
                      unit: unit,
                    ),
                    fraction: _fraction(sp.time.inMilliseconds / sp.metres, s.splits),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.m),
        StatusLine(
          icon: LucideIcons.info,
          text: 'Measured with GPS on this phone. Moving time leaves out stops. Climb is an estimate from GPS height.',
        ),
        if (a.note != null) ...[const SizedBox(height: Space.m), Text(a.note!, style: t.bodyMedium)],
        Padding(
          padding: const EdgeInsets.only(top: Space.l),
          child: Text(
            '${s.used.length} GPS points. The route stays on this phone.',
            style: t.bodySmall?.copyWith(color: p.inkSoft),
          ),
        ),
      ],
    );
  }

  /// How fast this split was against the fastest one, 0 to 1, for the bar.
  static double _fraction(double msPerMetre, List<TrackSplit> splits) {
    var best = double.infinity;
    for (final sp in splits) {
      final v = sp.time.inMilliseconds / sp.metres;
      if (v > 0 && v < best) best = v;
    }
    return msPerMetre <= 0 || !best.isFinite ? 0 : (best / msPerMetre).clamp(0.05, 1.0);
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({required this.label, required this.value, required this.fraction});
  final String label;
  final (String, String) value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Semantics(
      label: '$label, ${value.$1} ${value.$2}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.xs),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: t.bodyMedium)),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 8,
                  color: p.brand,
                  backgroundColor: p.brandSoft,
                ),
              ),
            ),
            const SizedBox(width: Space.m),
            SizedBox(
              width: 92,
              child: Text('${value.$1} ${value.$2}', textAlign: TextAlign.end, style: t.bodyMedium?.tabular),
            ),
          ],
        ),
      ),
    );
  }
}

/// "2.3 kilometres" for screen readers.
String speakDistance(double metres, String unit) => switch (unit) {
  'mi' => '${(metres / 1609.344).toStringAsFixed(1)} miles',
  'm' => '${metres.round()} metres',
  _ => '${(metres / 1000).toStringAsFixed(1)} kilometres',
};
