import 'dart:math' as math;
import 'dart:typed_data';

import '../rig/anatomy.dart';
import '../rig/math3d.dart';

/// A shaded 3D body for the body map.
///
/// The skin is one set of smooth lofted surfaces: trunk, neck, head, arms,
/// hands, legs, and feet. Each muscle is a region of that surface: skin
/// inside the muscle's volume rises a little (the muscle's relief) and
/// takes the muscle's colour, with a dark groove where it meets the next
/// one. Muscles are part of the surface, not shapes on top of it, so the
/// figure sorts cleanly while it turns and every visible patch can be
/// tapped.
///
/// Units are metres for an adult about 1.75 m tall. Y is up, Z points out
/// of the chest, and X points to the figure's left. The pose is standing,
/// arms a little away from the sides, palms forward. Built once in code; no
/// asset files.
class BodyMesh {
  BodyMesh._({
    required this.positions,
    required this.normals,
    required this.muscle,
    required this.weight,
    required this.groove,
    required this.shadow,
    required this.indices,
    required this.triangleMuscle,
    required this.anchors,
  });

  /// x y z for each vertex.
  final Float32List positions;

  /// Unit normal for each vertex, x y z.
  final Float32List normals;

  /// Index into [mapMuscles] for each vertex, or -1 for plain skin.
  final Int8List muscle;

  /// How strongly each vertex shows its muscle colour, 0 to 1.
  final Float32List weight;

  /// How dark each vertex is from a groove between muscles, 0 to 1.
  final Float32List groove;

  /// Soft shading in creases, such as where the thighs meet the trunk,
  /// 0 to 1. It also hides the seam where two surfaces cross.
  final Float32List shadow;

  /// Three vertex indices per triangle.
  final Uint16List indices;

  /// Index into [mapMuscles] for each triangle, or -1 for skin. A tap on
  /// the triangle picks this muscle.
  final Int8List triangleMuscle;

  /// Centre of each muscle on the body, for forgiving taps.
  final Map<Muscle, List<V3>> anchors;

  int get vertexCount => positions.length ~/ 3;
  int get triangleCount => indices.length ~/ 3;

  static final BodyMesh instance = _build();
}

/// Muscles drawn on the body map. Their index is the id in [BodyMesh].
const mapMuscles = <Muscle>[
  Muscle.upperChest,
  Muscle.chest,
  Muscle.lowerChest,
  Muscle.lats,
  Muscle.upperBack,
  Muscle.traps,
  Muscle.lowerBack,
  Muscle.frontDelts,
  Muscle.sideDelts,
  Muscle.rearDelts,
  Muscle.biceps,
  Muscle.triceps,
  Muscle.forearms,
  Muscle.quads,
  Muscle.hamstrings,
  Muscle.calves,
  Muscle.adductors,
  Muscle.glutes,
  Muscle.abductors,
  Muscle.abs,
  Muscle.lowerAbs,
  Muscle.obliques,
];

// --------------------------------------------------------------- Regions

/// Surfaces of the body. A muscle only colours the parts it lies on, so
/// the biceps never tint the side of the chest.
enum _Part { trunk, upperArm, forearm, thigh, shin, other }

/// One muscle volume. Skin inside it belongs to the muscle.
class _Region {
  _Region(this.muscle, this.parts, this.center, this.radii, M3 frame, this.bump) : toLocal = _transpose(frame);
  final int muscle;
  final Set<_Part> parts;
  final V3 center;
  final V3 radii;
  final M3 toLocal;

  /// How far the middle of the muscle rises above the skin, in metres.
  final double bump;

  /// 0 at the centre, 1 on the edge of the volume.
  double distance(V3 p) {
    final l = toLocal.apply(p - center);
    return math.sqrt(
      (l.x / radii.x) * (l.x / radii.x) + (l.y / radii.y) * (l.y / radii.y) + (l.z / radii.z) * (l.z / radii.z),
    );
  }
}

M3 _transpose(M3 m) => M3([m.m[0], m.m[3], m.m[6], m.m[1], m.m[4], m.m[7], m.m[2], m.m[5], m.m[8]]);

