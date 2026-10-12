import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/format.dart';
import '../../../core/palette.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets.dart';
import '../area_style.dart';
import '../catalog/model.dart';
import '../library_screen.dart';
import '../muscle_map.dart';
import '../rig/anatomy.dart';
import 'library.dart';
import 'move_groups.dart';
import 'photo_motion.dart';

/// Search, filter, and scroll every movement. The list builds rows lazily,
/// so it stays fast with hundreds of entries.
class MoveBrowser extends ConsumerStatefulWidget {
  const MoveBrowser({
    super.key,
    required this.onTap,
    this.initialArea,
    this.leading = const [],
    this.leadingWhen,
    this.trailingIcon = LucideIcons.chevronRight,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.l),
    this.autofocus = false,
  });

  final void Function(Move) onTap;
  final BodyArea? initialArea;

  /// Rows shown above the results, for example "Create your own".
  final List<Widget> leading;

  /// Builds extra rows from the current search text (as typed) and area.
  final List<Widget> Function(String query, BodyArea? area)? leadingWhen;
  final IconData trailingIcon;
  final EdgeInsets padding;
  final bool autofocus;

  @override
  ConsumerState<MoveBrowser> createState() => _MoveBrowserState();
}

class _MoveBrowserState extends ConsumerState<MoveBrowser> {
  final _q = TextEditingController();
  late BodyArea? _area = widget.initialArea;

  /// One muscle inside [_area], or null for the whole area.
  Muscle? _muscle;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final lib = ref.watch(libraryProvider);
    final q = _q.text.trim().toLowerCase();
    final place = ref.watch(placeProvider);
    return lib.when(
      loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading exercises')),
      error: (e, _) => Center(child: Text('Could not load the exercise library. $e')),
      data: (lib) {
        final muscles = _area == null ? const <Muscle>[] : areaMuscles[_area]!;
        final filtered = [
          for (final m in lib.moves)
            if ((_area == null || m.area == _area) &&
                (_muscle == null || m.target == _muscle) &&
                (place == null || place.fits(m)))
              m,
        ];
        // A search ranks the best matches first. With no search and a body
        // part chosen, the list follows the tree: each muscle (or each group
        // inside one muscle) under its own heading, hand-picked moves first.
        final rows = <Object>[];
        if (q.isNotEmpty || _area == null) {
          rows.addAll(lib.search(q, within: filtered));
        } else {
          final ids = {for (final m in filtered) m.catalogId};
          for (final mu in _muscle == null ? muscles : [_muscle!]) {
            final picks = [
              for (final m in lib.essentialsFor(mu))
                if (ids.contains(m.catalogId)) m,
            ];
            final pickIds = {for (final m in picks) m.catalogId};
            final rest = filtered.where((m) => m.target == mu && !pickIds.contains(m.catalogId)).toList();
            if (_muscle == null) {
              if (picks.isEmpty && rest.isEmpty) continue;
              rows
                ..add(_Heading(mu.label, mu.hint, picks.length + rest.length))
                ..addAll(picks)
                ..addAll(rest);
            } else {
              if (picks.isNotEmpty) {
                rows.addAll([_Heading('Start here', 'The best moves to begin with', picks.length), ...picks]);
              }
              for (final (g, moves) in groupMoves(mu, rest)) {
                rows.addAll([_Heading(g.label, g.hint, moves.length), ...moves]);
              }
            }
          }
        }
        final count = rows.whereType<Move>().length;
        final typing = MediaQuery.viewInsetsOf(context).bottom > 0;
        final extra = [...widget.leading, ...?widget.leadingWhen?.call(_q.text.trim(), _area)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: widget.padding,
              child: TextField(
                controller: _q,
                autofocus: widget.autofocus,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.search, size: IconSizes.s),
                  hintText: 'Search exercises or muscles',
                  fillColor: p.surface,
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(LucideIcons.x, size: IconSizes.s),
                          onPressed: () => setState(_q.clear),
                        ),
                ),
              ),
            ),
            // While the keyboard is open, hide the filters so results have room.
            if (!typing) ...[
              const SizedBox(height: Space.m),
              Padding(
                padding: EdgeInsets.only(left: widget.padding.left),
                child: AreaChips(
                  selected: _area,
                  onChanged: (a) => setState(() {
                    _area = a;
                    _muscle = null;
                  }),
                ),
              ),
              if (muscles.length > 1) ...[
                const SizedBox(height: Space.s),
                Padding(
                  padding: widget.padding,
                  child: _MuscleChips(
                    area: _area!,
                    muscles: muscles,
                    selected: _muscle,
                    onChanged: (m) => setState(() => _muscle = m),
                  ),
                ),
              ],
              const SizedBox(height: Space.s),
              Padding(padding: widget.padding, child: const PlaceTabs()),
            ],
            Padding(
              padding: EdgeInsets.fromLTRB(widget.padding.left, Space.m, widget.padding.right, Space.xs),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  count == 1 ? '1 exercise' : '$count exercises',
                  style: t.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(widget.padding.left, Space.s, widget.padding.right, Space.xxl),
                itemCount: extra.length + (rows.isEmpty ? 1 : rows.length),
                itemBuilder: (context, i) {
                  if (i < extra.length) return extra[i];
                  if (rows.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Text(
                        'No match. Try a shorter word, or clear a filter.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: p.inkSoft),
                      ),
                    );
                  }
                  return switch (rows[i - extra.length]) {
                    final _Heading h => _HeadingRow(h),
                    final Move m => MoveTile(m, icon: widget.trailingIcon, onTap: () => widget.onTap(m)),
                    _ => const SizedBox.shrink(),
                  };
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A heading inside the list: a muscle, a group, or "Start here".
class _Heading {
  const _Heading(this.title, this.hint, this.count);
  final String title;
  final String hint;
  final int count;
}

class _HeadingRow extends StatelessWidget {
  const _HeadingRow(this.h);
  final _Heading h;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            h.title,
            top: Space.m,
            action: Text('${h.count}', style: t.bodySmall),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Space.l),
            child: Text(h.hint, style: t.bodySmall),
          ),
        ],
      ),
    );
  }
}

