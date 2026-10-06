import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/palette.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets.dart';
import '../../../data/providers.dart';
import '../area_style.dart';
import '../guide_screen.dart';
import '../muscle_map.dart';
import 'library.dart';
import 'photo_motion.dart';
import 'use_move.dart';

/// Detail page for one library exercise: photos, muscles, and steps.
class MoveScreen extends ConsumerWidget {
  const MoveScreen({super.key, required this.id, this.fromWorkout = false});
  final String id;

  /// Opened from a live workout: the move is already in it, so there is no
  /// add button.
  final bool fromWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lib = ref.watch(libraryProvider);
    final live = ref.watch(liveSessionProvider).value;
    final e = lib.value?.byId[id];
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: lib.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Exercise not found.')),
      );
    }
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final (_, areaSoft) = areaColors(p, e.area);
    return Scaffold(
      appBar: AppBar(title: Text(e.target.label)),
      bottomNavigationBar: fromWorkout
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
                child: FilledButton.icon(
                  onPressed: () => useMove(
                    context,
                    ref,
                    catalogId: e.catalogId,
                    name: e.name,
                    equipment: e.equipment == 'No equipment' ? null : e.equipment,
                    muscles: e.primary.join(', '),
                    liveId: live?.id,
                  ),
                  icon: Icon(live == null ? LucideIcons.play : LucideIcons.plus, size: 20),
                  label: Text(live == null ? 'Start workout with this' : 'Add to workout'),
                ),
              ),
            ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          PhotoMotion(photos: (e.startPhoto, e.endPhoto), name: e.name),
          const SizedBox(height: Space.l),
          Semantics(header: true, child: Text(e.name, style: t.headlineSmall)),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              Tag(e.target.label, color: areaSoft),
              Tag(e.equipment, icon: LucideIcons.dumbbell),
              Tag(e.level.label, icon: LucideIcons.gauge),
              Tag(e.categoryLabel, icon: LucideIcons.layers),
              if (e.mechanic != null) Tag(e.mechanic == 'compound' ? 'Compound' : 'Isolation'),
            ],
          ),
          const SizedBox(height: Space.l),
          AppCard(
            color: p.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyMap(
                  primary: {for (final m in e.primary) targetMuscle(m, e.name)},
                  secondary: {for (final m in e.secondary) targetMuscle(m, e.name)},
                  hot: p.coral,
                  warm: p.orange,
                  body: p.line,
                  height: 170,
                ),
                const SizedBox(height: Space.m),
                _MuscleRow(label: 'Main', dot: p.coral, names: e.primary),
                if (e.secondary.isNotEmpty) _MuscleRow(label: 'Helpers', dot: p.orange, names: e.secondary),
              ],
            ),
          ),
          if (e.steps.isNotEmpty) ...[const SectionHeader('How to do it'), StepsCard(items: e.steps)],
          ExerciseHistory(catalogId: e.catalogId),
          const SizedBox(height: Space.xl),
          const StatusLine(
            icon: LucideIcons.info,
            text: 'General guidance for healthy adults. Not medical advice. Stop if you feel sharp pain.',
          ),
          const SizedBox(height: Space.s),
          Text(
            'Photos and steps: Free Exercise DB, public domain.',
            style: t.bodySmall?.copyWith(color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow({required this.label, required this.dot, required this.names});
  final String label;
  final Color dot;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
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
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final n in names) Tag(n, color: context.pal.surface)],
            ),
          ),
        ],
      ),
    );
  }
}
