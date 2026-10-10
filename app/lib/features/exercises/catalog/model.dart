import '../rig/anatomy.dart';
import '../rig/equipment.dart';
import '../rig/pose.dart';
import '../rig/skeleton.dart';

/// Body areas used to group the built-in exercises.
enum BodyArea {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  arms('Arms'),
  legs('Legs'),
  glutes('Glutes'),
  core('Core');

  const BodyArea(this.label);
  final String label;

  String get short => switch (this) {
    BodyArea.glutes => 'Glutes',
    _ => label,
  };
}

enum Level {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Level(this.label);
  final String label;
}

/// A built-in exercise with coaching and a body-model animation.
///
/// Text is original to this project and is part of the app (all rights reserved).
/// It is general technique coaching, not medical advice.
class ExerciseDef {
  const ExerciseDef({
    required this.id,
    required this.name,
    required this.area,
    required this.equipment,
    required this.level,
    required this.primary,
    this.secondary = const {},
    required this.keys,
    this.anchor = const FeetAnchor(),
    this.equip = const [],
    this.angles = const [],
    this.view = 35,
    required this.summary,
    required this.setup,
    required this.steps,
    required this.breathing,
    required this.cues,
    required this.mistakes,
    required this.easier,
    required this.harder,
    required this.dose,
    required this.tempo,
    this.timed = false,
  });

  /// Stable ID. Saved workouts link to it. Never change it.
  final String id;
  final String name;
  final BodyArea area;
  final String equipment;
  final Level level;
  final Set<Muscle> primary;
  final Set<Muscle> secondary;

  /// Key positions. The animation loops through them and back to the first.
  final List<KeyPose> keys;
  final Anchor anchor;
  final List<Equip> equip;

  /// Joints that show a live angle label, for example `lKnee`.
  final List<String> angles;

  /// Default camera angle in degrees. 0 is front, 90 is the figure's left.
  final double view;

  /// One line: what the exercise trains and why.
  final String summary;
  final List<String> setup;
  final List<String> steps;
  final String breathing;
  final List<String> cues;
  final List<String> mistakes;
  final String easier;
  final String harder;

  /// Sets and reps or time, by goal.
  final String dose;

  /// Speed of each rep.
  final String tempo;

  /// True for holds measured in time, such as a plank.
  final bool timed;
}
