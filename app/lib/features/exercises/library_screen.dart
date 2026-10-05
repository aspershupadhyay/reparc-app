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
import 'catalog/catalog.dart';
import 'catalog/model.dart';
import 'viewer.dart';

/// Area filter chips. Null means all areas.
class AreaChips extends StatelessWidget {
  const AreaChips({super.key, required this.selected, required this.onChanged});
  final BodyArea? selected;
  final ValueChanged<BodyArea?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    Widget chip(String label, IconData? icon, bool sel, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(right: Space.s),
      child: Semantics(
        selected: sel,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: sel ? p.ink : p.surface,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: Space.l),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 16, color: sel ? p.surface : p.inkSoft),
                    const SizedBox(width: 6),
                  ],
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
          chip('All', LucideIcons.layers, selected == null, () => onChanged(null)),
          for (final a in BodyArea.values) chip(a.short, a.icon, selected == a, () => onChanged(a)),
        ],
      ),
    );
  }
}

/// A card with a still body-model picture.
class ExerciseCard extends StatelessWidget {
  const ExerciseCard(this.e, {super.key, required this.onTap, this.trailing});
  final ExerciseDef e;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final (c, soft) = areaColors(p, e.area);
    return Semantics(
      button: true,
      label: '${e.name}. ${e.area.label}. ${e.equipment}. ${e.level.label}',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: Radii.large,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  ExerciseThumb(e, height: 130),
                  Positioned(
                    left: Space.s,
                    top: Space.s,
                    child: Tag(e.area.short, color: soft, textColor: p.ink),
                  ),
                  if (trailing != null) Positioned(right: 4, top: 4, child: trailing!),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, Space.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(e.level.label, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
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

/// Grid of built-in exercises for one area, or all of them.
class CatalogGrid extends StatelessWidget {
  const CatalogGrid({super.key, required this.items, required this.onTap});
  final List<ExerciseDef> items;
  final void Function(ExerciseDef) onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth > 600 ? 3 : 2;
        final w = (c.maxWidth - Space.m * (cols - 1)) / cols;
        return Wrap(
          spacing: Space.m,
          runSpacing: Space.m,
          children: [
            for (final e in items)
              SizedBox(
                width: w,
                child: ExerciseCard(e, onTap: () => onTap(e)),
              ),
          ],
        );
      },
    );
  }
}

/// Exercise library: built-in coached exercises by body area, and the
/// user's own exercises.
class LibraryBody extends ConsumerStatefulWidget {
  const LibraryBody({super.key});

  @override
  ConsumerState<LibraryBody> createState() => _LibraryBodyState();
}

class _LibraryBodyState extends ConsumerState<LibraryBody> {
  BodyArea? _area;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final q = _q.text.trim().toLowerCase();
    final own = (ref.watch(exercisesProvider).value ?? const []).where((e) => e.catalogId == null).toList();
    bool match(String s) => q.isEmpty || s.toLowerCase().contains(q);
    final areas = _area == null ? BodyArea.values : [_area!];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _q,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.search, size: IconSizes.s),
            hintText: 'Search ${catalog.length} exercises',
            fillColor: context.pal.surface,
          ),
        ),
        const SizedBox(height: Space.m),
        AreaChips(selected: _area, onChanged: (a) => setState(() => _area = a)),
        for (final a in areas)
          if (exercisesFor(a).where((e) => match('${e.name} ${e.equipment} ${e.area.label}')).isNotEmpty) ...[
            SectionHeader(a.label, action: Text('${exercisesFor(a).length}', style: t.bodySmall)),
            CatalogGrid(
              items: exercisesFor(a).where((e) => match('${e.name} ${e.equipment} ${e.area.label}')).toList(),
              onTap: (e) => context.push('/workout/guide/${e.id}'),
            ),
          ],
        SectionHeader(
          'Your exercises',
          action: TextButton.icon(
            onPressed: () => showExerciseForm(context),
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('New'),
          ),
        ),
        if (own.isEmpty)
          Text('Add your own movements here.', style: t.bodyMedium?.copyWith(color: context.pal.inkSoft))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, e) in own.where((e) => match(e.name)).indexed) ...[
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

/// Full-page library, opened from Home.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise library')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: const [LibraryBody()],
      ),
    );
  }
}
