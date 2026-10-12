import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../exercises/library/library.dart';
import '../exercises/library/move_browser.dart';
import '../exercises/library/move_groups.dart';
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
  /// Current search text, used as the name for a new exercise.
  String _query = '';

  Future<void> _create() async {
    final id = await showExerciseForm(context, initialName: _query);
    if (id != null && mounted) Navigator.pop(context, id);
  }

  Future<void> _pickMove(Move m) async {
    final id = await _exerciseRowFor(context, ref, m);
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final own = (ref.watch(exercisesProvider).value ?? const []).where((e) => e.catalogId == null).toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
            child: Text(widget.title, style: t.titleLarge),
          ),
          Expanded(
            child: MoveBrowser(
              trailingIcon: LucideIcons.plus,
              onTap: _pickMove,
              leadingWhen: (q, area) {
                _query = q;
                return [
                  _NewRow(label: q.isEmpty ? 'Create your own' : 'Create “$q”', onTap: _create),
                  if (area == null)
                    for (final e in own)
                      if (q.isEmpty || e.name.toLowerCase().contains(q.toLowerCase()))
                        _Row(
                          title: e.name,
                          subtitle: e.equipment ?? 'Your exercise',
                          leading: IconBadge(LucideIcons.userRound, color: p.brandSoft, glyph: p.brand),
                          onTap: () => Navigator.pop(context, e.id),
                        ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The exercise row that logs [m]. Creates it the first time.
Future<String?> _exerciseRowFor(BuildContext context, WidgetRef ref, Move m) => guardedWrite(
  context,
  () => ref
      .read(workoutRepoProvider)
      .ensureCatalogExercise(catalogId: m.catalogId, name: m.name, equipment: m.equipment, targetMuscles: m.muscles),
);

/// Offers moves for the same muscle to stand in for the exercise linked
/// to [catalogId], for example when the equipment is taken. Returns the new
/// exercise row id. Exercises outside the library open the full picker.
Future<String?> swapExercise(BuildContext context, WidgetRef ref, String? catalogId) async {
  final lib = await ref.read(libraryProvider.future);
  if (!context.mounted) return null;
  final current = catalogId == null ? null : lib.byCatalogId[catalogId];
  if (current == null) return pickExercise(context, title: 'Replace exercise');
  return showAppSheet<String>(context, (_) => _SwapSheet(current: current));
}

class _SwapSheet extends ConsumerStatefulWidget {
  const _SwapSheet({required this.current});
  final Move current;

  @override
  ConsumerState<_SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends ConsumerState<_SwapSheet> {
  Future<void> _pick(Move m) async {
    final id = await _exerciseRowFor(context, ref, m);
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final lib = ref.watch(libraryProvider).value;
    final c = widget.current;
    final all = lib == null ? const <Move>[] : swapsFor(lib, c);
    final place = ref.watch(placeProvider);
    final shown = place == null ? all : all.where(place.fits).toList();
    final group = groupOf(c);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.88,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xs),
            child: Text('Swap ${c.name}', style: t.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(
              'Same muscle: ${c.target.label.toLowerCase()}'
              '${muscleGroups[c.target]?.contains(group) ?? false ? ', ${group.label.toLowerCase()}' : ''}. '
              'Closest matches first. Sets you logged stay.',
              style: t.bodySmall,
            ),
          ),
          const SizedBox(height: Space.m),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Space.l),
            child: PlaceTabs(),
          ),
          const SizedBox(height: Space.s),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text('No other moves here. Try All.', style: t.bodyMedium))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
                    itemCount: shown.length,
                    itemBuilder: (_, i) => MoveTile(shown[i], icon: LucideIcons.repeat, onTap: () => _pick(shown[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.subtitle, required this.leading, required this.onTap});
  final String title;
  final String subtitle;
  final Widget leading;
  final VoidCallback onTap;

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
