import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/analytics.dart';
import 'area_style.dart';
import 'catalog/catalog.dart';
import 'catalog/model.dart';
import 'library/library.dart';
import 'library/photo_motion.dart';
import 'library/use_move.dart';
import 'muscle_map.dart';
import 'viewer.dart';

/// Coached guide for one built-in exercise.
class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key, required this.id, this.fromWorkout = false});
  final String id;

  /// Opened from a live workout: the move is already in it, so there is no
  /// add button.
  final bool fromWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = catalogById[id];
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Exercise not found.')),
      );
    }
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final (areaColor, areaSoft) = areaColors(p, e.area);
    final live = ref.watch(liveSessionProvider).value;
    return Scaffold(
      // The large title below names the page; the bar repeats nothing.
      appBar: AppBar(),
      bottomNavigationBar: fromWorkout
          ? null
          : BottomActionBar(
              child: FilledButton.icon(
                onPressed: () => _use(context, ref, e, liveId: live?.id),
                icon: Icon(live == null ? LucideIcons.play : LucideIcons.plus, size: 20),
                label: Text(live == null ? 'Start workout with this' : 'Add to workout'),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          if (coachedPhotoPaths(e.id) case final photos?)
            PhotoMotion(photos: photos, name: e.name, height: 300)
          else
            ExerciseViewer(e, height: 380),
          const SizedBox(height: Space.l),
          Semantics(header: true, child: Text(e.name, style: t.headlineSmall)),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              Tag(e.primary.first.label, color: areaSoft),
              Tag(e.equipment, icon: LucideIcons.dumbbell),
              Tag(e.level.label, icon: LucideIcons.gauge),
            ],
          ),
          const SizedBox(height: Space.m),
          Text(e.summary, style: t.bodyLarge),
          const SizedBox(height: Space.l),
          _Muscles(e: e, areaColor: areaColor),
          const SizedBox(height: Space.m),
          // Equal heights, and a range such as "8–12" never splits.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: LucideIcons.repeat,
                    label: e.timed ? 'Hold' : 'Sets × reps',
                    text: e.dose.split(' · ').map((x) => x.replaceAll(' ', '\u00A0')).join('\n'),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: _InfoTile(icon: LucideIcons.timer, label: 'Tempo', text: e.tempo),
                ),
              ],
            ),
          ),
          SectionHeader('Set up', top: Space.xl),
          // Plain dots: a teal chevron reads as a link.
          _Bullets(items: e.setup, icon: LucideIcons.dot, color: p.inkSoft),
          const SectionHeader('How to do it'),
          StepsCard(items: e.steps),
          const SectionHeader('Breathing'),
          AppCard(
            color: p.brandSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.wind, color: p.brand),
                const SizedBox(width: Space.m),
                Expanded(child: Text(e.breathing, style: t.bodyMedium)),
              ],
            ),
          ),
          const SectionHeader('Coach cues'),
          AppCard(
            color: p.panel,
            child: Column(
              children: [
                for (final c in e.cues)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(LucideIcons.megaphone, size: 18, color: p.energy),
                        const SizedBox(width: Space.m),
                        Expanded(
                          child: Text('“$c”', style: t.titleSmall?.copyWith(color: p.onPanel)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionHeader('Avoid'),
          _Bullets(items: e.mistakes, icon: LucideIcons.circleX, color: p.coral),
          const SectionHeader('Adjust it'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoTile(icon: LucideIcons.arrowDown, label: 'Easier', text: e.easier, color: p.greenSoft),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: _InfoTile(icon: LucideIcons.arrowUp, label: 'Harder', text: e.harder, color: p.orangeSoft),
              ),
            ],
          ),
          ExerciseHistory(catalogId: e.id),
          const SizedBox(height: Space.xl),
          StatusLine(
            icon: LucideIcons.info,
            text: 'General coaching for healthy adults. Not medical advice. Stop if you feel sharp pain.',
          ),
        ],
      ),
    );
  }

  Future<void> _use(BuildContext context, WidgetRef ref, ExerciseDef e, {String? liveId}) => useMove(
    context,
    ref,
    catalogId: e.id,
    name: e.name,
    equipment: e.equipment,
    muscles: e.primary.map((m) => m.label).join(', '),
    liveId: liveId,
  );
}

class _Muscles extends StatelessWidget {
  const _Muscles({required this.e, required this.areaColor});
  final ExerciseDef e;
  final Color areaColor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    Widget row(String label, Color dot, Iterable<String> names) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  // Flexible so large text wraps instead of overflowing.
                  Flexible(child: Text(label, style: t.labelSmall)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [for (final n in names) Tag(n, color: p.surface)]),
          ),
        ],
      ),
    );
    return AppCard(
      color: p.surface,
      child: Column(
        children: [
          BodyMap(primary: e.primary, secondary: e.secondary, hot: p.coral, warm: p.orange, body: p.line, height: 170),
          const SizedBox(height: Space.m),
          row('Main', p.coral, e.primary.map((m) => m.label)),
          if (e.secondary.isNotEmpty) row('Helpers', p.orange, e.secondary.map((m) => m.label)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.text, this.color});
  final IconData icon;
  final String label;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.pal.inkSoft),
              const SizedBox(width: 6),
              Text(label, style: t.labelSmall),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(text, style: t.titleSmall),
        ],
      ),
    );
  }
}

class _Bullets extends StatelessWidget {
  const _Bullets({required this.items, required this.icon, required this.color});
  final List<String> items;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        children: [
          for (final s in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text(s, style: t.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class StepsCard extends StatelessWidget {
  const StepsCard({super.key, required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        children: [
          for (final (i, s) in items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
                    child: Text('${i + 1}', style: t.labelMedium?.copyWith(color: p.surface)),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(s, style: t.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The user's own sets for this exercise, if any.
class ExerciseHistory extends ConsumerWidget {
  const ExerciseHistory({super.key, required this.catalogId});
  final String catalogId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref.watch(catalogExerciseProvider(catalogId)).value;
    if (row == null) return const SizedBox.shrink();
    final sets = ref.watch(exerciseHistoryProvider(row.id)).value ?? const [];
    if (sets.isEmpty) return const SizedBox.shrink();
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final records = heaviestLoads(sets);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Your history'),
        for (final r in records)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s),
            child: AppCard(
              color: p.panel,
              onTap: () => context.push('/workout/session/${r.source.session.id}'),
              child: Row(
                children: [
                  IconBadge(LucideIcons.trophy, color: p.energy, size: 40),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Metric(
                      label: 'Best load',
                      value: fmtWithUnit(r.source.set.load, r.source.set.loadUnit),
                      note: fmtDayShort(
                        localDayOfInstant(r.source.session.startedAt, r.source.session.utcOffsetMinutes),
                      ),
                      color: p.onPanel,
                      labelColor: p.onPanelSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.s),
          child: Column(
            children: [
              for (final r in sets.take(5))
                ListTile(
                  dense: true,
                  title: Text(
                    [
                      fmtWithUnit(r.set.load, r.set.loadUnit),
                      if (r.set.reps != null) '× ${r.set.reps}',
                    ].join(' '),
                    style: t.bodyLarge?.tabular,
                  ),
                  trailing: Text(
                    fmtDayShort(localDayOfInstant(r.session.startedAt, r.session.utcOffsetMinutes)),
                    style: t.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
