import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets.dart';
import '../../../data/providers.dart';
import '../../workout/start_workout.dart';

/// Adds a built-in or library movement to the live workout, or starts a
/// workout with it. One exercise row per [catalogId] keeps its history
/// together.
Future<void> useMove(
  BuildContext context,
  WidgetRef ref, {
  required String catalogId,
  required String name,
  String? equipment,
  String? muscles,
  String? liveId,
}) async {
  final repo = ref.read(workoutRepoProvider);
  final exId = await guardedWrite(
    context,
    () => repo.ensureCatalogExercise(catalogId: catalogId, name: name, equipment: equipment, targetMuscles: muscles),
  );
  if (exId == null || !context.mounted) return;
  if (liveId != null) {
    final ok = await guardedWrite(context, () => repo.addSessionExercise(liveId, exId));
    if (ok != null && context.mounted) await context.push('/live/$liveId');
    return;
  }
  await startWorkout(context, ref, firstExerciseId: exId);
}