double _smooth(double e0, double e1, double x) {
  final t = ((x - e0) / (e1 - e0)).clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

List<_Region> _regions() {
  final out = <_Region>[];
  void m(Muscle mu, V3 c, V3 r, double bump, {double rz = 0, double ry = 0}) {
    final parts = switch (mu) {
      Muscle.frontDelts || Muscle.sideDelts || Muscle.rearDelts => {_Part.trunk, _Part.upperArm},
      Muscle.biceps || Muscle.triceps => {_Part.upperArm},
      Muscle.forearms => {_Part.forearm},
      Muscle.glutes => {_Part.trunk, _Part.thigh},
      Muscle.quads || Muscle.hamstrings || Muscle.adductors => {_Part.thigh},
      Muscle.calves => {_Part.shin},
      _ => {_Part.trunk},
    };
    for (final s in [1.0, -1.0]) {
      out.add(_Region(mapMuscles.indexOf(mu), parts, V3(c.x * s, c.y, c.z), r, M3.ry(s * ry) * M3.rz(s * rz), bump));
    }
  }

  // Chest: the three bands of the pectoral fan.
  m(Muscle.upperChest, const V3(0.074, 1.378, 0.110), const V3(0.080, 0.036, 0.070), 0.011, rz: -12);
  m(Muscle.chest, const V3(0.082, 1.322, 0.116), const V3(0.090, 0.046, 0.070), 0.017, rz: -4);
  m(Muscle.lowerChest, const V3(0.078, 1.270, 0.110), const V3(0.080, 0.026, 0.070), 0.013, rz: 8);
  // Core: the six-pack in pairs; the lower two pairs are the lower abs.
  for (final y in [1.208, 1.148]) {
    m(Muscle.abs, V3(0.034, y, 0.108), const V3(0.031, 0.031, 0.070), 0.008);
  }
  for (final y in [1.088, 1.026]) {
    m(Muscle.lowerAbs, V3(0.032, y, 0.104), const V3(0.029, 0.033, 0.070), 0.007);
  }
  m(Muscle.obliques, const V3(0.122, 1.110, 0.058), const V3(0.046, 0.088, 0.075), 0.006, rz: 10, ry: -35);
  // Back.
  m(Muscle.traps, const V3(0.070, 1.458, -0.035), const V3(0.095, 0.046, 0.080), 0.012, rz: -22);
  m(Muscle.upperBack, const V3(0.060, 1.338, -0.112), const V3(0.062, 0.078, 0.060), 0.010);
  m(Muscle.lats, const V3(0.122, 1.228, -0.082), const V3(0.072, 0.135, 0.065), 0.015, rz: -14, ry: 20);
  m(Muscle.lowerBack, const V3(0.036, 1.075, -0.100), const V3(0.036, 0.092, 0.060), 0.010);
  // Shoulders: three heads of the deltoid.
  m(Muscle.frontDelts, const V3(0.196, 1.432, 0.036), const V3(0.046, 0.072, 0.040), 0.012, rz: -8);
  m(Muscle.sideDelts, const V3(0.234, 1.420, 0.000), const V3(0.036, 0.072, 0.046), 0.014, rz: -8);
  m(Muscle.rearDelts, const V3(0.196, 1.432, -0.040), const V3(0.046, 0.072, 0.040), 0.012, rz: -8);
  // Arms.
  m(Muscle.biceps, const V3(0.216, 1.268, 0.040), const V3(0.036, 0.088, 0.036), 0.012, rz: -9);
  m(Muscle.triceps, const V3(0.218, 1.282, -0.046), const V3(0.040, 0.104, 0.036), 0.012, rz: -9);
  m(Muscle.forearms, const V3(0.250, 1.075, 0.008), const V3(0.050, 0.088, 0.052), 0.010, rz: -11);
  // Hips and legs.
  m(Muscle.glutes, const V3(0.080, 0.920, -0.104), const V3(0.088, 0.098, 0.070), 0.022);
  m(Muscle.abductors, const V3(0.158, 0.975, -0.020), const V3(0.042, 0.062, 0.062), 0.008);
  m(Muscle.quads, const V3(0.106, 0.705, 0.052), const V3(0.072, 0.172, 0.060), 0.016, rz: -2.5);
  m(Muscle.quads, const V3(0.070, 0.560, 0.040), const V3(0.036, 0.052, 0.050), 0.012);
  m(Muscle.hamstrings, const V3(0.106, 0.705, -0.052), const V3(0.068, 0.172, 0.060), 0.012, rz: -2.5);
  m(Muscle.adductors, const V3(0.058, 0.770, 0.002), const V3(0.036, 0.120, 0.060), 0.006, rz: -4);
  m(Muscle.calves, const V3(0.112, 0.368, -0.046), const V3(0.052, 0.102, 0.052), 0.014, rz: 1.5);
  return out;
}

// ------------------------------------------------------------------ Build

class _Builder {
  final pos = <double>[];
  final nrm = <double>[];
  final idx = <int>[];
  final regions = _regions();
  final mus = <int>[];
  final wgt = <double>[];
  final grv = <double>[];
  final shd = <double>[];

  /// Adds a closed grid: rows of ring points, each row closed on itself.
  /// Muscle regions raise and colour the points; normals are then taken
  /// from the raised surface. The first and last rows are capped.
  void grid(List<List<V3>> rows, List<List<V3>> baseNormals, {_Part part = _Part.other}) {
    final nr = rows.length, seg = rows.first.length;
    final p = [for (final r in rows) List<V3>.of(r)];
    final tag = List.generate(nr, (_) => List.filled(seg, -1));
    final w = List.generate(nr, (_) => List.filled(seg, 0.0));
    final g = List.generate(nr, (_) => List.filled(seg, 0.0));
    final mine = [
      for (final reg in regions)
        if (reg.parts.contains(part)) reg,
    ];
    if (mine.isNotEmpty) {
      for (var r = 0; r < nr; r++) {
        for (var i = 0; i < seg; i++) {
          final v = rows[r][i];
          var best = -1;
          var bestD = 1.0;
          var lift = 0.0;
          for (final reg in mine) {
            final d = reg.distance(v);
            if (d >= 1) continue;
            // A soft dome: full height in the middle, none at the edge.
            lift = math.max(lift, reg.bump * (1 - d * d));
            if (d < bestD) {
              bestD = d;
              best = reg.muscle;
            }
          }
          if (best >= 0) {
            tag[r][i] = best;
            // Wide, soft edges: colour and groove fade over several
            // vertices, so outlines stay smooth without anti-aliasing.
            w[r][i] = _smooth(1.0, 0.45, bestD);
            g[r][i] = _smooth(0.55, 0.92, bestD) * (1 - _smooth(0.92, 1.0, bestD));
            p[r][i] = v + baseNormals[r][i] * lift;
          }
        }
      }
    }
    // Normals from the raised surface: across the ring and along the rows.
    final n = List.generate(nr, (r) {
      return List.generate(seg, (i) {
        final across = p[r][(i + 1) % seg] - p[r][(i - 1 + seg) % seg];
        final along = p[math.min(r + 1, nr - 1)][i] - p[math.max(r - 1, 0)][i];
        var nn = across.cross(along).unit;
        if (nn.dot(baseNormals[r][i]) < 0) nn = -nn;
        return nn.length < 0.5 ? baseNormals[r][i] : nn;
      });
    });

    // The hip crease: the bottom of the trunk and the top of each thigh.
    double crease(V3 v) => switch (part) {
      _Part.trunk => _smooth(0.99, 0.87, v.y),
      _Part.thigh => _smooth(0.90, 0.985, v.y),
      _ => 0,
    };
    final base = pos.length ~/ 3;
    for (var r = 0; r < nr; r++) {
      for (var i = 0; i < seg; i++) {
        _vertex(p[r][i], n[r][i], tag[r][i], w[r][i], g[r][i], crease(p[r][i]));
      }
    }
    int at(int r, int i) => base + r * seg + (i % seg);
    for (var r = 0; r < nr - 1; r++) {
      for (var i = 0; i < seg; i++) {
        idx.addAll([at(r, i), at(r + 1, i), at(r + 1, i + 1), at(r, i), at(r + 1, i + 1), at(r, i + 1)]);
      }
    }
    for (final (r, next) in [(0, 1), (nr - 1, nr - 2)]) {
      final c = p[r].fold(V3.zero, (a, b) => a + b) * (1 / seg);
      final cn = (p[r].first - p[next].first).unit;
      final ci = pos.length ~/ 3;
      _vertex(c, cn.length < 0.5 ? baseNormals[r][0] : cn, -1, 0, 0, crease(c));
      for (var i = 0; i < seg; i++) {
        idx.addAll([ci, at(r, i), at(r, i + 1)]);
      }
    }
  }

  void _vertex(V3 p, V3 n, int muscle, double weight, double groove, double shadow) {
    pos.addAll([p.x, p.y, p.z]);
    nrm.addAll([n.x, n.y, n.z]);
    mus.add(muscle);
    wgt.add(weight);
    grv.add(groove);
    shd.add(shadow);
  }

  /// A smooth tube in [frame] from [origin], down the frame's -Y axis for
  /// [len] metres. Profile points are (t, rx, rz, dz): a fraction along the
  /// tube, the radius across and front to back, and a forward shift. The
  /// profile is resampled every [step] metres with a smooth curve.
  void loft(
    V3 origin,
    M3 frame,
    double len,
    List<(double, double, double, double)> profile, {
    int seg = 28,
    double step = 0.012,
    _Part part = _Part.other,
  }) {
    final rows = <List<V3>>[], normals = <List<V3>>[];
    final count = math.max(2, (len / step).ceil() + 1);
    for (var k = 0; k < count; k++) {
      final t = k / (count - 1);
      final (rx, rz, dz) = _sample(profile, t);
      final row = <V3>[], nr = <V3>[];
      for (var i = 0; i < seg; i++) {
        final th = 2 * math.pi * i / seg;
        row.add(origin + frame.apply(V3(rx * math.cos(th), -t * len, dz + rz * math.sin(th))));
        nr.add(frame.apply(V3(math.cos(th) / rx, 0, math.sin(th) / rz)).unit);
      }
      rows.add(row);
      normals.add(nr);
    }
    grid(rows, normals, part: part);
  }

  /// An ellipsoid of radii [r] in [frame] at [c].
  void ellipsoid(V3 c, V3 r, M3 frame, {int seg = 24, int rings = 16}) {
    final rows = <List<V3>>[], normals = <List<V3>>[];
    for (var k = 1; k < rings; k++) {
      final phi = -math.pi / 2 + math.pi * k / rings;
      final row = <V3>[], nr = <V3>[];
      for (var i = 0; i < seg; i++) {
        final th = 2 * math.pi * i / seg;
        final u = V3(math.cos(phi) * math.cos(th), math.sin(phi), math.cos(phi) * math.sin(th));
        row.add(c + frame.apply(V3(u.x * r.x, u.y * r.y, u.z * r.z)));
        nr.add(frame.apply(V3(u.x / r.x, u.y / r.y, u.z / r.z)).unit);
      }
      rows.add(row);
      normals.add(nr);
    }
    grid(rows, normals);
  }
}

/// Catmull-Rom through the profile, so outlines stay smooth.
(double, double, double) _sample(List<(double, double, double, double)> pr, double t) {
  var k = 0;
  while (k < pr.length - 2 && pr[k + 1].$1 < t) {
    k++;
  }
  final a = pr[math.max(k - 1, 0)], b = pr[k], c = pr[k + 1], d = pr[math.min(k + 2, pr.length - 1)];
  final u = c.$1 == b.$1 ? 0.0 : ((t - b.$1) / (c.$1 - b.$1)).clamp(0.0, 1.0);
  double cr(double p0, double p1, double p2, double p3) {
    final u2 = u * u, u3 = u2 * u;
    return 0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (-p0 + 3 * p1 - 3 * p2 + p3) * u3);
  }

  return (cr(a.$2, b.$2, c.$2, d.$2), cr(a.$3, b.$3, c.$3, d.$3), cr(a.$4, b.$4, c.$4, d.$4));
}

