import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import '../rig/anatomy.dart';
import '../rig/math3d.dart';
import 'body_model.dart';

/// Colours for one frame of the body map.
class BodyPaint {
  const BodyPaint({required this.skin, required this.muscle, required this.rim});

  final Color skin;

  /// Colour for each muscle in this frame. A muscle missing here shows as
  /// skin.
  final Map<Muscle, Color> muscle;

  /// Back light on the outline, so the figure stands off a dark panel.
  final Color rim;
}

/// One drawn frame: where everything landed on screen, for taps.
class BodyFrame {
  BodyFrame._(this.mesh, this.xy, this.order, Map<Muscle, List<Offset>> Function() anchors) : _anchors = anchors;

  final BodyMesh mesh;

  /// Screen x y of each vertex.
  final Float32List xy;

  /// Visible triangles, far first.
  final Int32List order;

  final Map<Muscle, List<Offset>> Function() _anchors;

  /// Muscle centres on screen that face the viewer and are not hidden
  /// behind another part of the body (an arm in front of the back, say).
  /// Worked out on first use, so a frame that is never tapped costs
  /// nothing.
  late final Map<Muscle, List<Offset>> anchorsOnScreen = () {
    final out = <Muscle, List<Offset>>{};
    _anchors().forEach((m, pts) {
      final shown = [
        for (final p in pts)
          if (_under(p) == m) p,
      ];
      if (shown.isNotEmpty) out[m] = shown;
    });
    return out;
  }();

  /// The muscle of the nearest triangle under [p], or null for skin or
  /// empty space.
  Muscle? _under(Offset p) {
    final t = _triangleAt(p);
    if (t < 0) return null;
    final m = mesh.triangleMuscle[t];
    return m < 0 ? null : mapMuscles[m];
  }

  /// The nearest drawn triangle under [p], or -1.
  int _triangleAt(Offset p) {
    final idx = mesh.indices;
    for (var k = order.length - 1; k >= 0; k--) {
      final t = order[k];
      final a = idx[t * 3] * 2, b = idx[t * 3 + 1] * 2, c = idx[t * 3 + 2] * 2;
      if (_inside(p, xy[a], xy[a + 1], xy[b], xy[b + 1], xy[c], xy[c + 1])) return t;
    }
    return -1;
  }

  /// The muscle under [p], or null for skin or empty space. A tap on skin
  /// within [slop] pixels of a facing muscle centre picks that muscle, so
  /// small muscles are easy to hit with a finger.
  Muscle? hit(Offset p, {double slop = 24}) {
    final t = _triangleAt(p);
    if (t >= 0 && mesh.triangleMuscle[t] >= 0) return mapMuscles[mesh.triangleMuscle[t]];
    final onBody = t >= 0;
    Muscle? best;
    var bestD = onBody ? slop : slop * 0.6;
    anchorsOnScreen.forEach((m, pts) {
      for (final a in pts) {
        final d = (a - p).distance;
        if (d < bestD) {
          bestD = d;
          best = m;
        }
      }
    });
    return best;
  }

  static bool _inside(Offset p, double ax, double ay, double bx, double by, double cx, double cy) {
    double side(double x1, double y1, double x2, double y2) => (x2 - x1) * (p.dy - y1) - (y2 - y1) * (p.dx - x1);
    final d1 = side(ax, ay, bx, by), d2 = side(bx, by, cx, cy), d3 = side(cx, cy, ax, ay);
    final neg = d1 < 0 || d2 < 0 || d3 < 0;
    final pos = d1 > 0 || d2 > 0 || d3 > 0;
    return !(neg && pos);
  }
}

/// Middle of the figure, which the view turns around.
const _pivot = V3(0, 0.89, 0);

/// Camera distance in metres: a slight perspective, like a phone held at
/// arm's length.
const _camera = 3.4;

/// Depth buckets for sorting triangles far to near.
const _buckets = 4096;

