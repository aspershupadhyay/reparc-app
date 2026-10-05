import 'math3d.dart';
import 'pose.dart';

/// Body sizes in metres, for an adult about 1.75 m tall.
abstract final class Dims {
  static const pelvisHalf = 0.095;
  static const torso = 0.50;
  static const shoulderHalf = 0.185;
  static const shoulderDrop = 0.045;
  static const neck = 0.07;
  static const headR = 0.105;
  static const upperArm = 0.29;
  static const forearm = 0.26;
  static const hand = 0.075;
  static const thigh = 0.43;
  static const shin = 0.43;
}

/// How the figure is held in place while it moves.
sealed class Anchor {
  const Anchor();
}

/// Feet stay planted: ankles centred on the origin, lowest foot point on
/// the floor.
class FeetAnchor extends Anchor {
  const FeetAnchor();
}

/// The pelvis stays at a fixed point, for example on a bench or seat.
class PelvisAnchor extends Anchor {
  const PelvisAnchor(this.at);
  final V3 at;
}

/// The hands stay at a fixed point, for example on a bar.
class HandsAnchor extends Anchor {
  const HandsAnchor(this.at);
  final V3 at;
}

/// A rigid body segment with its frame. Used for drawing and highlights.
class Segment {
  const Segment(this.part, this.a, this.b, this.frame, this.radius);
  final Part part;
  final V3 a;
  final V3 b;
  final M3 frame;
  final double radius;
}

enum Part {
  head,
  neck,
  chest,
  abdomen,
  pelvis,
  shoulders,
  lUpperArm,
  rUpperArm,
  lForearm,
  rForearm,
  lThigh,
  rThigh,
  lShin,
  rShin,
  lFoot,
  rFoot,
}

/// Joint positions of one posed body.
class Body {
  Body._(this.j, this.segments, this.frames);

  /// Joint positions by name.
  final Map<String, V3> j;
  final List<Segment> segments;

  /// Segment frames by part, for muscle overlays.
  final Map<Part, M3> frames;

  V3 operator [](String k) => j[k]!;

  Body translate(V3 d) => Body._(
    j.map((k, v) => MapEntry(k, v + d)),
    [for (final s in segments) Segment(s.part, s.a + d, s.b + d, s.frame, s.radius)],
    frames,
  );

  /// Interior angle at a joint in degrees. 180 is straight.
  double angle(String joint) {
    final (a, b, c) = jointTriple(joint);
    return angleDeg(j[a]! - j[b]!, j[c]! - j[b]!);
  }

  /// The three joint names that define an angle: outer, vertex, outer.
  static (String, String, String) jointTriple(String joint) => switch (joint) {
    'lKnee' => ('lHip', 'lKnee', 'lAnkle'),
    'rKnee' => ('rHip', 'rKnee', 'rAnkle'),
    'lHip' => ('neck', 'lHip', 'lKnee'),
    'rHip' => ('neck', 'rHip', 'rKnee'),
    'lElbow' => ('lShoulder', 'lElbow', 'lWrist'),
    'rElbow' => ('rShoulder', 'rElbow', 'rWrist'),
    'lShoulder' => ('lHip', 'lShoulder', 'lElbow'),
    'rShoulder' => ('rHip', 'rShoulder', 'rElbow'),
    'lAnkle' => ('lKnee', 'lAnkle', 'lToe'),
    'rAnkle' => ('rKnee', 'rAnkle', 'rToe'),
    _ => throw ArgumentError('Unknown joint $joint'),
  };
}

