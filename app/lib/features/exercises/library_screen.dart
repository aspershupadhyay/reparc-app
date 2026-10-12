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
import 'body3d/body_map_3d.dart';
import 'catalog/model.dart';
import 'library/library.dart';
import 'library/move_browser.dart';
import 'library/move_groups.dart';
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

/// Exercises section of the Workout tab. A tidy path, never a wall of
/// exercises: pick a body part, then a muscle, then its exercises in
/// labelled groups. Search finds anything in one step.
class LibraryBody extends ConsumerWidget {
  const LibraryBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final own = (ref.watch(exercisesProvider).value ?? const []).where((e) => e.catalogId == null).toList();
    final lib = ref.watch(libraryProvider).value;
    final total = lib?.moves.length;
    int? count(BodyArea a) => lib?.moves.where((m) => m.area == a).length;
    final tiles = <Widget>[
      for (final a in BodyArea.values) _AreaCard(area: a, count: count(a)),
      const _BodyMapCard(),
    ];
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
        const SectionHeader('Body parts'),
        // Two cards a row. Each row takes the height of its taller card, so
        // large text never cuts a name off.
        for (var i = 0; i < tiles.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.m),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: Space.m),
                  Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
                ],
              ),
            ),
          ),
        const SectionHeader('Tools', top: Space.l),
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

/// A large picture card: artwork on a soft tinted stage, a title, and a
/// short line under it.
class _PictureCard extends StatelessWidget {
  const _PictureCard({
    required this.art,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    required this.onTap,
  });
  final Widget art;
  final Color tint;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [tint.withValues(alpha: 0.16), tint.withValues(alpha: 0.03)],
                  ),
                ),
                child: Padding(padding: const EdgeInsets.all(Space.s), child: art),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.s, Space.m),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(subtitle, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area, required this.count});
  final BodyArea area;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final muscles = areaMuscles[area]!;
    final moves = count == null ? '' : '$count exercises';
    return _PictureCard(
      art: Image.asset(
        bodyIconAsset(area: area),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      ),
      tint: areaColors(context.pal, area).$1,
      title: area.short,
      subtitle: moves,
      semanticLabel: '${area.short}. ${muscles.map((m) => m.label).join(', ')}. $moves',
      onTap: () => context.push('/workout/area/${area.name}'),
    );
  }
}

/// Opens the 3D body: turn it and tap a muscle.
class _BodyMapCard extends StatelessWidget {
  const _BodyMapCard();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return _PictureCard(
      art: Icon(LucideIcons.rotate3D, size: 56, color: p.brand),
      tint: p.brand,
      title: '3D body',
      subtitle: 'Turn it, tap a muscle',
      semanticLabel: '3D body. Turn the body and tap a muscle',
      onTap: () => context.push('/workout/body'),
    );
  }
}

/// The 3D body map on its own page.
class BodyMapScreen extends StatelessWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D body')),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, c) => Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.l),
            child: BodyMap3D(height: c.maxHeight - Space.s - Space.l),
          ),
        ),
      ),
    );
  }
}