/// Draws [mesh] turned by [yaw] (degrees; 0 shows the front, 180 the back)
/// and tilted by [pitch], fitted into [size] and scaled by [zoom]. Returns
/// what was drawn, for taps.
BodyFrame paintBody(
  Canvas canvas,
  Size size,
  BodyMesh mesh, {
  required double yaw,
  required double pitch,
  required BodyPaint paint,
  double zoom = 1,
}) {
  final rot = M3.rx(pitch) * M3.ry(-yaw);
  final r = rot.m;
  final nv = mesh.vertexCount;
  final pos = mesh.positions, nrm = mesh.normals;

  // Fit 1.85 m of height into the box.
  final scale = size.height * 0.95 / 1.85 * zoom;
  final cx = size.width / 2, cy = size.height / 2;

  // Muscle colours by id, with skin for muscles not given.
  final skin = paint.skin;
  final cols = [for (final m in mapMuscles) paint.muscle[m] ?? skin];

  // Lights in view space: a key from the upper left front, a soft fill
  // from the right, and a rim from behind.
  final key = const V3(-0.45, 0.55, 0.70).unit;
  final fill = const V3(0.65, 0.05, 0.45).unit;
  final half = (key + const V3(0, 0, 1)).unit;

  final xy = Float32List(nv * 2);
  final vz = Float32List(nv);
  final colors = Int32List(nv);
  for (var v = 0; v < nv; v++) {
    final i = v * 3;
    final px = pos[i] - _pivot.x, py = pos[i + 1] - _pivot.y, pz = pos[i + 2] - _pivot.z;
    final x = r[0] * px + r[1] * py + r[2] * pz;
    final y = r[3] * px + r[4] * py + r[5] * pz;
    final z = r[6] * px + r[7] * py + r[8] * pz;
    final k = _camera / (_camera - z);
    xy[v * 2] = cx + x * k * scale;
    xy[v * 2 + 1] = cy - y * k * scale;
    vz[v] = z;

    final nx0 = nrm[i], ny0 = nrm[i + 1], nz0 = nrm[i + 2];
    final nx = r[0] * nx0 + r[1] * ny0 + r[2] * nz0;
    final ny = r[3] * nx0 + r[4] * ny0 + r[5] * nz0;
    final nz = r[6] * nx0 + r[7] * ny0 + r[8] * nz0;

    final m = mesh.muscle[v];
    final w = m < 0 ? 0.0 : mesh.weight[v];
    final base = m < 0 || w == 0 ? skin : Color.lerp(skin, cols[m], w)!;
    final ao = mesh.shadow[v];
    final diffuse = math.max(0.0, nx * key.x + ny * key.y + nz * key.z);
    final soft = math.max(0.0, nx * fill.x + ny * fill.y + nz * fill.z);
    // Ambient light is what the creases block; direct light only dims a
    // little in them.
    final light = (0.30 * (1 - ao) + (0.62 * diffuse + 0.16 * soft) * (1 - 0.45 * ao)) * (1 - 0.26 * mesh.groove[v]);
    final spec = math.max(0.0, nx * half.x + ny * half.y + nz * half.z);
    final gloss = (0.07 + 0.12 * w) * math.pow(spec, 24) * (1 - ao);
    final rim = 0.5 * math.pow(1 - nz.clamp(0.0, 1.0), 3) * (1 - 0.6 * ao);
    int ch(double c, double rc) => (c * 255 * light + 255 * gloss + rc * 255 * rim).clamp(0.0, 255.0).round();
    colors[v] =
        (0xFF << 24) | (ch(base.r, paint.rim.r) << 16) | (ch(base.g, paint.rim.g) << 8) | ch(base.b, paint.rim.b);
  }

  // Keep triangles that wind counter-clockwise on screen (they face the
  // viewer), then sort them far to near by bucket.
  final idx = mesh.indices;
  final nt = mesh.triangleCount;
  final depth = Float32List(nt);
  final keep = Int32List(nt);
  var count = 0;
  var zMin = double.infinity, zMax = double.negativeInfinity;
  for (var t = 0; t < nt; t++) {
    final a = idx[t * 3], b = idx[t * 3 + 1], c = idx[t * 3 + 2];
    final ax = xy[a * 2], ay = xy[a * 2 + 1];
    final area = (xy[b * 2] - ax) * (xy[c * 2 + 1] - ay) - (xy[b * 2 + 1] - ay) * (xy[c * 2] - ax);
    // Screen y points down, so a triangle that faces the viewer has a
    // negative area here.
    if (area >= 0) continue;
    final d = vz[a] + vz[b] + vz[c];
    depth[t] = d;
    if (d < zMin) zMin = d;
    if (d > zMax) zMax = d;
    keep[count++] = t;
  }
  final order = Int32List(count);
  if (count > 0) {
    final span = math.max(zMax - zMin, 1e-6);
    final bucketOf = Int32List(count);
    final start = Int32List(_buckets + 1);
    for (var k = 0; k < count; k++) {
      final b = ((depth[keep[k]] - zMin) / span * (_buckets - 1)).floor().clamp(0, _buckets - 1);
      bucketOf[k] = b;
      start[b + 1]++;
    }
    for (var b = 0; b < _buckets; b++) {
      start[b + 1] += start[b];
    }
    for (var k = 0; k < count; k++) {
      order[start[bucketOf[k]]++] = keep[k];
    }
  }
  final drawIdx = Uint16List(count * 3);
  for (var k = 0; k < count; k++) {
    final t = order[k];
    drawIdx[k * 3] = idx[t * 3];
    drawIdx[k * 3 + 1] = idx[t * 3 + 1];
    drawIdx[k * 3 + 2] = idx[t * 3 + 2];
  }

  // A soft floor shadow grounds the figure.
  final feet = rot.apply(const V3(0, 0.0, 0) - _pivot);
  final fk = _camera / (_camera - feet.z);
  final shadowC = Offset(cx + feet.x * fk * scale, cy - feet.y * fk * scale);
  canvas.drawOval(
    Rect.fromCenter(
      center: shadowC,
      width: 0.62 * scale,
      height: 0.62 * scale * (0.18 + 0.5 * math.sin(pitch.abs() * math.pi / 180)),
    ),
    Paint()
      ..color = const Color(0x66000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
  );

  canvas.drawVertices(
    Vertices.raw(VertexMode.triangles, xy, colors: colors, indices: drawIdx),
    BlendMode.dst,
    Paint()..isAntiAlias = true,
  );

  return BodyFrame._(mesh, xy, order, () {
    final anchors = <Muscle, List<Offset>>{};
    mesh.anchors.forEach((m, list) {
      for (final a in list) {
        // Only points whose skin faces the viewer.
        if (rot.apply(a.normal).z < 0.35) continue;
        final v = rot.apply(a.point - _pivot);
        final k = _camera / (_camera - v.z);
        (anchors[m] ??= []).add(Offset(cx + v.x * k * scale, cy - v.y * k * scale));
      }
    });
    return anchors;
  });
}