/// Frame for a limb hanging from a joint, turned out by [abd] degrees and
/// forward by [flex] degrees.
M3 _limb(double side, double abd, [double flex = 0]) => M3.rz(side * abd) * M3.rx(-flex);

BodyMesh _build() {
  final b = _Builder();

  // Trunk, from below the hips to the base of the neck. (height, rx, rz, dz)
  const trunk = <(double, double, double, double)>[
    (0.86, 0.090, 0.060, -0.010),
    (0.89, 0.150, 0.100, -0.010),
    (0.92, 0.174, 0.112, -0.010),
    (0.98, 0.166, 0.108, -0.006),
    (1.05, 0.148, 0.100, 0.000),
    (1.12, 0.148, 0.102, 0.004),
    (1.19, 0.158, 0.108, 0.008),
    (1.26, 0.170, 0.114, 0.010),
    (1.33, 0.180, 0.117, 0.010),
    (1.39, 0.183, 0.110, 0.004),
    (1.44, 0.166, 0.096, -0.004),
    (1.475, 0.110, 0.074, -0.008),
    (1.50, 0.062, 0.058, -0.004),
  ];
  const top = 1.50, bottom = 0.86;
  b.loft(
    const V3(0, top, 0),
    M3.identity,
    top - bottom,
    [for (final (y, rx, rz, dz) in trunk.reversed) ((top - y) / (top - bottom), rx, rz, dz)],
    seg: 72,
    step: 0.011,
    part: _Part.trunk,
  );
  // Neck and head.
  b.loft(const V3(0, 1.585, 0.0), M3.identity, 0.11, const [
    (0, 0.050, 0.052, 0.0),
    (1, 0.058, 0.060, -0.004),
  ], seg: 24);
  b.ellipsoid(const V3(0, 1.648, 0.012), const V3(0.082, 0.112, 0.098), M3.identity, seg: 28, rings: 18);

  for (final s in [1.0, -1.0]) {
    // Arms hang 9° out from the sides.
    final shoulder = V3(s * 0.19, 1.43, -0.005);
    final upper = _limb(s, 9);
    b.loft(
      shoulder + const V3(0, 0.035, 0),
      upper,
      0.325,
      const [
        (0.00, 0.048, 0.050, 0.0),
        (0.14, 0.056, 0.058, 0.0),
        (0.42, 0.047, 0.050, 0.004),
        (0.78, 0.040, 0.043, 0.0),
        (1.00, 0.036, 0.038, 0.0),
      ],
      seg: 36,
      part: _Part.upperArm,
    );
    final elbow = shoulder + upper.apply(const V3(0, -0.29, 0));
    final fore = _limb(s, 11, 4);
    b.loft(
      elbow,
      fore,
      0.265,
      const [
        (0.00, 0.037, 0.037, 0.0),
        (0.22, 0.044, 0.040, 0.004),
        (0.65, 0.032, 0.026, 0.0),
        (1.00, 0.026, 0.020, 0.0),
      ],
      seg: 30,
      part: _Part.forearm,
    );
    final wrist = elbow + fore.apply(const V3(0, -0.265, 0));
    b.ellipsoid(wrist + fore.apply(const V3(0, -0.07, 0.004)), const V3(0.038, 0.075, 0.017), fore, seg: 18, rings: 12);

    // Legs.
    final hip = V3(s * 0.095, 0.90, 0);
    final thigh = _limb(s, 2.5);
    b.loft(
      hip + const V3(0, 0.085, 0),
      thigh,
      0.505,
      const [
        (0.00, 0.074, 0.080, -0.004),
        (0.12, 0.088, 0.094, 0.002),
        (0.22, 0.086, 0.092, 0.006),
        (0.55, 0.068, 0.072, 0.006),
        (0.88, 0.052, 0.056, 0.0),
        (1.00, 0.050, 0.054, 0.0),
      ],
      seg: 44,
      part: _Part.thigh,
    );
    final knee = hip + thigh.apply(const V3(0, -0.42, 0));
    final shin = _limb(s, -1.5);
    b.loft(
      knee,
      shin,
      0.405,
      const [
        (0.00, 0.050, 0.052, 0.0),
        (0.25, 0.052, 0.058, -0.012),
        (0.62, 0.037, 0.039, -0.004),
        (1.00, 0.030, 0.032, 0.0),
      ],
      seg: 36,
      part: _Part.shin,
    );
    final ankle = knee + shin.apply(const V3(0, -0.405, 0));
    b.ellipsoid(ankle + const V3(0, -0.035, 0.055), const V3(0.044, 0.034, 0.118), M3.identity, seg: 20, rings: 12);
  }

  // Triangles take the muscle most of their corners have.
  final tri = Int8List(b.idx.length ~/ 3);
  for (var t = 0; t < tri.length; t++) {
    final a = b.mus[b.idx[t * 3]], c = b.mus[b.idx[t * 3 + 1]], d = b.mus[b.idx[t * 3 + 2]];
    tri[t] = a == c || a == d ? a : (c == d ? c : (a >= 0 ? a : (c >= 0 ? c : d)));
  }
  final anchors = <Muscle, List<V3>>{};
  for (final r in b.regions) {
    (anchors[mapMuscles[r.muscle]] ??= []).add(r.center);
  }
  return BodyMesh._(
    positions: Float32List.fromList(b.pos),
    normals: Float32List.fromList(b.nrm),
    muscle: Int8List.fromList(b.mus),
    weight: Float32List.fromList(b.wgt),
    groove: Float32List.fromList(b.grv),
    shadow: Float32List.fromList(b.shd),
    indices: Uint16List.fromList(b.idx),
    triangleMuscle: tri,
    anchors: anchors,
  );
}
