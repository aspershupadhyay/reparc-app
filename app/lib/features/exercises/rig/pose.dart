/// Joint angles for one key position of an exercise, in degrees.
///
/// Conventions (figure standing, arms hanging, palms facing the thighs):
/// - `pitch`: whole-body tilt. -90 lies face up, +90 lies face down.
/// - `lean`: trunk bends forward at the hips. `twist` turns the trunk.
///   `bend` tilts the trunk to the side.
/// - Shoulder `flex` raises the arm forward, `abd` raises it to the side,
///   `rot` turns it on its own axis (90 points a bent forearm up).
/// - `elbow` and `knee` are flexion from straight.
/// - Hip `flex` raises the thigh forward, `abd` moves it out.
/// - `ankle` is dorsiflexion (toes toward shin).
class Pose {
  const Pose._(this.v);
  final Map<String, double> v;

  static const keys = [
    'pitch', 'roll', 'yaw', 'lean', 'twist', 'bend', 'head', //
    'lShFlex', 'rShFlex', 'lShAbd', 'rShAbd', 'lShRot', 'rShRot', 'lElbow', 'rElbow',
    'lHipFlex', 'rHipFlex', 'lHipAbd', 'rHipAbd', 'lKnee', 'rKnee', 'lAnkle', 'rAnkle',
  ];

  /// Builds a pose. Symmetric values apply to both sides. A side value
  /// (for example `lKnee`) overrides the symmetric value.
  factory Pose({
    double pitch = 0,
    double roll = 0,
    double yaw = 0,
    double lean = 0,
    double twist = 0,
    double bend = 0,
    double head = 0,
    double shFlex = 0,
    double shAbd = 8,
    double shRot = 0,
    double elbow = 5,
    double hipFlex = 0,
    double hipAbd = 4,
    double knee = 2,
    double ankle = 0,
    Map<String, double> side = const {},
  }) {
    final m = <String, double>{
      'pitch': pitch,
      'roll': roll,
      'yaw': yaw,
      'lean': lean,
      'twist': twist,
      'bend': bend,
      'head': head,
      'lShFlex': shFlex,
      'rShFlex': shFlex,
      'lShAbd': shAbd,
      'rShAbd': shAbd,
      'lShRot': shRot,
      'rShRot': shRot,
      'lElbow': elbow,
      'rElbow': elbow,
      'lHipFlex': hipFlex,
      'rHipFlex': hipFlex,
      'lHipAbd': hipAbd,
      'rHipAbd': hipAbd,
      'lKnee': knee,
      'rKnee': knee,
      'lAnkle': ankle,
      'rAnkle': ankle,
      ...side,
    };
    return Pose._(m);
  }

  double operator [](String k) => v[k] ?? 0;

  static Pose lerp(Pose a, Pose b, double t) => Pose._({for (final k in keys) k: a[k] + (b[k] - a[k]) * t});
}

/// One key position with a short coaching label for that phase.
class KeyPose {
  const KeyPose(this.pose, this.label, {this.hold = 0.35, this.move = 1.2});
  final Pose pose;

  /// Phase name shown during the move into this pose, for example "Lower".
  final String label;

  /// Seconds to hold this pose.
  final double hold;

  /// Seconds to move from the previous pose into this one.
  final double move;
}
