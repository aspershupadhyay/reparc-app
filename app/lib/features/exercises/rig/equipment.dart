import 'math3d.dart';
import 'skeleton.dart';

/// Equipment drawn with the body. Positions follow the hands where needed.
sealed class Equip {
  const Equip();
}

class Barbell extends Equip {
  const Barbell({this.plates = true, this.length = 1.9});
  final bool plates;

  /// Bar length in metres. 1.9 is a short Olympic-style bar; 1.25 is an EZ bar.
  final double length;
}

class Dumbbells extends Equip {
  const Dumbbells({this.neutral = true});

  /// True when palms face each other, so the handle runs front to back.
  final bool neutral;
}

/// One weight held in both hands, like a goblet squat or kettlebell swing.
class HeldWeight extends Equip {
  const HeldWeight();
}

class PullUpBar extends Equip {
  const PullUpBar(this.height);
  final double height;
}

class DipBars extends Equip {
  const DipBars(this.height);
  final double height;
}

/// A cable from a fixed anchor to the hands.
class Cable extends Equip {
  const Cable(this.anchor, {this.hand});
  final V3 anchor;

  /// 'l' or 'r' for a one-hand cable. Null attaches to both hands.
  final String? hand;
}

/// A box shape, such as a bench, a seat, or a step.
class Block extends Equip {
  const Block(this.center, this.size, {this.tilt = 0, this.pad = true});
  final V3 center;

  /// Width (x), height (y), and length (z).
  final V3 size;

  /// Tilt about the x axis in degrees, for an incline bench.
  final double tilt;
  final bool pad;
}

class Mat extends Equip {
  const Mat();
}

/// Corners of a [Block], in the standard box order.
List<V3> blockCorners(Block b) {
  final r = M3.rx(b.tilt);
  final h = b.size * 0.5;
  return [
    for (final sx in [-1.0, 1.0])
      for (final sy in [-1.0, 1.0])
        for (final sz in [-1.0, 1.0]) b.center + r.apply(V3(sx * h.x, sy * h.y, sz * h.z)),
  ];
}

/// Faces as corner index lists for [blockCorners].
const blockFaces = [
  [0, 1, 3, 2], // left
  [4, 6, 7, 5], // right
  [0, 4, 5, 1], // bottom
  [2, 3, 7, 6], // top
  [0, 2, 6, 4], // back
  [1, 5, 7, 3], // front
];

/// Bar axis through the hands. Falls back to the body's side axis.
(V3, V3) barThroughHands(Body b) {
  final l = b['lHand'], r = b['rHand'];
  final mid = (l + r) * 0.5;
  final d = l - r;
  return (mid, d.length < 0.05 ? V3.left : d.unit);
}
