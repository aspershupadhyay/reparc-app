import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../exercises/area_style.dart';
import '../exercises/catalog/catalog.dart';
import '../exercises/catalog/model.dart';
import '../exercises/library_screen.dart';
import '../exercises/viewer.dart';
import 'exercise_form.dart';

/// Picks a built-in or custom exercise, or creates one without leaving
/// the workout (handbook 4.2). Returns the exercise row id.
Future<String?> pickExercise(BuildContext context, {String title = 'Add exercise'}) {
  return showAppSheet<String>(context, (_) => _Picker(title: title));
}

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.title});
  final String title;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  final _q = TextEditingController();
  BodyArea? _area;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = await showExerciseForm(context, initialName: _q.text.trim());
    if (id != null && mounted) Navigator.pop(context, id);
  }

  Future<void> _pickCatalog(ExerciseDef e) async {
    final id = await guardedWrite(
      context,
      () => ref
          .read(workoutRepoProvider)
          .ensureCatalogExercise(
            catalogId: e.id,
            name: e.name,
            equipment: e.equipment,
            targetMuscles: e.primary.map((m) => m.label).join(', '),
          ),
    );
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final q = _q.text.trim().toLowerCase();
    final own = (ref.watch(exercisesProvider).value ?? const []).where((e) => e.catalogId == null).toList();
    final builtIn = catalog
        .where(
          (e) =>
              (_area == null || e.area == _area) && (q.isEmpty || '${e.name} ${e.equipment}'.toLowerCase().contains(q)),
        )
        .toList();
    final mine = own.where((e) => _area == null && (q.isEmpty || e.name.toLowerCase().contains(q))).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(widget.title, style: t.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, Space.m),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: IconSizes.s),
                hintText: 'Search',
                fillColor: p.surface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: Space.l),
            child: AreaChips(selected: _area, onChanged: (a) => setState(() => _area = a)),
          ),
          const SizedBox(height: Space.s),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xl),
              children: [
                _NewRow(label: q.isEmpty ? 'Create your own' : 'Create “${_q.text.trim()}”', onTap: _create),
                for (final e in mine)
                  _Row(
                    title: e.name,
                    subtitle: e.equipment ?? 'Your exercise',
                    leading: IconBadge(LucideIcons.userRound, color: p.brandSoft, glyph: p.brand),
                    onTap: () => Navigator.pop(context, e.id),
                  ),
                for (final e in builtIn)
                  _Row(
                    title: e.name,
                    subtitle: '${e.area.short} · ${e.equipment}',
                    leading: ClipRRect(
                      borderRadius: Radii.small,
                      child: SizedBox(width: 56, height: 56, child: ExerciseThumb(e, height: 56)),
                    ),
                    dot: areaColors(p, e.area).$1,
                    onTap: () => _pickCatalog(e),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.leading, required this.onTap, this.dot});
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: AppCard(
        padding: const EdgeInsets.all(Space.s),
        onTap: onTap,
        semanticLabel: '$title. $subtitle. Add',
        child: ExcludeSemantics(
          child: Row(
            children: [
              leading,
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleSmall),
                    Text(subtitle, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(LucideIcons.plus, color: context.pal.brand),
              const SizedBox(width: Space.s),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewRow extends StatelessWidget {
  const _NewRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(LucideIcons.plus, color: p.brand),
        label: Text(label),
      ),
    );
  }
}
