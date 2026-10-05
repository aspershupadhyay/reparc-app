import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/features/exercises/catalog/catalog.dart';
import 'package:reparc/features/exercises/catalog/model.dart';
import 'package:reparc/features/exercises/rig/skeleton.dart';
import 'package:reparc/features/exercises/viewer.dart';

void main() {
  test('every body area has coached exercises', () {
    for (final a in BodyArea.values) {
      expect(exercisesFor(a).length, greaterThanOrEqualTo(5), reason: a.label);
    }
  });

  test('ids are unique and stable in format', () {
    final ids = catalog.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(RegExp(r'^[a-z0-9-]+$').hasMatch(id), isTrue, reason: id);
    }
  });

  test('every exercise has complete coaching', () {
    for (final e in catalog) {
      expect(e.setup, isNotEmpty, reason: e.id);
      expect(e.steps.length, greaterThanOrEqualTo(3), reason: e.id);
      expect(e.cues.length, greaterThanOrEqualTo(3), reason: e.id);
      expect(e.mistakes.length, greaterThanOrEqualTo(3), reason: e.id);
      expect(e.primary, isNotEmpty, reason: e.id);
      for (final s in [e.summary, e.breathing, e.easier, e.harder, e.dose, e.tempo]) {
        expect(s.trim(), isNotEmpty, reason: e.id);
      }
    }
  });

  test('every animation frame solves to finite positions', () {
    for (final e in catalog) {
      expect(e.keys.length, greaterThanOrEqualTo(2), reason: e.id);
      final total = loopSeconds(e.keys);
      for (var i = 0; i <= 20; i++) {
        final body = solve(frameAt(e.keys, total * i / 20).pose, e.anchor);
        for (final v in body.j.values) {
          expect(v.x.isFinite && v.y.isFinite && v.z.isFinite, isTrue, reason: e.id);
        }
        for (final joint in e.angles) {
          final a = body.angle(joint);
          expect(a, inInclusiveRange(0, 180), reason: '${e.id} $joint');
        }
      }
    }
  });

  test('standing exercises keep the feet on the floor', () {
    for (final e in catalog.where((e) => e.anchor is FeetAnchor)) {
      for (final k in e.keys) {
        final b = solve(k.pose, e.anchor);
        final low = [b['lToe'], b['rToe'], b['lHeel'], b['rHeel']].map((v) => v.y).reduce((a, c) => a < c ? a : c);
        expect(low, closeTo(0.035, 0.001), reason: e.id);
      }
    }
  });
}
