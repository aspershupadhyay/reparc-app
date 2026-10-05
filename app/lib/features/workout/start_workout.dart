import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../data/providers.dart';

/// Starts a session and opens the live workout.
///
/// If a session is already live, the user returns to it instead.
Future<void> startWorkout(BuildContext context, WidgetRef ref, {String? templateId, String? firstExerciseId}) async {
  final repo = ref.read(workoutRepoProvider);
  final live = await repo.liveSession();
  if (!context.mounted) return;
  if (live != null) {
    showMessage(context, 'Finish the workout in progress first.');
    await context.push('/live/${live.id}');
    return;
  }
  final id = await guardedWrite(context, () async {
    final id = await repo.startSession(templateId: templateId);
    if (firstExerciseId != null) {
      final se = await repo.addSessionExercise(id, firstExerciseId);
      await repo.addSet(se);
    }
    return id;
  });
  if (id != null && context.mounted) await context.push('/live/$id');
}
