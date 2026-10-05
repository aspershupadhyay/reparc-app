import 'dart:math' as math;

/// Small 3D vector for the body model. Y is up. Z points out of the
/// figure's chest. X points to the figure's left.
class V3 {
  const V3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  static const zero = V3(0, 0, 0);
  static const up = V3(0, 1, 0);
  static const down = V3(0, -1, 0);
  static const fwd = V3(0, 0, 1);
  static const left = V3(1, 0, 0);

  V3 operator +(V3 o) => V3(x + o.x, y + o.y, z + o.z);
  V3 operator -(V3 o) => V3(x - o.x, y - o.y, z - o.z);
  V3 operator *(double k) => V3(x * k, y * k, z * k);
  V3 operator -() => V3(-x, -y, -z);

  double dot(V3 o) => x * o.x + y * o.y + z * o.z;
  V3 cross(V3 o) => V3(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  V3 get unit {
    final l = length;
    return l < 1e-9 ? V3.zero : this * (1 / l);
  }

  static V3 lerp(V3 a, V3 b, double t) => a + (b - a) * t;

  @override
  String toString() => 'V3(${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, ${z.toStringAsFixed(3)})';
}

/// Row-major 3x3 rotation matrix.
class M3 {
  const M3(this.m);
  final List<double> m;

  static const identity = M3([1, 0, 0, 0, 1, 0, 0, 0, 1]);

  static double _r(double deg) => deg * math.pi / 180;

  /// Positive angle turns +Y toward +Z.
  factory M3.rx(double deg) {
    final c = math.cos(_r(deg)), s = math.sin(_r(deg));
    return M3([1, 0, 0, 0, c, -s, 0, s, c]);
  }

  /// Positive angle turns +Z toward +X.
  factory M3.ry(double deg) {
    final c = math.cos(_r(deg)), s = math.sin(_r(deg));
    return M3([c, 0, s, 0, 1, 0, -s, 0, c]);
  }

  /// Positive angle turns +X toward +Y.
  factory M3.rz(double deg) {
    final c = math.cos(_r(deg)), s = math.sin(_r(deg));
    return M3([c, -s, 0, s, c, 0, 0, 0, 1]);
  }

  M3 operator *(M3 o) {
    final a = m, b = o.m;
    return M3([
      for (var r = 0; r < 3; r++)
        for (var c = 0; c < 3; c++) a[r * 3] * b[c] + a[r * 3 + 1] * b[3 + c] + a[r * 3 + 2] * b[6 + c],
    ]);
  }

  V3 apply(V3 v) => V3(
    m[0] * v.x + m[1] * v.y + m[2] * v.z,
    m[3] * v.x + m[4] * v.y + m[5] * v.z,
    m[6] * v.x + m[7] * v.y + m[8] * v.z,
  );

  V3 get xAxis => V3(m[0], m[3], m[6]);
  V3 get yAxis => V3(m[1], m[4], m[7]);
  V3 get zAxis => V3(m[2], m[5], m[8]);
}

/// Angle between two vectors in degrees.
double angleDeg(V3 a, V3 b) {
  final d = a.unit.dot(b.unit).clamp(-1.0, 1.0);
  return math.acos(d) * 180 / math.pi;
}
