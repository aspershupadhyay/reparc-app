import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import 'exercise_form.dart';

/// Picks an exercise from the library, or creates one without leaving the
/// workout flow (handbook 4.2). Returns the exercise id.
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

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final id = await showExerciseForm(context, initialName: _q.text.trim());
    if (id != null && mounted) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final exercises = ref.watch(exercisesProvider);
    final q = _q.text.trim().toLowerCase();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Text(widget.title, style: t.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: TextField(
              controller: _q,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(LucideIcons.search, size: IconSizes.s),
                labelText: 'Search your exercises',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: OutlinedButton.icon(
              onPressed: _create,
              icon: const Icon(LucideIcons.plus, size: IconSizes.s),
              label: Text(q.isEmpty ? 'New exercise' : 'New exercise “${_q.text.trim()}”'),
            ),
          ),
          const SizedBox(height: Space.s),
          Expanded(
            child: AsyncBody(
              value: exercises,
              builder: (list) {
                final shown = list
                    .where(
                      (e) =>
                          q.isEmpty || '${e.name} ${e.variation ?? ''} ${e.equipment ?? ''}'.toLowerCase().contains(q),
                    )
                    .toList();
                if (shown.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(Space.l),
                    child: Text(
                      list.isEmpty
                          ? 'Your library is empty. Create your first exercise.'
                          : 'No exercise matches your search.',
                      style: t.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final e = shown[i];
                    return ListTile(
                      title: Text(exerciseTitle(e)),
                      subtitle: e.equipment == null ? null : Text(e.equipment!),
                      trailing: const Icon(LucideIcons.plus, size: IconSizes.s),
                      onTap: () => Navigator.pop(context, e.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
