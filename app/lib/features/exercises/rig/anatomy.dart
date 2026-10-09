import 'math3d.dart';
import 'skeleton.dart';

/// Muscles the app can highlight on the body model.
enum Muscle {
  chest('Mid chest'),
  upperChest('Upper chest'),
  lowerChest('Lower chest'),
  frontDelts('Front shoulders'),
  sideDelts('Side shoulders'),
  rearDelts('Rear shoulders'),
  lats('Lats'),
  upperBack('Upper back'),
  traps('Traps'),
  lowerBack('Lower back'),
  biceps('Biceps'),
  triceps('Triceps'),
  forearms('Forearms'),
  abs('Abs'),
  lowerAbs('Lower abs'),
  obliques('Obliques'),
  glutes('Glutes'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  adductors('Inner thighs'),
  abductors('Outer hips'),
  calves('Calves'),
  hipFlexors('Hip flexors');

  const Muscle(this.label);
  final String label;
}

/// One muscle shape on a body segment.
///
/// [from] and [to] are fractions along the segment. [offset] is in the
/// segment's local frame, in metres. X offsets mirror for the right side.
class _Shape {
  const _Shape(this.part, this.from, this.to, this.offset, this.radius, {this.both = true});
  final Part part;
  final double from;
  final double to;
  final V3 offset;
  final double radius;

  /// For trunk parts, also draw a mirrored copy on the other side.
  final bool both;
}

const _left = {
  Part.lUpperArm: Part.rUpperArm,
  Part.lForearm: Part.rForearm,
  Part.lThigh: Part.rThigh,
  Part.lShin: Part.rShin,
};

/// Trunk shapes use heights in metres above the pelvis centre for [from]
/// and [to]. Limb shapes use fractions along the limb.
const Map<Muscle, List<_Shape>> _shapes = {
  Muscle.chest: [_Shape(Part.chest, 0.29, 0.40, V3(0.07, 0, 0.085), 0.06)],
  Muscle.upperChest: [_Shape(Part.chest, 0.38, 0.44, V3(0.065, 0, 0.09), 0.05)],
  Muscle.lowerChest: [_Shape(Part.chest, 0.25, 0.30, V3(0.07, 0, 0.08), 0.05)],
  Muscle.frontDelts: [_Shape(Part.lUpperArm, 0.0, 0.28, V3(0, 0, 0.022), 0.045)],
  Muscle.sideDelts: [_Shape(Part.lUpperArm, 0.0, 0.28, V3(0.024, 0, 0), 0.045)],
  Muscle.rearDelts: [_Shape(Part.lUpperArm, 0.0, 0.28, V3(0, 0, -0.024), 0.045)],
  Muscle.lats: [_Shape(Part.chest, 0.13, 0.36, V3(0.095, 0, -0.055), 0.06)],
  Muscle.upperBack: [_Shape(Part.chest, 0.30, 0.42, V3(0.05, 0, -0.095), 0.055)],
  Muscle.traps: [_Shape(Part.chest, 0.44, 0.52, V3(0.06, 0, -0.06), 0.045)],
  Muscle.lowerBack: [_Shape(Part.abdomen, 0.05, 0.25, V3(0.035, 0, -0.08), 0.045)],
  Muscle.biceps: [_Shape(Part.lUpperArm, 0.25, 0.85, V3(0, 0, 0.022), 0.036)],
  Muscle.triceps: [_Shape(Part.lUpperArm, 0.15, 0.85, V3(0, 0, -0.022), 0.038)],
  Muscle.forearms: [_Shape(Part.lForearm, 0.05, 0.6, V3(0, 0, 0.008), 0.034)],
  Muscle.abs: [_Shape(Part.abdomen, 0.06, 0.31, V3(0.035, 0, 0.085), 0.042)],
  Muscle.lowerAbs: [_Shape(Part.abdomen, 0.02, 0.12, V3(0.03, 0, 0.085), 0.04)],
  Muscle.obliques: [_Shape(Part.abdomen, 0.08, 0.28, V3(0.09, 0, 0.035), 0.04)],
  Muscle.glutes: [_Shape(Part.pelvis, 0.0, 0.0, V3(0, -0.03, -0.075), 0.075, both: false)],
  Muscle.quads: [_Shape(Part.lThigh, 0.15, 0.85, V3(0, 0, 0.03), 0.055)],
  Muscle.hamstrings: [_Shape(Part.lThigh, 0.2, 0.85, V3(0, 0, -0.03), 0.052)],
  Muscle.adductors: [_Shape(Part.lThigh, 0.1, 0.6, V3(-0.03, 0, 0), 0.045)],
  Muscle.abductors: [_Shape(Part.lThigh, 0.0, 0.22, V3(0.045, 0, -0.01), 0.045)],
  Muscle.calves: [_Shape(Part.lShin, 0.1, 0.5, V3(0, 0, -0.03), 0.045)],
  Muscle.hipFlexors: [_Shape(Part.lThigh, 0.0, 0.3, V3(0, 0, 0.03), 0.045)],
};

/// A capsule to draw for a highlighted muscle.
class MuscleCapsule {
  const MuscleCapsule(this.muscle, this.a, this.b, this.radius);
  final Muscle muscle;
  final V3 a;
  final V3 b;
  final double radius;
}

/// Capsules for [muscles] on [body], both sides.
List<MuscleCapsule> muscleCapsules(Body body, Iterable<Muscle> muscles) {
  final out = <MuscleCapsule>[];
  Segment seg(Part p) => body.segments.firstWhere((s) => s.part == p);
  for (final m in muscles) {
    for (final sh in _shapes[m]!) {
      final limb = _left.containsKey(sh.part);
      final sides = limb
          ? [(sh.part, 1.0), (_left[sh.part]!, -1.0)]
          : sh.both
          ? [(sh.part, 1.0), (sh.part, -1.0)]
          : [(sh.part, 1.0)];
      for (final (part, s) in sides) {
        final g = seg(part);
        final f = g.frame;
        final off = f.apply(V3(sh.offset.x * s, sh.offset.y, sh.offset.z));
        if (part == Part.pelvis) {
          // Glutes: one shape per side behind each hip.
          for (final hip in [body['lHip'], body['rHip']]) {
            final c = hip + off;
            out.add(MuscleCapsule(m, c, c + f.apply(const V3(0, -0.07, 0)), sh.radius));
          }
          continue;
        }
        if (part == Part.chest || part == Part.abdomen) {
          final base = body['pelvis'];
          out.add(
            MuscleCapsule(m, base + f.apply(V3.up * sh.from) + off, base + f.apply(V3.up * sh.to) + off, sh.radius),
          );
          continue;
        }
        final a = g.a + (g.b - g.a) * sh.from + off;
        final b = g.a + (g.b - g.a) * sh.to + off;
        out.add(MuscleCapsule(m, a, b, sh.radius));
      }
    }
  }
  return out;
}
