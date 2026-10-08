import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../data/providers.dart';

/// Starts a session and opens the live workout: an empty workout, or one
/// day of a plan ([programId] and [programDay]).
///
/// If a session is already live, the user returns to it instead.
Future<void> startWorkout(
  BuildContext context,
  WidgetRef ref, {
  String? firstExerciseId,
  String? programId,
  int? programDay,
}) async {
  final repo = ref.read(workoutRepoProvider);
  final live = await repo.liveSession();
  if (!context.mounted) return;
  if (live != null) {
    showMessage(context, 'Finish the workout in progress first.');
    await context.push('/live/${live.id}');
    return;
  }
  final id = await guardedWrite(context, () async {
    if (programId != null && programDay != null) {
      return repo.startProgramDay(programId: programId, dayIndex: programDay);
    }
    final id = await repo.startSession();
    if (firstExerciseId != null) {
      await repo.addExerciseWithSets(id, firstExerciseId);
    }
    return id;
  });
  if (id != null && context.mounted) await context.push('/live/$id');
}