/// One body area: a card for each of its muscles. Arms shows Biceps,
/// Triceps, and Forearms; a tap opens that muscle's exercises.
class AreaScreen extends ConsumerWidget {
  const AreaScreen({super.key, required this.area});
  final BodyArea area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final lib = ref.watch(libraryProvider).value;
    final muscles = areaMuscles[area]!;
    return Scaffold(
      appBar: AppBar(title: Text(area.short)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: Space.xs, bottom: Space.m),
            child: Text('Pick a muscle to see its exercises.', style: t.bodyMedium?.copyWith(color: p.inkSoft)),
          ),
          for (final m in muscles)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.m),
              child: _MuscleCard(muscle: m, count: lib?.moves.where((x) => x.target == m).length),
            ),
          const SizedBox(height: Space.s),
          Center(
            child: TextButton.icon(
              onPressed: () => context.push('/workout/browse?area=${area.name}'),
              icon: const Icon(LucideIcons.search, size: 18),
              label: Text('Search all ${area.short.toLowerCase()} exercises'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleCard extends StatelessWidget {
  const _MuscleCard({required this.muscle, required this.count});
  final Muscle muscle;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final color = areaColors(p, muscle.area).$1;
    final moves = count == null ? '' : '$count exercises';
    return AppCard(
      padding: const EdgeInsets.all(Space.m),
      onTap: () => context.push('/workout/muscle/${muscle.name}'),
      semanticLabel: '${muscle.label}. ${muscle.hint}. $moves',
      child: ExcludeSemantics(
        child: Row(
          children: [
            MuscleIcon.muscle(muscle, size: 96, color: color),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(muscle.label, style: t.titleLarge),
                  const SizedBox(height: 2),
                  Text(muscle.hint, style: t.bodySmall),
                  if (count != null) ...[
                    const SizedBox(height: Space.s),
                    Tag(moves, color: color.withValues(alpha: 0.14)),
                  ],
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

/// One muscle's exercises, in labelled groups: the best picks first, then
/// the ways to train it (for example the triceps long head), then stretches
/// and power moves. One filter: All, Gym, or Home.
class MuscleScreen extends ConsumerStatefulWidget {
  const MuscleScreen({super.key, required this.muscle});
  final Muscle muscle;

  @override
  ConsumerState<MuscleScreen> createState() => _MuscleScreenState();
}

class _MuscleScreenState extends ConsumerState<MuscleScreen> {
  /// Groups opened past their first few moves.
  final _open = <String>{};

  /// Moves shown in a group before "Show more".
  static const _preview = 4;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final mu = widget.muscle;
    final color = areaColors(p, mu.area).$1;
    final place = ref.watch(placeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(mu.label)),
      body: AsyncBody(
        value: ref.watch(libraryProvider),
        builder: (lib) {
          final all = [
            for (final m in lib.moves)
              if (m.target == mu && (place == null || place.fits(m))) m,
          ];
          final picks = lib.essentialsFor(mu).where((m) => place == null || place.fits(m)).toList();
          final pickIds = {for (final m in picks) m.catalogId};
          final groups = groupMoves(mu, all.where((m) => !pickIds.contains(m.catalogId)));
          // Rows below the header: a group heading, its moves, then a
          // "Show more" button when the group is long.
          final rows = <Object>[
            if (picks.isNotEmpty) ...[_Section('Start here', 'The best moves to begin with', picks.length), ...picks],
            for (final (g, moves) in groups) ...[
              _Section(g.label, g.hint, moves.length),
              ...(_open.contains(g.label) ? moves : moves.take(_preview)),
              if (!_open.contains(g.label) && moves.length > _preview) _More(g.label, moves.length - _preview),
            ],
          ];
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                sliver: SliverList.list(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(Space.m),
                      child: Row(
                        children: [
                          MuscleIcon.muscle(mu, size: 112, color: color),
                          const SizedBox(width: Space.m),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(mu.area.short.toUpperCase(), style: sectionLabelStyle(context)),
                                const SizedBox(height: 2),
                                Text(mu.hint, style: t.bodyMedium),
                                const SizedBox(height: Space.s),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    all.length == 1 ? '1 exercise' : '${all.length} exercises',
                                    style: t.labelMedium?.copyWith(color: color),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Space.m),
                    const PlaceTabs(),
                    if (place != null)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xs, left: Space.xs),
                        child: Text(place.hint, style: t.bodySmall),
                      ),
                    if (all.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(Space.xl),
                        child: Text(
                          'Nothing for ${place?.label.toLowerCase() ?? 'this'} here yet. Try All.',
                          textAlign: TextAlign.center,
                          style: t.bodyMedium?.copyWith(color: p.inkSoft),
                        ),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
                sliver: SliverList.builder(
                  itemCount: rows.length,
                  itemBuilder: (_, i) => switch (rows[i]) {
                    final _Section s => _SectionRow(s),
                    final Move m => MoveTile(m, onTap: () => context.push(m.route)),
                    final _More more => Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setState(() => _open.add(more.group)),
                        icon: const Icon(LucideIcons.chevronDown, size: 18),
                        label: Text('Show ${more.count} more'),
                      ),
                    ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A heading inside a muscle's list, with what the group trains.
class _Section {
  const _Section(this.title, this.hint, this.count);
  final String title;
  final String hint;
  final int count;
}

/// "Show N more" under a long group.
class _More {
  const _More(this.group, this.count);
  final String group;
  final int count;
}

class _SectionRow extends StatelessWidget {
  const _SectionRow(this.s);
  final _Section s;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          s.title,
          top: Space.l,
          action: Text('${s.count}', style: t.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.only(left: Space.l, bottom: Space.s),
          child: Text(s.hint, style: t.bodySmall),
        ),
      ],
    );
  }
}

/// Full-page body-part grid, opened from Home.
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
