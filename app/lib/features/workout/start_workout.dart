import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets.dart';
import '../../data/providers.dart';

/// Starts a session and opens the live workout.
///
/// If a session is already live, the user returns to it instead.
Future<void> startWorkout(BuildContext context, WidgetRef ref, {String? templateId}) async {
  final repo = ref.read(workoutRepoProvider);
  final live = await repo.liveSession();
  if (!context.mounted) return;
  if (live != null) {
    showMessage(context, 'Finish the workout in progress before you start another.');
    await context.push('/live/${live.id}');
    return;
  }
  final id = await guardedWrite(context, () => repo.startSession(templateId: templateId));
  if (id != null && context.mounted) await context.push('/live/$id');
}