/// Second step under a body part: the whole area, or one muscle in it.
class _MuscleChips extends StatelessWidget {
  const _MuscleChips({required this.area, required this.muscles, required this.selected, required this.onChanged});
  final BodyArea area;
  final List<Muscle> muscles;
  final Muscle? selected;
  final ValueChanged<Muscle?> onChanged;

  @override
  Widget build(BuildContext context) {
    // A wrap, not a side scroll: at most five chips, and every muscle
    // stays in view.
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final m in [null, ...muscles])
          ChoiceChip(
            label: Text(m?.label ?? 'All ${area.short.toLowerCase()}'),
            selected: selected == m,
            onSelected: (_) => onChanged(m),
          ),
      ],
    );
  }
}

/// All, Gym, or Home: the one equipment filter in browse lists. The choice
/// stays while the app is open.
class PlaceTabs extends ConsumerWidget {
  const PlaceTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      label: 'Where you train',
      child: PillTabs<Place?>(
        values: const [null, Place.gym, Place.home],
        selected: ref.watch(placeProvider),
        label: (v) => v?.label ?? 'All',
        icon: (v) => switch (v) {
          null => LucideIcons.layers,
          Place.gym => LucideIcons.dumbbell,
          Place.home => LucideIcons.house,
        },
        onChanged: ref.read(placeProvider.notifier).set,
      ),
    );
  }
}

/// One movement in a list: photo, name, area, equipment, and level.
class MoveTile extends StatelessWidget {
  const MoveTile(this.m, {super.key, required this.onTap, this.icon = LucideIcons.chevronRight});
  final Move m;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final (dot, _) = areaColors(p, m.area);
    final photos = m.photos;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: AppCard(
        padding: const EdgeInsets.all(Space.s),
        onTap: onTap,
        semanticLabel:
            '${m.name}. ${m.target.label}. ${m.equipment}. ${m.level.label}${m.coached != null ? '. Coached guide' : ''}',
        child: ExcludeSemantics(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: Radii.small,
                child: photos == null
                    ? SizedBox(width: 72, height: 56, child: ColoredBox(color: p.surfaceAlt))
                    : PhotoThumb(photos.$1, width: 72, height: 56),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: t.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          // Two lines, so "Beginner" is not cut to "Begin…".
                          child: Text(
                            metaLine([m.target.label, m.equipment, m.level.label]),
                            style: t.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (m.coached != null) ...[
                      const SizedBox(height: 4),
                      Tag('Coached guide', color: p.brandSoft, icon: LucideIcons.graduationCap),
                    ],
                  ],
                ),
              ),
              // A chevron only opens a page, so it is grey like every other
              // chevron. An add icon is an action, so it keeps the tint.
              Icon(icon, color: icon == LucideIcons.chevronRight ? p.inkSoft : p.brand, size: IconSizes.s),
              const SizedBox(width: Space.s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page browser for every exercise.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key, this.area});
  final BodyArea? area;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(area == null ? 'All exercises' : area!.label)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: Space.s),
          child: MoveBrowser(initialArea: area, onTap: (m) => context.push(m.route)),
        ),
      ),
    );
  }
}
