import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../rig/anatomy.dart';
import '../rig/math3d.dart';

/// A shaded 3D body for the body map.
///
/// The body is MakeHuman's CC0 base mesh, shaped as an athletic young
/// adult with MakeHuman's own sliders, arms lowered, and split finer on the
/// trunk and limbs. Each vertex belongs to a muscle or to bare skin; seams
/// between muscles and between the heads of one muscle are dark grooves,
/// and soft shadow (ambient occlusion) is baked in. `tool/body/build.py`
/// makes the asset; see `tool/body/README.md`.
///
/// Units are metres for an adult 1.78 m tall, feet on y = 0. Y is up, Z
/// points out of the chest, and X points to the figure's left. The pose is
/// standing, arms a little away from the sides.
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

  /// The asset that holds the mesh.
  static const asset = 'assets/body/body.bin';

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

  /// Baked soft shadow: 0 open to the sky, 1 deep in a crease.
  final Float32List shadow;

  /// Three vertex indices per triangle, counter-clockwise seen from
  /// outside.
  final Uint16List indices;

  /// Index into [mapMuscles] for each triangle, or -1 for skin. A tap on
  /// the triangle picks this muscle.
  final Int8List triangleMuscle;

  /// Points well inside each muscle, with the way the skin faces there,
  /// for forgiving taps.
  final Map<Muscle, List<BodyAnchor>> anchors;

  int get vertexCount => positions.length ~/ 3;
  int get triangleCount => indices.length ~/ 3;

  static BodyMesh? _cache;

  /// Loads and caches the mesh from the app's assets.
  static Future<BodyMesh> load([AssetBundle? bundle]) async {
    final cached = _cache;
    if (cached != null) return cached;
    final data = await (bundle ?? rootBundle).load(asset);
    return _cache = BodyMesh.parse(data);
  }

  /// Reads the binary written by `tool/body/build.py`.
  factory BodyMesh.parse(ByteData data) {
    final r = _Reader(data);
    if (r.ascii(4) != 'RBDY') throw const FormatException('Not a body mesh');
    final version = r.u32();
    if (version != 1) throw FormatException('Unknown body mesh version $version');
    final nv = r.u32(), nt = r.u32(), na = r.u32();
    final positions = Float32List(nv * 3);
    for (var i = 0; i < nv * 3; i++) {
      positions[i] = r.f32();
    }
    final normals = Float32List(nv * 3);
    for (var v = 0; v < nv; v++) {
      final x = r.i8() / 127, y = r.i8() / 127, z = r.i8() / 127;
      final l = math.sqrt(x * x + y * y + z * z);
      final k = l < 1e-6 ? 0.0 : 1 / l;
      normals[v * 3] = x * k;
      normals[v * 3 + 1] = y * k;
      normals[v * 3 + 2] = z * k;
    }
    final muscle = Int8List(nv);
    for (var v = 0; v < nv; v++) {
      muscle[v] = r.i8();
    }
    Float32List unit() {
      final out = Float32List(nv);
      for (var v = 0; v < nv; v++) {
        out[v] = r.u8() / 255;
      }
      return out;
    }

    final weight = unit(), groove = unit(), shadow = unit();
    final indices = Uint16List(nt * 3);
    for (var i = 0; i < nt * 3; i++) {
      indices[i] = r.u16();
    }
    final triangleMuscle = Int8List(nt);
    for (var t = 0; t < nt; t++) {
      triangleMuscle[t] = r.i8();
    }
    final anchors = <Muscle, List<BodyAnchor>>{};
    for (var a = 0; a < na; a++) {
      final m = r.i8();
      final p = V3(r.f32(), r.f32(), r.f32());
      final n = V3(r.f32(), r.f32(), r.f32());
      (anchors[mapMuscles[m]] ??= []).add(BodyAnchor(p, n));
    }
    if (r.offset != data.lengthInBytes) throw const FormatException('Body mesh has extra bytes');
    return BodyMesh._(
      positions: positions,
      normals: normals,
      muscle: muscle,
      weight: weight,
      groove: groove,
      shadow: shadow,
      indices: indices,
      triangleMuscle: triangleMuscle,
      anchors: anchors,
    );
  }
}

/// The body mesh, loaded once from the app's assets.
final bodyMeshProvider = FutureProvider<BodyMesh>((ref) => BodyMesh.load());

/// A point on a muscle and the way the skin faces there.
class BodyAnchor {
  const BodyAnchor(this.point, this.normal);
  final V3 point;
  final V3 normal;
}

/// Muscles drawn on the body map. Their index is the id in [BodyMesh] and
/// in `tool/body/muscles.py` (NAMES); keep the two lists in step.
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

class _Reader {
  _Reader(this.data);
  final ByteData data;
  int offset = 0;

  String ascii(int n) {
    final s = String.fromCharCodes([for (var i = 0; i < n; i++) data.getUint8(offset + i)]);
    offset += n;
    return s;
  }

  int u32() {
    final v = data.getUint32(offset, Endian.little);
    offset += 4;
    return v;
  }

  int u16() {
    final v = data.getUint16(offset, Endian.little);
    offset += 2;
    return v;
  }

  int u8() => data.getUint8(offset++);

  int i8() => data.getInt8(offset++);

  double f32() {
    final v = data.getFloat32(offset, Endian.little);
    offset += 4;
    return v;
  }
}
