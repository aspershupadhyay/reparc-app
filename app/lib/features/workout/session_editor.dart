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
import '../../domain/guide.dart';
import 'guide_controller.dart';

/// Exercises and sets of one session. Used by the live workout and by the
/// saved-workout editor.
class SessionExerciseList extends ConsumerWidget {
  const SessionExerciseList({super.key, required this.detail, required this.live});
  final SessionDetail detail;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = detail.exercises;
    final warm = items.where(isWarmupMove).toList();
    // In a live workout a finished warm-up folds to one line.
    final warmupDone = warm.length > 1 && warm.every((v) => v.sets.isNotEmpty && v.completedSets == v.sets.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          const EmptyState(
            icon: LucideIcons.dumbbell,
            title: 'No exercises yet',
            body: 'Add an exercise, then record each set.',
          ),
        if (live && warmupDone)
          _WarmupFolded(
            views: [
              for (final v in items)
                if (isWarmupMove(v)) v,
            ],
            builder: (v) => _ExerciseCard(
              view: v,
              index: items.indexOf(v),
              count: items.length,
              sessionId: detail.session.id,
              live: live,
            ),
          ),
        for (final (i, v) in items.indexed)
          if (!(live && warmupDone && isWarmupMove(v))) ...[
            _Collapsible(
              key: ValueKey(v.item.id),
              // In a live workout a finished exercise folds to one line, so the
              // next lift stays in view. Tap it to open it again.
              folded: live && v.sets.isNotEmpty && v.completedSets == v.sets.length,
              view: v,
              card: _ExerciseCard(
                view: v,
                index: i,
                count: items.length,
                sessionId: detail.session.id,
                live: live,
              ),
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
              () async {
                await ref.read(workoutRepoProvider).addExerciseWithSets(detail.session.id, exId);
              },
            );
          },
          icon: const Icon(LucideIcons.plus, size: IconSizes.s),
          label: const Text('Add exercise'),
        ),
      ],
    );
  }
}

/// Every warm-up move, done, as one line. Tap it to see the moves.
class _WarmupFolded extends StatefulWidget {
  const _WarmupFolded({required this.views, required this.builder});
  final List<SessionExerciseView> views;
  final Widget Function(SessionExerciseView) builder;

  @override
  State<_WarmupFolded> createState() => _WarmupFoldedState();
}

class _WarmupFoldedState extends State<_WarmupFolded> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final n = widget.views.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
            onTap: () => setState(() => _open = !_open),
            semanticLabel: 'Warm-up done, $n moves. ${_open ? 'Close' : 'Open'}',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: p.energyStrong, shape: BoxShape.circle),
                    child: Icon(LucideIcons.check, size: 16, color: p.on(p.energyStrong)),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(child: Text('Warm-up', style: t.titleSmall)),
                  Text('$n moves done', style: t.bodySmall),
                  const SizedBox(width: Space.s),
                  Icon(_open ? LucideIcons.chevronUp : LucideIcons.chevronDown, size: IconSizes.s, color: p.inkSoft),
                ],
              ),
            ),
          ),
          if (_open)
            for (final v in widget.views) ...[const SizedBox(height: Space.s), widget.builder(v)],
        ],
      ),
    );
  }
}

class _Collapsible extends StatefulWidget {
  const _Collapsible({super.key, required this.folded, required this.view, required this.card});
  final bool folded;
  final SessionExerciseView view;
  final Widget card;

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.folded || _open) return widget.card;
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final v = widget.view;
    final n = v.sets.length;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      onTap: () => setState(() => _open = true),
      semanticLabel: '${v.exercise.name}, done, $n set${n == 1 ? '' : 's'}. Open',
      child: ExcludeSemantics(
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: p.energyStrong, shape: BoxShape.circle),
              child: Icon(LucideIcons.check, size: 16, color: p.on(p.energyStrong)),
            ),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(v.exercise.name, style: t.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Text('$n set${n == 1 ? '' : 's'} done', style: t.bodySmall),
            const SizedBox(width: Space.s),
            Icon(LucideIcons.chevronDown, size: IconSizes.s, color: p.inkSoft),
          ],
        ),
      ),
    );
  }
}

