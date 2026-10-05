import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/palette.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets.dart';
import '../area_style.dart';
import '../catalog/model.dart';
import '../library_screen.dart';
import 'library.dart';
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
  String? _equipment;

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
    return lib.when(
      loading: () => const Center(child: CircularProgressIndicator(semanticsLabel: 'Loading exercises')),
      error: (e, _) => Center(child: Text('Could not load the exercise library. $e')),
      data: (lib) {
        final words = q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final results = [
          for (final m in lib.moves)
            if ((_area == null || m.area == _area) &&
                (_equipment == null || m.equipment == _equipment) &&
                words.every(m.searchText.contains))
              m,
        ];
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
                  hintText: 'Search ${lib.moves.length} exercises or muscles',
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
            const SizedBox(height: Space.m),
            Padding(
              padding: EdgeInsets.only(left: widget.padding.left),
              child: AreaChips(selected: _area, onChanged: (a) => setState(() => _area = a)),
            ),
            const SizedBox(height: Space.s),
            Padding(
              padding: EdgeInsets.only(left: widget.padding.left),
              child: _EquipmentChips(
                options: lib.equipment,
                selected: _equipment,
                onChanged: (e) => setState(() => _equipment = e),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(widget.padding.left, Space.m, widget.padding.right, Space.xs),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  results.length == 1 ? '1 exercise' : '${results.length} exercises',
                  style: t.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(widget.padding.left, Space.s, widget.padding.right, Space.xxl),
                itemCount: extra.length + (results.isEmpty ? 1 : results.length),
                itemBuilder: (context, i) {
                  if (i < extra.length) return extra[i];
                  if (results.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(Space.xl),
                      child: Text(
                        'No match. Try a shorter word, or clear a filter.',
                        textAlign: TextAlign.center,
                        style: t.bodyMedium?.copyWith(color: p.inkSoft),
                      ),
                    );
                  }
                  final m = results[i - extra.length];
                  return MoveTile(m, icon: widget.trailingIcon, onTap: () => widget.onTap(m));
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EquipmentChips extends StatelessWidget {
  const _EquipmentChips({required this.options, required this.selected, required this.onChanged});
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final o in [null, ...options])
            Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: ChoiceChip(
                label: Text(o ?? 'Any equipment'),
                selected: selected == o,
                onSelected: (_) => onChanged(o),
              ),
            ),
        ],
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
            '${m.name}. ${m.area.label}. ${m.equipment}. ${m.level.label}${m.coached != null ? '. Coached guide' : ''}',
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
                          child: Text(
                            '${m.area.short} · ${m.equipment} · ${m.level.label}',
                            style: t.bodySmall,
                            maxLines: 1,
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
              Icon(icon, color: p.brand, size: IconSizes.s),
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
