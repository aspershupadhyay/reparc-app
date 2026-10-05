import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'anatomy.dart';
import 'equipment.dart';
import 'math3d.dart';
import 'skeleton.dart';

/// Colours for the body model. The viewer always sits on a dark panel.
class RigStyle {
  const RigStyle({
    required this.body,
    required this.primary,
    required this.secondary,
    required this.steel,
    required this.plate,
    required this.pad,
    required this.floor,
    required this.floorLine,
    required this.label,
    required this.labelText,
  });

  final Color body;
  final Color primary;
  final Color secondary;
  final Color steel;
  final Color plate;
  final Color pad;
  final Color floor;
  final Color floorLine;
  final Color label;
  final Color labelText;
}

/// Space the camera keeps for the whole movement, so the figure does not
/// jump in size while it moves or turns.
class Fit {
  const Fit(this.center, this.radiusH, this.minY, this.maxY);
  final V3 center;
  final double radiusH;
  final double minY;
  final double maxY;

  static Fit of(Iterable<V3> points) {
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    var minZ = double.infinity, maxZ = -double.infinity;
    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
      minZ = math.min(minZ, p.z);
      maxZ = math.max(maxZ, p.z);
    }
    final c = V3((minX + maxX) / 2, (minY + maxY) / 2, (minZ + maxZ) / 2);
    var r = 0.0;
    for (final p in points) {
      r = math.max(r, math.sqrt((p.x - c.x) * (p.x - c.x) + (p.z - c.z) * (p.z - c.z)));
    }
    return Fit(c, r + 0.12, minY - 0.05, maxY + 0.12);
  }
}

/// Points that define the space a body and its equipment use.
Iterable<V3> scenePoints(Body b, List<Equip> equip) sync* {
  yield* b.j.values;
  yield V3(b['pelvis'].x, 0, b['pelvis'].z);
  for (final e in equip) {
    switch (e) {
      case Barbell(:final length, :final plates):
        final (mid, d) = barThroughHands(b);
        final r = plates ? 0.23 : 0.02;
        yield mid + d * (length / 2) + V3.up * r;
        yield mid - d * (length / 2) - V3.up * r;
      case Block():
        yield* blockCorners(e);
      case PullUpBar(:final height):
        yield V3(0.6, height + 0.1, b['lHand'].z);
        yield V3(-0.6, height + 0.1, b['lHand'].z);
      case Cable(:final anchor):
        yield anchor;
      default:
        break;
    }
  }
}

class Camera {
  Camera(this.yaw, this.pitch, this.fit, Size size) {
    final rH = fit.radiusH;
    final hY = fit.maxY - fit.minY;
    scale = math.min(size.width / (2 * rH), size.height / (hY * 1.08));
    origin = Offset(size.width / 2, size.height / 2 + scale * 0.0);
    view = M3.rx(pitch) * M3.ry(-yaw);
  }

  final double yaw;
  final double pitch;
  final Fit fit;
  late final double scale;
  late final Offset origin;
  late final M3 view;

  V3 _v(V3 p) => view.apply(V3(p.x - fit.center.x, p.y - (fit.minY + fit.maxY) / 2, p.z - fit.center.z));
  Offset at(V3 p) {
    final v = _v(p);
    return origin + Offset(v.x * scale, -v.y * scale);
  }

  double depth(V3 p) => _v(p).z;
}

class _Item {
  _Item(this.depth, this.draw);
  final double depth;
  final void Function(Canvas c) draw;
}

