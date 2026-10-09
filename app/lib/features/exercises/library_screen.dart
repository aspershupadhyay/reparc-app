import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../workout/exercise_form.dart';
import 'area_style.dart';
import 'catalog/model.dart';
import 'library/library.dart';
import 'library/move_browser.dart';
import 'muscle_map.dart';
import 'rig/anatomy.dart';

/// Area filter chips with each area's own body icon. Null means all areas.
class AreaChips extends StatelessWidget {
  const AreaChips({super.key, required this.selected, required this.onChanged});
  final BodyArea? selected;
  final ValueChanged<BodyArea?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget chip(String label, Widget? icon, bool sel, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: Space.s),
      child: Semantics(
        selected: sel,
        button: true,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: sel ? p.ink : p.surface,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: EdgeInsets.only(left: icon == null ? Space.l : 6, right: Space.l),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[icon, const SizedBox(width: 6)],
                  Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: sel ? p.surface : p.ink)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', null, selected == null, () => onChanged(null)),
          for (final a in BodyArea.values)
            chip(
              a.short,
              MuscleIcon.area(a, size: 32, color: areaColors(p, a).$1),
              selected == a,
              () => onChanged(a),
            ),
        ],
      ),
    );
  }
}

/// Exercises section of the Workout tab. Three steps, never a wall of
/// exercises: pick a body area, pick a muscle, then start with a few
/// hand-picked moves. The full list stays one tap away.
class LibraryBody extends ConsumerWidget {
  const LibraryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final own = (ref.watch(exercisesProvider).value ?? const []).where((e) => e.catalogId == null).toList();
    final lib = ref.watch(libraryProvider).value;
    final total = lib?.moves.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () => context.push('/workout/browse'),
          semanticLabel: 'Search ${total ?? ''} exercises',
          padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
          radius: Radii.small,
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(LucideIcons.search, size: IconSizes.s, color: p.inkSoft),
                const SizedBox(width: Space.s),
                Expanded(
                  child: Text(
                    total == null ? 'Search exercises' : 'Search $total exercises or muscles',
                    style: t.bodyLarge?.copyWith(color: p.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SectionHeader('Pick a body part'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, a) in BodyArea.values.indexed) ...[
                if (i > 0) const Divider(indent: 72),
                _AreaRow(area: a, count: lib?.moves.where((m) => m.area == a && m.kind == MoveKind.strength).length),
              ],
            ],
          ),
        ),
        const SectionHeader('Tools'),
        AppCard(
          onTap: () => context.push('/workout/calculator'),
          semanticLabel: 'Weight calculator. Find your working weight',
          child: ExcludeSemantics(
            child: Row(
              children: [
                IconBadge(LucideIcons.calculator, color: p.brandSoft, glyph: p.brand, size: 44),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weight calculator', style: t.titleMedium),
                      Text('How much to lift, from your last set or your experience', style: t.bodySmall),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
              ],
            ),
          ),
        ),
        SectionHeader(
          'Your exercises',
          action: TextButton.icon(
            onPressed: () => showExerciseForm(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New'),
          ),
        ),
        if (own.isEmpty)
          Text('Add your own movements here.', style: t.bodyMedium?.copyWith(color: p.inkSoft))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, e) in own.indexed) ...[
                  if (i > 0) const Divider(indent: Space.l),
                  ListTile(
                    title: Text(exerciseTitle(e)),
                    subtitle: e.equipment == null ? null : Text(e.equipment!),
                    trailing: const Icon(LucideIcons.chevronRight, size: IconSizes.s),
                    onTap: () => context.push('/workout/exercise/${e.id}'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area, required this.count});
  final BodyArea area;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final muscles = areaMuscles[area]!;
    return Semantics(
      button: true,
      label: '${area.label}: ${muscles.map((m) => m.label).join(', ')}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => context.push('/workout/area/${area.name}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
          child: Row(
            children: [
              MuscleIcon.area(area, size: 48, color: areaColors(p, area).$1),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area.short, style: t.titleMedium),
                    Text(
                      muscles.length == 1 ? muscles.first.hint : muscles.map((m) => m.label).join(' · '),
                      style: t.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (count != null) Text('$count', style: t.bodySmall),
              const SizedBox(width: Space.xs),
              Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// One body area: choose a muscle, see where to start, then the rest.
class AreaScreen extends ConsumerStatefulWidget {
  const AreaScreen({super.key, required this.area, this.onPick, this.pickIcon});
  final BodyArea area;

  /// When set, tapping a move picks it (for example, to add to a workout).
  final void Function(Move)? onPick;
  final IconData? pickIcon;

  @override
  ConsumerState<AreaScreen> createState() => _AreaScreenState();
}

class _AreaScreenState extends ConsumerState<AreaScreen> {
  late Muscle _muscle = areaMuscles[widget.area]!.first;
  EquipKind? _equip;
  MoveKind _kind = MoveKind.strength;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final lib = ref.watch(libraryProvider);
    final muscles = areaMuscles[widget.area]!;
    final color = areaColors(p, widget.area).$1;
    void open(Move m) => widget.onPick != null ? widget.onPick!(m) : context.push(m.route);
    return Scaffold(
      appBar: AppBar(title: Text(widget.area.short)),
      body: AsyncBody(
        value: lib,
        builder: (lib) {
          final all = lib.moves.where((m) => m.target == _muscle && m.kind == _kind).toList();
          final equips = {for (final m in all) m.equipKind}.toList()..sort((a, b) => a.index.compareTo(b.index));
          final shown = _equip == null ? all : all.where((m) => m.equipKind == _equip).toList();
          final starts = _kind == MoveKind.strength
              ? lib.essentialsFor(_muscle).where((m) => _equip == null || m.equipKind == _equip).toList()
              : const <Move>[];
          final startIds = {for (final m in starts) m.catalogId};
          final rest = shown.where((m) => !startIds.contains(m.catalogId)).toList();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                sliver: SliverList.list(
                  children: [
                    if (muscles.length > 1)
                      // Same height for every tile, even when one name takes
                      // two lines at large text sizes.
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final m in muscles)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3),
                                  child: _MuscleChoice(
                                    muscle: m,
                                    color: color,
                                    selected: m == _muscle,
                                    onTap: () => setState(() {
                                      _muscle = m;
                                      _equip = null;
                                    }),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    else
                      Center(child: MuscleIcon.muscle(_muscle, size: 72, color: color)),
                    const SizedBox(height: Space.s),
                    // A quieter second-level control: the muscle above is the
                    // main choice (visual review, 2026-10-09).
                    PillTabs<MoveKind>(
                      compact: true,
                      values: MoveKind.values,
                      selected: _kind,
                      label: (k) => k.label,
                      onChanged: (k) => setState(() {
                        _kind = k;
                        _equip = null;
                      }),
                    ),
                    const SizedBox(height: Space.s),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final e in [null, ...equips])
                            Padding(
                              padding: const EdgeInsets.only(right: Space.s),
                              child: ChoiceChip(
                                label: Text(e?.label ?? 'Any equipment'),
                                selected: _equip == e,
                                onSelected: (_) => setState(() => _equip = e),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (starts.isNotEmpty) ...[
                      SectionHeader('Start here', top: Space.l),
                      Padding(
                        padding: const EdgeInsets.only(left: Space.l),
                        child: Text(
                          '${_muscle.hint}. The best moves for ${_muscle.label.toLowerCase()}: pick one or two '
                          'that fit your gym.',
                          style: t.bodySmall,
                        ),
                      ),
                      const SizedBox(height: Space.s),
                      for (final m in starts)
                        MoveTile(m, onTap: () => open(m), icon: widget.pickIcon ?? LucideIcons.chevronRight),
                    ],
                    SectionHeader(
                      starts.isEmpty ? 'All ${_kind.label.toLowerCase()} moves' : 'More options',
                      top: Space.l,
                      action: Text('${rest.length}', style: t.bodySmall),
                    ),
                    if (rest.isEmpty)
                      Text('Nothing else here. Try "Any equipment".', style: t.bodyMedium?.copyWith(color: p.inkSoft)),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
                sliver: SliverList.builder(
                  itemCount: rest.length,
                  itemBuilder: (_, i) =>
                      MoveTile(rest[i], onTap: () => open(rest[i]), icon: widget.pickIcon ?? LucideIcons.chevronRight),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MuscleChoice extends StatelessWidget {
  const _MuscleChoice({required this.muscle, required this.color, required this.selected, required this.onTap});
  final Muscle muscle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      label: muscle.label,
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: Radii.medium,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.quick,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: Space.xs),
            decoration: BoxDecoration(
              borderRadius: Radii.medium,
              border: Border.all(color: selected ? color : Colors.transparent, width: 2),
            ),
            // Icon above the name. Side by side, four tiles left too little
            // width and names broke mid-word ("Qu ad", "Forearm s"; phone
            // test, 2026-10-10).
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MuscleIcon.muscle(muscle, size: 32, color: selected ? color : p.inkSoft),
                const SizedBox(height: 2),
                Text(
                  muscle.label,
                  textAlign: TextAlign.center,
                  style: (selected ? t.labelMedium : t.bodyMedium)?.copyWith(color: selected ? p.ink : p.inkSoft),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-page body-area list, opened from Home.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: const [LibraryBody()],
      ),
    );
  }
}
