import 'arms.dart';
import 'back.dart';
import 'chest.dart';
import 'core.dart';
import 'glutes.dart';
import 'legs.dart';
import 'model.dart';
import 'shoulders.dart';

/// Every built-in exercise, in display order.
final List<ExerciseDef> catalog = [
  ...chestExercises,
  ...backExercises,
  ...shoulderExercises,
  ...armExercises,
  ...legExercises,
  ...gluteExercises,
  ...coreExercises,
];

final Map<String, ExerciseDef> catalogById = {for (final e in catalog) e.id: e};

List<ExerciseDef> exercisesFor(BodyArea area) => [
  for (final e in catalog)
    if (e.area == area) e,
];