/// Forward kinematics: joint angles to joint positions.
Body solve(Pose p, Anchor anchor) {
  final body = M3.ry(p['yaw']) * M3.rx(p['pitch']) * M3.rz(p['roll']);
  final torso = body * M3.rx(p['lean']) * M3.rz(p['bend']) * M3.ry(p['twist']);
  const p0 = V3.zero;
  final j = <String, V3>{'pelvis': p0};
  final frames = <Part, M3>{Part.pelvis: body, Part.chest: torso, Part.abdomen: torso};

  final neck = p0 + torso.apply(V3.up * Dims.torso);
  j['neck'] = neck;
  j['chest'] = p0 + torso.apply(V3.up * (Dims.torso * 0.72));
  final headFrame = torso * M3.rx(p['head']);
  frames[Part.head] = headFrame;
  j['head'] = neck + headFrame.apply(const V3(0, Dims.neck + Dims.headR, 0.015));

  for (final (side, s) in [('l', 1.0), ('r', -1.0)]) {
    final shoulder = neck + torso.apply(V3(s * Dims.shoulderHalf, -Dims.shoulderDrop, 0));
    final upper = torso * M3.rz(s * p['${side}ShAbd']) * M3.rx(-p['${side}ShFlex']) * M3.ry(s * p['${side}ShRot']);
    final elbow = shoulder + upper.apply(V3.down * Dims.upperArm);
    final fore = upper * M3.rx(-p['${side}Elbow']);
    final wrist = elbow + fore.apply(V3.down * Dims.forearm);
    final hand = wrist + fore.apply(V3.down * Dims.hand);
    j['${side}Shoulder'] = shoulder;
    j['${side}Elbow'] = elbow;
    j['${side}Wrist'] = wrist;
    j['${side}Hand'] = hand;
    frames[side == 'l' ? Part.lUpperArm : Part.rUpperArm] = upper;
    frames[side == 'l' ? Part.lForearm : Part.rForearm] = fore;

    final hip = p0 + body.apply(V3(s * Dims.pelvisHalf, 0, 0));
    final thigh = body * M3.rz(s * p['${side}HipAbd']) * M3.rx(-p['${side}HipFlex']);
    final knee = hip + thigh.apply(V3.down * Dims.thigh);
    final shin = thigh * M3.rx(p['${side}Knee']);
    final ankle = knee + shin.apply(V3.down * Dims.shin);
    final foot = shin * M3.rx(-p['${side}Ankle']);
    j['${side}Hip'] = hip;
    j['${side}Knee'] = knee;
    j['${side}Ankle'] = ankle;
    j['${side}Toe'] = ankle + foot.apply(const V3(0, -0.055, 0.17));
    j['${side}Heel'] = ankle + foot.apply(const V3(0, -0.06, -0.05));
    frames[side == 'l' ? Part.lThigh : Part.rThigh] = thigh;
    frames[side == 'l' ? Part.lShin : Part.rShin] = shin;
    frames[side == 'l' ? Part.lFoot : Part.rFoot] = foot;
  }

  final segs = <Segment>[
    Segment(Part.pelvis, j['lHip']!, j['rHip']!, body, 0.085),
    Segment(Part.abdomen, p0 + torso.apply(V3.up * 0.06), j['chest']!, torso, 0.105),
    Segment(Part.chest, j['chest']!, neck + torso.apply(V3.down * 0.07), torso, 0.125),
    Segment(Part.shoulders, j['lShoulder']!, j['rShoulder']!, torso, 0.06),
    Segment(Part.neck, neck + torso.apply(V3.down * 0.04), neck + headFrame.apply(V3.up * Dims.neck), headFrame, 0.045),
    Segment(Part.head, j['head']!, j['head']!, headFrame, Dims.headR),
    for (final (side, ua, fa, th, sh, ft) in [
      ('l', Part.lUpperArm, Part.lForearm, Part.lThigh, Part.lShin, Part.lFoot),
      ('r', Part.rUpperArm, Part.rForearm, Part.rThigh, Part.rShin, Part.rFoot),
    ]) ...[
      Segment(ua, j['${side}Shoulder']!, j['${side}Elbow']!, frames[ua]!, 0.048),
      Segment(fa, j['${side}Elbow']!, j['${side}Hand']!, frames[fa]!, 0.038),
      Segment(th, j['${side}Hip']!, j['${side}Knee']!, frames[th]!, 0.068),
      Segment(sh, j['${side}Knee']!, j['${side}Ankle']!, frames[sh]!, 0.05),
      Segment(ft, j['${side}Heel']!, j['${side}Toe']!, frames[ft]!, 0.035),
    ],
  ];

  var b = Body._(j, segs, frames);
  switch (anchor) {
    case FeetAnchor():
      final mid = (b['lAnkle'] + b['rAnkle']) * 0.5;
      final minY = [b['lToe'], b['rToe'], b['lHeel'], b['rHeel']].map((v) => v.y).reduce((a, c) => a < c ? a : c);
      b = b.translate(V3(-mid.x, -minY + 0.035, -mid.z));
    case PelvisAnchor(:final at):
      b = b.translate(at);
    case HandsAnchor(:final at):
      final mid = (b['lHand'] + b['rHand']) * 0.5;
      b = b.translate(at - mid);
  }
  return b;
}
