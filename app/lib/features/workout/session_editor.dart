import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';
import '../../data/workout_repository.dart';
import '../exercises/library/library.dart';
import 'exercise_form.dart';
import 'exercise_picker.dart';

/// Exercises and sets of one session. Used by the live workout and by the
/// saved-workout editor.
class SessionExerciseList extends ConsumerWidget {
  const SessionExerciseList({super.key, required this.detail, required this.live});
  final SessionDetail detail;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = detail.exercises;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          const EmptyState(
            icon: LucideIcons.dumbbell,
            title: 'No exercises yet',
            body: 'Add an exercise, then record each set.',
          ),
        for (final (i, v) in items.indexed) ...[
          _ExerciseCard(
            key: ValueKey(v.item.id),
            view: v,
            index: i,
            count: items.length,
            sessionId: detail.session.id,
            live: live,
          ),
          const SizedBox(height: Space.m),
        ],
        const SizedBox(height: Space.s),
        OutlinedButton.icon(
          onPressed: () async {
            final exId = await pickExercise(context);
            if (exId == null || !context.mounted) return;
            await guardedWrite(
              context,
              () => ref.read(workoutRepoProvider).addSessionExercise(detail.session.id, exId),
            );
          },
          icon: const Icon(LucideIcons.plus, size: IconSizes.s),
          label: const Text('Add exercise'),
        ),
      ],
    );
  }
}