/// Draws the posed body, its equipment, muscle highlights, and joint
/// angle labels.
void paintRig(
  Canvas canvas,
  Size size, {
  required Body body,
  required List<Equip> equip,
  required Set<Muscle> primary,
  required Set<Muscle> secondary,
  required List<String> angles,
  required Camera cam,
  required RigStyle style,
  required TextStyle labelStyle,
}) {
  final items = <_Item>[];
  final s = cam.scale;

  Color shade(Color c, double depth) {
    final t = ((depth / cam.fit.radiusH).clamp(-1.0, 1.0) + 1) / 2; // 0 far, 1 near
    return Color.lerp(Color.lerp(c, const Color(0xFF000000), 0.38)!, c, t)!;
  }

  void capsule(V3 a, V3 b, double r, Color color, {double bias = 0, bool gloss = true}) {
    final d = (cam.depth(a) + cam.depth(b)) / 2 + bias;
    items.add(
      _Item(d, (c) {
        final pa = cam.at(a), pb = cam.at(b);
        final col = shade(color, d);
        final paint = Paint()
          ..color = col
          ..strokeWidth = 2 * r * s
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        if ((pa - pb).distance < 0.5) {
          c.drawCircle(pa, r * s, Paint()..color = col);
        } else {
          c.drawLine(pa, pb, paint);
        }
        if (gloss) {
          final off = Offset(-r * s * 0.32, -r * s * 0.32);
          final g = Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.13)
            ..strokeWidth = r * s * 0.7
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;
          if ((pa - pb).distance < 0.5) {
            c.drawCircle(pa + off, r * s * 0.45, Paint()..color = g.color);
          } else {
            c.drawLine(pa + off, pb + off, g);
          }
        }
      }),
    );
  }

  void polygon(List<V3> pts, Color color, {double bias = 0, Color? stroke}) {
    final d = pts.map(cam.depth).reduce((a, b) => a + b) / pts.length + bias;
    items.add(
      _Item(d, (c) {
        final path = Path()..addPolygon(pts.map(cam.at).toList(), true);
        c.drawPath(path, Paint()..color = shade(color, d));
        if (stroke != null) {
          c.drawPath(
            path,
            Paint()
              ..color = stroke
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      }),
    );
  }

  List<V3> disc(V3 center, V3 axis, double r, [int n = 22]) {
    final a = axis.unit;
    final u = (a.cross(V3.up).length < 0.1 ? a.cross(V3.fwd) : a.cross(V3.up)).unit;
    final w = a.cross(u).unit;
    return [
      for (var i = 0; i < n; i++)
        center + u * (r * math.cos(2 * math.pi * i / n)) + w * (r * math.sin(2 * math.pi * i / n)),
    ];
  }

  // Floor: a disc with rings, so turning the view is easy to follow.
  final floorC = V3(body['pelvis'].x, 0, body['pelvis'].z);
  final floorPts = disc(floorC, V3.up, 1.15, 48);
  canvas.drawPath(Path()..addPolygon(floorPts.map(cam.at).toList(), true), Paint()..color = style.floor);
  for (final r in [0.55, 0.85]) {
    canvas.drawPath(
      Path()..addPolygon(disc(floorC, V3.up, r, 48).map(cam.at).toList(), true),
      Paint()
        ..color = style.floorLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
  // Soft shadow under the body.
  final shadowC = V3(body['pelvis'].x, 0.002, body['pelvis'].z);
  canvas.drawPath(
    Path()..addPolygon(disc(shadowC, V3.up, 0.32, 32).map(cam.at).toList(), true),
    Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
  );

  // Body.
  for (final seg in body.segments) {
    capsule(seg.a, seg.b, seg.radius, style.body);
  }

  // Muscles. Primary wins when a muscle is in both sets.
  for (final m in muscleCapsules(body, primary)) {
    capsule(m.a, m.b, m.radius, style.primary, bias: 0.004, gloss: false);
  }
  for (final m in muscleCapsules(body, secondary.difference(primary))) {
    capsule(m.a, m.b, m.radius, style.secondary, bias: 0.003, gloss: false);
  }

  // Equipment.
  for (final e in equip) {
    switch (e) {
      case Barbell(:final plates, :final length):
        final (mid, d) = barThroughHands(body);
        capsule(mid - d * (length / 2), mid + d * (length / 2), 0.014, style.steel);
        if (plates) {
          for (final k in [-1.0, 1.0]) {
            for (final (off, r) in [(0.62, 0.225), (0.67, 0.225)]) {
              polygon(disc(mid + d * (k * off), d, r), style.plate, stroke: style.steel.withValues(alpha: 0.5));
            }
            capsule(mid + d * (k * 0.57), mid + d * (k * 0.59), 0.03, style.steel);
          }
        }
      case Dumbbells(:final neutral):
        for (final side in ['l', 'r']) {
          final h = body['${side}Hand'];
          final f = body.frames[side == 'l' ? Part.lForearm : Part.rForearm]!;
          final axis = neutral ? f.zAxis : f.xAxis;
          capsule(h - axis * 0.08, h + axis * 0.08, 0.016, style.steel);
          for (final k in [-1.0, 1.0]) {
            polygon(disc(h + axis * (k * 0.1), axis, 0.075), style.plate, stroke: style.steel.withValues(alpha: 0.5));
          }
        }
      case HeldWeight():
        final h = (body['lHand'] + body['rHand']) * 0.5;
        final down = body.frames[Part.lForearm]!.apply(V3.down);
        capsule(h + down * 0.1, h + down * 0.1, 0.11, style.plate);
      case PullUpBar(:final height):
        final z = (body['lHand'].z + body['rHand'].z) / 2;
        capsule(V3(0.62, height, z), V3(-0.62, height, z), 0.017, style.steel);
        for (final x in [0.62, -0.62]) {
          capsule(V3(x, height, z), V3(x, height + 0.35, z), 0.022, style.steel);
        }
      case DipBars(:final height):
        for (final x in [0.27, -0.27]) {
          capsule(V3(x, height, -0.3), V3(x, height, 0.35), 0.02, style.steel);
          for (final zz in [-0.3, 0.35]) {
            capsule(V3(x, height, zz), V3(x, 0, zz), 0.022, style.steel);
          }
        }
      case Cable(:final anchor, :final hand):
        final h = hand == null ? (body['lHand'] + body['rHand']) * 0.5 : body['${hand}Hand'];
        capsule(anchor, h, 0.006, style.steel, gloss: false);
        capsule(anchor, anchor, 0.04, style.plate);
        // The column is see-through so it never hides the body.
        capsule(
          V3(anchor.x, 0, anchor.z),
          V3(anchor.x, 2.1, anchor.z),
          0.03,
          style.plate.withValues(alpha: 0.45),
          gloss: false,
        );
      case Block():
        final corners = blockCorners(e);
        for (final (i, f) in blockFaces.indexed) {
          polygon([for (final k in f) corners[k]], i == 3 && e.pad ? style.pad : style.plate, bias: -0.01);
        }
      case Mat():
        final c = body['pelvis'];
        polygon(
          [
            V3(c.x - 0.3, 0.004, c.z - 0.95),
            V3(c.x + 0.3, 0.004, c.z - 0.95),
            V3(c.x + 0.3, 0.004, c.z + 0.95),
            V3(c.x - 0.3, 0.004, c.z + 0.95),
          ],
          style.pad,
          bias: -5,
        );
    }
  }

  items.sort((a, b) => a.depth.compareTo(b.depth));
  for (final i in items) {
    i.draw(canvas);
  }

  // Joint angle notation, always on top.
  for (final joint in angles) {
    final (oa, v, ob) = Body.jointTriple(joint);
    final pv = cam.at(body[v]);
    final da = cam.at(body[oa]) - pv, db = cam.at(body[ob]) - pv;
    if (da.distance < 12 || db.distance < 12) continue;
    final a1 = math.atan2(da.dy, da.dx), a2 = math.atan2(db.dy, db.dx);
    var sweep = a2 - a1;
    while (sweep > math.pi) {
      sweep -= 2 * math.pi;
    }
    while (sweep < -math.pi) {
      sweep += 2 * math.pi;
    }
    final r = math.min(26.0, math.min(da.distance, db.distance) * 0.45);
    canvas.drawArc(
      Rect.fromCircle(center: pv, radius: r),
      a1,
      sweep,
      false,
      Paint()
        ..color = style.label
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(pv, 3, Paint()..color = style.label);
    final mid = a1 + sweep / 2;
    final text = '${body.angle(joint).round()}°';
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: labelStyle.copyWith(color: style.labelText),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    final at = pv + Offset(math.cos(mid), math.sin(mid)) * (r + 18);
    final box = Rect.fromCenter(center: at, width: tp.width + 10, height: tp.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(8)), Paint()..color = style.label);
    tp.paint(canvas, box.topLeft + const Offset(5, 2));
  }
}