enum _ExerciseAction { up, down, swap, replace, skip, edit, remove }

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
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
      case _ExerciseAction.swap || _ExerciseAction.replace:
        final id = a == _ExerciseAction.swap
            ? await swapExercise(context, ref, view.exercise.catalogId)
            : await pickExercise(context, title: 'Replace exercise');
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
    final cols = SetColumns.of(view);
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
                    // In a live workout the ticks show what is done, so the
                    // count is left out.
                    if (view.exercise.variation != null || skipped || !live)
                      Text(
                        [
                          ?view.exercise.variation,
                          if (skipped)
                            'Skipped'
                          else if (!live)
                            '${view.completedSets} of ${view.sets.length} set${view.sets.length == 1 ? '' : 's'} done',
                        ].join(' · '),
                        style: t.bodySmall,
                      ),
                    if (view.item.note case final note?)
                      Padding(
                        padding: const EdgeInsets.only(top: Space.xs),
                        child: NoteChips(note: note),
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
                tooltip: 'Options for ${view.exercise.name}',
                icon: const Icon(LucideIcons.ellipsisVertical),
                onSelected: (a) => _onAction(context, ref, a),
                itemBuilder: (_) => [
                  if (index > 0) const PopupMenuItem(value: _ExerciseAction.up, child: Text('Move up')),
                  if (index < count - 1) const PopupMenuItem(value: _ExerciseAction.down, child: Text('Move down')),
                  if (view.exercise.catalogId != null)
                    const PopupMenuItem(value: _ExerciseAction.swap, child: Text('Swap for a similar move')),
                  const PopupMenuItem(value: _ExerciseAction.replace, child: Text('Replace exercise')),
                  PopupMenuItem(value: _ExerciseAction.skip, child: Text(skipped ? 'Do not skip' : 'Skip exercise')),
                  const PopupMenuItem(value: _ExerciseAction.edit, child: Text('Edit exercise details')),
                  const PopupMenuItem(value: _ExerciseAction.remove, child: Text('Remove from workout')),
                ],
              ),
            ],
          ),
          if (!skipped) ...[
            if (view.sets.isNotEmpty) const SizedBox(height: Space.s),
            for (final (i, s) in view.sets.indexed)
              SetRow(
                key: ValueKey(s.id),
                set: s,
                number: view.sets.take(i + 1).where((x) => x.setType != SetType.warmup).length,
                previous: i > 0 ? view.sets[i - 1] : null,
                settings: settings,
                sessionId: sessionId,
                live: live,
                isNext: i == view.sets.indexWhere((x) => !x.completed),
                cols: cols,
                targetReps: rampUpReps(view, s) ?? targetRepsFromNote(view.item.note),
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

/// The fields a card shows for its sets: weight and reps, reps only (a
/// warm-up move), or time only (a timed set). Every field stays in Set
/// details.
enum SetColumns {
  loadReps,
  reps,
  time;

  static SetColumns of(SessionExerciseView v) {
    if (v.sets.isNotEmpty && v.sets.every(isTimedSet)) return time;
    if (isWarmupMove(v)) return reps;
    return loadReps;
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
    this.isNext = false,
    this.cols = SetColumns.loadReps,
    this.targetReps,
  });

  /// Which fields the row shows.
  final SetColumns cols;

  /// Reps the plan aims for, shown as the hint when no set came before.
  final int? targetReps;

  final SetEntry set;
  final int number;
  final SetEntry? previous;
  final AppSettings settings;
  final String sessionId;
  final bool live;

  /// The first set that is not done. It offers "Same as last set".
  final bool isNext;

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
    final s = widget.set;
    // A set that just became done (the set time ran out, or a tap) keeps
    // what the user typed: a value on screen that is not saved yet is saved
    // now, never cleared (launch review, 2026-10-10).
    if (s.completed && !old.set.completed) _saveTyped(old.set);
    // Refresh fields only when the saved value itself changed, and never
    // while the user types. A rebuild that comes before a save lands must
    // not put the old value back.
    if (!_loadFocus.hasFocus && s.load != old.set.load && parseDecimal(_load.text) != s.load) {
      _load.text = _num(s.load);
    }
    if (!_repsFocus.hasFocus && s.reps != old.set.reps && parseWhole(_reps.text) != s.reps) {
      _reps.text = s.reps?.toString() ?? '';
    }
    if (!_timeFocus.hasFocus && s.durationSec != old.set.durationSec && parseDuration(_time.text) != s.durationSec) {
      _time.text = _dur(s.durationSec);
    }
  }

  /// Saves the valid values on screen that were never saved: they match
  /// neither the set before this change ([was]) nor the set now. A value
  /// the app wrote, such as a measured time, is never overwritten.
  void _saveTyped(SetEntry was) {
    final s = widget.set;
    final load = parseDecimal(_load.text);
    final reps = parseWhole(_reps.text);
    final time = parseDuration(_time.text);
    final saveLoad = load != null && !load.isNaN && load >= 0 && load != s.load && load != was.load;
    final saveReps = reps != null && reps >= 0 && reps != s.reps && reps != was.reps;
    final saveTime = time != null && time >= 0 && time != s.durationSec && time != was.durationSec;
    if (!saveLoad && !saveReps && !saveTime) return;
    _save(
      SetEntriesCompanion(
        load: saveLoad ? Value(load) : const Value.absent(),
        loadUnit: saveLoad ? Value(_unit) : const Value.absent(),
        reps: saveReps ? Value(reps) : const Value.absent(),
        durationSec: saveTime ? Value(time) : const Value.absent(),
      ),
    );
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
      if (done && widget.live && widget.settings.guideOn) {
        // The guide saves the measured time and starts the right rest.
        await ref.read(guideProvider.notifier).completeFromRow(widget.set);
        return;
      }
      await repo.setCompleted(widget.set.id, done);
      final rest = widget.settings.restAfterSetSec;
      if (done && widget.live && rest != null) await repo.startRest(widget.sessionId, rest);
    });
    if (done) unawaited(HapticFeedback.lightImpact());
  }

  /// Fills load and reps from the last set, on the user's tap. The set is
  /// not marked done (handbook 4.5).
  void _sameAsLast(SetEntry p) {
    if (p.load != null) _load.text = _num(p.load);
    if (p.reps != null) _reps.text = '${p.reps}';
    _save(
      SetEntriesCompanion(
        load: p.load == null ? const Value.absent() : Value(p.load),
        loadUnit: p.load == null ? const Value.absent() : Value(p.loadUnit ?? _unit),
        reps: p.reps == null ? const Value.absent() : Value(p.reps),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = context.pal;
    final s = widget.set;
    final p = widget.previous;
    final g = ref.watch(guideProvider);
    final now = widget.live && g.phase == GuidePhase.set && g.setId == s.id;
    final warm = s.setType == SetType.warmup;
    final done = s.completed;
    // The guide's set time is the hint, so the user sees what is assumed.
    // The plan's target time, else the last time, else the guide's set time.
    final timeHint = s.targetSec != null
        ? _dur(s.targetSec)
        : p?.durationSec != null
        ? _dur(p!.durationSec)
        : widget.settings.guideOn && widget.settings.finishRepSets
        ? _dur(widget.settings.setSec ?? estimateSetSec(s.reps ?? p?.reps))
        : 'm:ss';
    final suffixStyle = t.labelSmall?.copyWith(color: pal.inkSoft);
    InputDecoration field({String? hint, String? suffix, String? error}) => InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.m),
      constraints: const BoxConstraints(minHeight: minTarget),
      errorMaxLines: 1,
      hintText: hint,
      // A target is slanted, so an aim of "10" never reads as a typed 10.
      hintStyle: t.bodyLarge?.copyWith(color: pal.inkSoft, fontStyle: FontStyle.italic),
      // The unit stays in view, also on an empty field.
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: Space.s),
              child: Text(suffix, style: suffixStyle),
            ),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      errorText: error,
      filled: true,
      fillColor: done ? pal.surface : pal.surfaceAlt,
    );
    final canCopy =
        widget.isNext && !done && p != null && (p.load != null || p.reps != null) && s.load == null && s.reps == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs, right: Space.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedContainer(
            duration: motionOf(context, Motion.quick),
            curve: Motion.change,
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: done ? pal.energyStrong.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: Radii.small,
              border: Border.all(
                color: now ? pal.brand : (done ? pal.energyStrong.withValues(alpha: 0.5) : Colors.transparent),
                width: now ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label:
                      '${warm ? 'Warm-up set' : 'Set ${widget.number}'}, ${s.setType.label}${now ? ', timing now' : ''}. Open set details',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: Radii.small,
                    onTap: () => showSetDetails(context, s, widget.settings),
                    child: SizedBox(
                      width: 40,
                      height: 48,
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: warm ? pal.orangeSoft : (now ? pal.brand : pal.surfaceAlt),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            warm ? 'W' : '${widget.number}',
                            style: t.labelMedium?.tabular.copyWith(
                              // Orange on its soft tint reads as "warm-up" and
                              // keeps 3:1 in both modes.
                              color: now ? pal.onBrand : (warm ? pal.orange : pal.ink),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: Space.xs),
                if (widget.cols == SetColumns.loadReps) ...[
                  Expanded(
                    child: TextField(
                      controller: _load,
                      focusNode: _loadFocus,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: t.bodyLarge?.tabular,
                      onChanged: _onLoad,
                      decoration: field(
                        hint: done || p?.load == null ? null : _num(p!.load),
                        suffix: _unit,
                        error: _loadError,
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.xs),
                ],
                if (widget.cols != SetColumns.time)
                  Expanded(
                    child: TextField(
                      controller: _reps,
                      focusNode: _repsFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      style: t.bodyLarge?.tabular,
                      onChanged: _onReps,
                      // A done set shows only what was saved, never a guess.
                      decoration: field(
                        hint: done ? null : (p?.reps ?? widget.targetReps)?.toString(),
                        suffix: 'reps',
                        error: _repsError,
                      ),
                    ),
                  ),
                if (widget.cols == SetColumns.time)
                  Expanded(
                    child: TextField(
                      controller: _time,
                      focusNode: _timeFocus,
                      keyboardType: TextInputType.datetime,
                      style: t.bodyLarge?.tabular,
                      onChanged: _onTime,
                      decoration: field(hint: done ? null : timeHint, error: _timeError),
                    ),
                  ),
                const SizedBox(width: Space.xs),
                Semantics(
                  label: warm ? 'Warm-up set complete' : 'Set ${widget.number} complete',
                  checked: done,
                  button: true,
                  excludeSemantics: true,
                  child: IconButton(
                    onPressed: _toggleDone,
                    tooltip: done ? 'Mark set not complete' : 'Mark set complete',
                    // Done is a status, not an action: a tinted circle with a
                    // green tick, so it does not compete with "Skip rest" or
                    // the next set (visual review, 2026-10-09).
                    style: IconButton.styleFrom(
                      backgroundColor: done ? pal.energyStrong.withValues(alpha: 0.2) : pal.surface,
                      side: BorderSide(color: done ? pal.energyStrong : pal.inkSoft, width: 1.5),
                    ),
                    icon: Icon(LucideIcons.check, color: done ? pal.energyStrong : pal.inkSoft),
                  ),
                ),
              ],
            ),
          ),
          if (canCopy)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _sameAsLast(p),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(LucideIcons.copy, size: 16),
                label: Text(
                  'Same as last set: ${[if (p.load != null) '${_num(p.load)} ${p.loadUnit ?? _unit}', if (p.reps != null) '${p.reps} reps'].join(' × ')}',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// An exercise note as a few quiet chips: "2 × 8–12", "1:15 min rest",
/// "3 reps left", then any coaching cue as one short line. The ramp-up
/// line is left out: the ramp-up rows and the clock already show it.
class NoteChips extends StatelessWidget {
  const NoteChips({super.key, required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final chips = <String>[];
    final cues = <String>[];
    for (final line in note.split('\n')) {
      if (line.startsWith('Ramp-up sets first:')) continue;
      final parts = line.replaceFirst('Target: ', '').split(' · ');
      for (final part in parts) {
        if (part == 'Warm-up') continue;
        // Short facts are chips; a sentence is a cue.
        (part.length <= 16 && !part.endsWith('.') ? chips : cues).add(part);
      }
    }
    return Semantics(
      label: note.replaceAll('\n', '. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (chips.isNotEmpty)
            Wrap(
              spacing: Space.xs,
              runSpacing: Space.xs,
              children: [
                for (final c in chips)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 2),
                    decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Radii.small),
                    child: Text(c, style: t.labelSmall?.copyWith(color: p.inkSoft)),
                  ),
              ],
            ),
          if (cues.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(cues.join(' '), style: t.bodySmall?.copyWith(color: p.inkSoft)),
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
        messageBar('Set deleted.', actionLabel: 'Undo', onAction: () => repo.restoreSet(removed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget unitPicker(String value, List<String> units, ValueChanged<String> on) => DropdownButton<String>(
      value: value,
      icon: pickerIcon(context),
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