enum _ExerciseAction { up, down, replace, skip, edit, remove }

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    super.key,
    required this.view,
    required this.index,
    required this.count,
    required this.sessionId,
    required this.live,
  });

  final SessionExerciseView view;
  final int index;
  final int count;
  final String sessionId;
  final bool live;

  Future<void> _onAction(BuildContext context, WidgetRef ref, _ExerciseAction a) async {
    final repo = ref.read(workoutRepoProvider);
    switch (a) {
      case _ExerciseAction.up:
        await guardedWrite(context, () => repo.moveSessionExercise(sessionId, index, index - 1));
      case _ExerciseAction.down:
        await guardedWrite(context, () => repo.moveSessionExercise(sessionId, index, index + 1));
      case _ExerciseAction.replace:
        final id = await pickExercise(context, title: 'Replace exercise');
        if (id == null || !context.mounted) return;
        final old = view.item.exerciseId;
        await guardedWrite(context, () => repo.replaceSessionExercise(view.item.id, id));
        if (context.mounted) {
          showMessage(
            context,
            'Exercise replaced. Sets kept.',
            actionLabel: 'Undo',
            onAction: () => repo.replaceSessionExercise(view.item.id, old),
          );
        }
      case _ExerciseAction.skip:
        await guardedWrite(context, () => repo.setSkipped(view.item.id, !view.item.skipped));
      case _ExerciseAction.edit:
        await showExerciseForm(context, existing: view.exercise);
      case _ExerciseAction.remove:
        final removed = await guardedWrite(context, () => repo.removeSessionExercise(view.item.id));
        if (removed != null && context.mounted) {
          showMessage(
            context,
            '${view.exercise.name} removed.',
            actionLabel: 'Undo',
            onAction: () => repo.restoreSessionExercise(removed),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(currentSettingsProvider);
    final skipped = view.item.skipped;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(view.exercise.name, style: t.titleMedium),
                    Text(
                      [
                        ?view.exercise.variation,
                        if (skipped) 'Skipped' else '${view.completedSets} of ${view.sets.length} sets done',
                      ].join(' · '),
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              if (guideRouteFor(view.exercise.catalogId) case final route?)
                IconButton(
                  tooltip: 'How to do ${view.exercise.name}',
                  onPressed: () => context.push(route),
                  icon: Icon(LucideIcons.bookOpen, color: context.pal.brand),
                ),
              PopupMenuButton<_ExerciseAction>(
                tooltip: 'Exercise options',
                icon: const Icon(LucideIcons.ellipsisVertical),
                onSelected: (a) => _onAction(context, ref, a),
                itemBuilder: (_) => [
                  if (index > 0) const PopupMenuItem(value: _ExerciseAction.up, child: Text('Move up')),
                  if (index < count - 1) const PopupMenuItem(value: _ExerciseAction.down, child: Text('Move down')),
                  const PopupMenuItem(value: _ExerciseAction.replace, child: Text('Replace exercise')),
                  PopupMenuItem(value: _ExerciseAction.skip, child: Text(skipped ? 'Do not skip' : 'Skip exercise')),
                  const PopupMenuItem(value: _ExerciseAction.edit, child: Text('Edit exercise details')),
                  const PopupMenuItem(value: _ExerciseAction.remove, child: Text('Remove from workout')),
                ],
              ),
            ],
          ),
          if (!skipped) ...[
            if (view.sets.isNotEmpty) ...[
              const SizedBox(height: Space.s),
              _SetHeader(unit: settings.loadUnit),
            ],
            for (final (i, s) in view.sets.indexed)
              SetRow(
                key: ValueKey(s.id),
                set: s,
                number: i + 1,
                previous: i > 0 ? view.sets[i - 1] : null,
                settings: settings,
                sessionId: sessionId,
                live: live,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => guardedWrite(context, () => ref.read(workoutRepoProvider).addSet(view.item.id)),
                icon: const Icon(LucideIcons.plus, size: IconSizes.s),
                label: const Text('Add set'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  const _SetHeader({required this.unit});
  final String unit;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelSmall?.copyWith(color: context.pal.inkSoft);
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(right: Space.s, bottom: Space.xs),
        child: Row(
          children: [
            SizedBox(width: 48, child: Text('Set', style: s)),
            const SizedBox(width: Space.s),
            Expanded(child: Text('Load', style: s)),
            const SizedBox(width: Space.s),
            Expanded(child: Text('Reps or time', style: s)),
            const SizedBox(width: Space.s),
            SizedBox(
              width: 48,
              child: Text('Done', style: s, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

/// One set. Each valid change is saved at once (handbook 4.5).
class SetRow extends ConsumerStatefulWidget {
  const SetRow({
    super.key,
    required this.set,
    required this.number,
    required this.previous,
    required this.settings,
    required this.sessionId,
    required this.live,
  });

  final SetEntry set;
  final int number;
  final SetEntry? previous;
  final AppSettings settings;
  final String sessionId;
  final bool live;

  @override
  ConsumerState<SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<SetRow> {
  late final _load = TextEditingController(text: _num(widget.set.load));
  late final _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
  late final _time = TextEditingController(text: _dur(widget.set.durationSec));
  final _loadFocus = FocusNode();
  final _repsFocus = FocusNode();
  final _timeFocus = FocusNode();
  String? _loadError;
  String? _repsError;
  String? _timeError;

  static String _num(double? v) => v == null ? '' : fmtNum(v, maxDecimals: 2).replaceAll(',', '');
  static String _dur(int? s) => s == null ? '' : fmtClock(Duration(seconds: s));

  @override
  void didUpdateWidget(SetRow old) {
    super.didUpdateWidget(old);
    // Refresh fields from saved data, but never while the user types.
    if (!_loadFocus.hasFocus && parseDecimal(_load.text) != widget.set.load) {
      _load.text = _num(widget.set.load);
    }
    if (!_repsFocus.hasFocus && parseWhole(_reps.text) != widget.set.reps) {
      _reps.text = widget.set.reps?.toString() ?? '';
    }
    if (!_timeFocus.hasFocus && parseDuration(_time.text) != widget.set.durationSec) {
      _time.text = _dur(widget.set.durationSec);
    }
  }

  @override
  void dispose() {
    for (final c in [_load, _reps, _time]) {
      c.dispose();
    }
    for (final f in [_loadFocus, _repsFocus, _timeFocus]) {
      f.dispose();
    }
    super.dispose();
  }

  String get _unit => widget.set.loadUnit ?? widget.settings.loadUnit;

  void _save(SetEntriesCompanion c) {
    ref.read(workoutRepoProvider).updateSet(widget.set.id, c).catchError((Object _) {
      if (mounted) showMessage(context, 'Not saved. Try again.');
    });
  }

  void _onLoad(String text) {
    final v = parseDecimal(text);
    if (v != null && (v.isNaN || v < 0)) {
      setState(() => _loadError = 'Check value');
      return;
    }
    setState(() => _loadError = null);
    _save(SetEntriesCompanion(load: Value(v), loadUnit: Value(v == null ? null : _unit)));
  }

  void _onReps(String text) {
    final v = parseWhole(text);
    if (v != null && v < 0) {
      setState(() => _repsError = 'Check value');
      return;
    }
    setState(() => _repsError = null);
    _save(SetEntriesCompanion(reps: Value(v)));
  }

  void _onTime(String text) {
    final v = parseDuration(text);
    if (v == -1) {
      setState(() => _timeError = 'Use m:ss');
      return;
    }
    setState(() => _timeError = null);
    _save(SetEntriesCompanion(durationSec: Value(v)));
  }

  Future<void> _toggleDone() async {
    final repo = ref.read(workoutRepoProvider);
    final done = !widget.set.completed;
    await guardedWrite(context, () async {
      await repo.setCompleted(widget.set.id, done);
      final rest = widget.settings.restAfterSetSec;
      if (done && widget.live && rest != null) await repo.startRest(widget.sessionId, rest);
    });
    if (done) unawaited(HapticFeedback.lightImpact());
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = widget.set;
    final p = widget.previous;
    final timed = s.setType == SetType.timed;
    final typeMark = s.setType.short;
    final dense = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.m),
      constraints: const BoxConstraints(minHeight: minTarget),
      errorMaxLines: 1,
    );
    return AnimatedContainer(
      duration: motionOf(context, Motion.quick),
      curve: Motion.change,
      margin: const EdgeInsets.only(bottom: Space.xs, right: Space.s),
      decoration: BoxDecoration(
        color: s.completed ? context.pal.energy.withValues(alpha: 0.28) : Colors.transparent,
        borderRadius: Radii.small,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Set ${widget.number}, ${s.setType.label}. Open set details',
            excludeSemantics: true,
            child: InkWell(
              borderRadius: Radii.small,
              onTap: () => showSetDetails(context, s, widget.settings),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text('${widget.number}$typeMark', style: t.titleSmall?.tabular),
                ),
              ),
            ),
          ),
          SizedBox(width: Space.s),
          Expanded(
            child: TextField(
              controller: _load,
              focusNode: _loadFocus,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              style: t.bodyLarge?.tabular,
              onChanged: _onLoad,
              decoration: dense.copyWith(
                hintText: p?.load == null ? null : _num(p!.load),
                suffixText: _unit,
                errorText: _loadError,
                semanticCounterText: '',
                labelText: null,
              ),
            ),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: timed
                ? TextField(
                    controller: _time,
                    focusNode: _timeFocus,
                    keyboardType: TextInputType.datetime,
                    style: t.bodyLarge?.tabular,
                    onChanged: _onTime,
                    decoration: dense.copyWith(
                      hintText: p?.durationSec == null ? 'm:ss' : _dur(p!.durationSec),
                      errorText: _timeError,
                    ),
                  )
                : TextField(
                    controller: _reps,
                    focusNode: _repsFocus,
                    keyboardType: TextInputType.number,
                    style: t.bodyLarge?.tabular,
                    onChanged: _onReps,
                    decoration: dense.copyWith(
                      hintText: p?.reps?.toString(),
                      suffixText: 'reps',
                      errorText: _repsError,
                    ),
                  ),
          ),
          const SizedBox(width: Space.s),
          Semantics(
            label: 'Set ${widget.number} complete',
            checked: s.completed,
            button: true,
            excludeSemantics: true,
            child: IconButton(
              onPressed: _toggleDone,
              tooltip: s.completed ? 'Mark set not complete' : 'Mark set complete',
              style: IconButton.styleFrom(
                backgroundColor: s.completed ? context.pal.ink : context.pal.surfaceAlt,
                side: BorderSide(color: context.pal.line),
              ),
              icon: Icon(
                s.completed ? LucideIcons.check : LucideIcons.circle,
                color: s.completed ? context.pal.energy : context.pal.inkSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Parses "m:ss", "h:mm:ss", or plain seconds. Null for empty, -1 if invalid.
int? parseDuration(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final parts = t.split(':');
  if (parts.length > 3) return -1;
  var total = 0;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0) return -1;
    total = total * 60 + n;
  }
  return total;
}

/// Edits every field of a set, or deletes it.
Future<void> showSetDetails(BuildContext context, SetEntry set, AppSettings settings) {
  return showAppSheet<void>(context, (_) => _SetDetails(set: set, settings: settings));
}

class _SetDetails extends ConsumerStatefulWidget {
  const _SetDetails({required this.set, required this.settings});
  final SetEntry set;
  final AppSettings settings;

  @override
  ConsumerState<_SetDetails> createState() => _SetDetailsState();
}

class _SetDetailsState extends ConsumerState<_SetDetails> {
  late SetType _type = widget.set.setType;
  late String _loadUnit = widget.set.loadUnit ?? widget.settings.loadUnit;
  late String _distUnit = widget.set.distanceUnit ?? widget.settings.distanceUnit;
  late final _load = TextEditingController(
    text: widget.set.load == null ? '' : fmtNum(widget.set.load, maxDecimals: 2),
  );
  late final _reps = TextEditingController(text: widget.set.reps?.toString() ?? '');
  late final _time = TextEditingController(
    text: widget.set.durationSec == null ? '' : fmtClock(Duration(seconds: widget.set.durationSec!)),
  );
  late final _dist = TextEditingController(
    text: widget.set.distance == null ? '' : fmtNum(widget.set.distance, maxDecimals: 3),
  );
  late final _rest = TextEditingController(
    text: widget.set.restSec == null ? '' : fmtClock(Duration(seconds: widget.set.restSec!)),
  );
  late final _note = TextEditingController(text: widget.set.note ?? '');
  String? _error;

  @override
  void dispose() {
    for (final c in [_load, _reps, _time, _dist, _rest, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final load = parseDecimal(_load.text.replaceAll(',', ''));
    final reps = parseWhole(_reps.text);
    final time = parseDuration(_time.text);
    final dist = parseDecimal(_dist.text.replaceAll(',', ''));
    final rest = parseDuration(_rest.text);
    final bad =
        (load != null && (load.isNaN || load < 0)) ||
        (reps != null && reps < 0) ||
        time == -1 ||
        (dist != null && (dist.isNaN || dist < 0)) ||
        rest == -1;
    if (bad) {
      setState(() => _error = 'Check the highlighted values. Use numbers, and m:ss for time.');
      return;
    }
    final c = SetEntriesCompanion(
      setType: Value(_type),
      load: Value(load),
      loadUnit: Value(load == null ? null : _loadUnit),
      reps: Value(reps),
      durationSec: Value(time),
      distance: Value(dist),
      distanceUnit: Value(dist == null ? null : _distUnit),
      restSec: Value(rest),
      note: Value(_note.text.trim().isEmpty ? null : _note.text.trim()),
    );
    final ok = await guardedWrite(context, () async {
      await ref.read(workoutRepoProvider).updateSet(widget.set.id, c);
      return true;
    });
    if (ok == true && mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final repo = ref.read(workoutRepoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final removed = await guardedWrite(context, () => repo.deleteSet(widget.set.id));
    if (!mounted) return;
    Navigator.pop(context);
    if (removed != null) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Set deleted.'),
          action: SnackBarAction(label: 'Undo', onPressed: () => repo.restoreSet(removed)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget unitPicker(String value, List<String> units, ValueChanged<String> on) => DropdownButton<String>(
      value: value,
      underline: const SizedBox.shrink(),
      items: [for (final u in units) DropdownMenuItem(value: u, child: Text(u))],
      onChanged: (v) => setState(() => on(v!)),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Set details', style: t.titleLarge),
          SizedBox(height: Space.l),
          Text('Set type', style: t.labelMedium),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            children: [
              for (final ty in SetType.values)
                ChoiceChip(label: Text(ty.label), selected: _type == ty, onSelected: (_) => setState(() => _type = ty)),
            ],
          ),
          const SizedBox(height: Space.l),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _load,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Load'),
                ),
              ),
              const SizedBox(width: Space.s),
              unitPicker(_loadUnit, Units.loadUnits, (v) => _loadUnit = v),
            ],
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _reps,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Repetitions'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _time,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(labelText: 'Duration (m:ss)'),
          ),
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dist,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Distance'),
                ),
              ),
              const SizedBox(width: Space.s),
              unitPicker(_distUnit, Units.distanceUnits, (v) => _distUnit = v),
            ],
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _rest,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(labelText: 'Rest after this set (m:ss)'),
          ),
          const SizedBox(height: Space.m),
          TextField(
            controller: _note,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.m),
            Semantics(
              liveRegion: true,
              child: StatusLine(icon: LucideIcons.circleAlert, text: _error!, color: context.pal.error),
            ),
          ],
          SizedBox(height: Space.l),
          FilledButton(onPressed: _save, child: const Text('Save set')),
          const SizedBox(height: Space.s),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: context.pal.error),
            icon: const Icon(LucideIcons.trash2, size: IconSizes.s),
            label: const Text('Delete set'),
          ),
        ],
      ),
    );
  }
}
