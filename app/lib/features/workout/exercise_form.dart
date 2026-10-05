import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/providers.dart';

/// Creates or edits a custom exercise. Returns the exercise id when saved.
Future<String?> showExerciseForm(BuildContext context, {Exercise? existing, String initialName = ''}) {
  return showAppSheet<String>(context, (_) => _ExerciseForm(existing: existing, initialName: initialName));
}

class _ExerciseForm extends ConsumerStatefulWidget {
  const _ExerciseForm({this.existing, required this.initialName});
  final Exercise? existing;
  final String initialName;

  @override
  ConsumerState<_ExerciseForm> createState() => _ExerciseFormState();
}

class _ExerciseFormState extends ConsumerState<_ExerciseForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? widget.initialName);
  late final _variation = TextEditingController(text: widget.existing?.variation ?? '');
  late final _equipment = TextEditingController(text: widget.existing?.equipment ?? '');
  late final _muscles = TextEditingController(text: widget.existing?.targetMuscles ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  String? _nameError;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _variation, _equipment, _muscles, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _nameError = 'Enter a name.');
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(workoutRepoProvider);
    final e = widget.existing;
    final id = await guardedWrite(context, () async {
      if (e == null) {
        return repo.createExercise(
          name: _name.text,
          variation: _variation.text,
          equipment: _equipment.text,
          targetMuscles: _muscles.text,
          note: _note.text,
        );
      }
      await repo.updateExercise(
        e.id,
        name: _name.text,
        variation: _variation.text,
        equipment: _equipment.text,
        targetMuscles: _muscles.text,
        note: _note.text,
      );
      return e.id;
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (id != null) Navigator.pop(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.existing == null ? 'New exercise' : 'Edit exercise', style: t.titleLarge),
          const SizedBox(height: Space.l),
          TextField(
            controller: _name,
            autofocus: widget.existing == null,
            maxLength: 120,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
          ),
          const SizedBox(height: Space.s),
          TextField(
            controller: _variation,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Variation (optional)',
              helperText: 'For example: incline, single arm, paused',
            ),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _equipment,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Equipment (optional)'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _muscles,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Target muscles (optional)'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: Space.l),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving' : 'Save exercise')),
        ],
      ),
    );
  }
}

String exerciseTitle(Exercise e) => e.variation == null ? e.name : '${e.name} · ${e.variation}';
