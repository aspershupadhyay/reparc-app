import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/features/exercises/catalog/catalog.dart';
import 'package:reparc/features/exercises/catalog/model.dart';
import 'package:reparc/features/exercises/library/library.dart';

void main() {
  final lib = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  test('library loads with hundreds of exercises', () {
    expect(lib.items.length, greaterThan(800));
    expect(lib.byId.length, lib.items.length, reason: 'IDs are unique');
  });

  test('every library entry has a name, a muscle, and both photos on disk', () {
    for (final e in lib.items) {
      expect(e.name.trim(), isNotEmpty, reason: e.id);
      expect(e.primary, isNotEmpty, reason: e.id);
      expect(File(e.startPhoto).existsSync(), isTrue, reason: e.startPhoto);
      expect(File(e.endPhoto).existsSync(), isTrue, reason: e.endPhoto);
    }
  });

  test('every coached guide has library photos', () {
    for (final c in catalog) {
      final id = coachedPhotos[c.id];
      expect(id, isNotNull, reason: c.id);
      expect(lib.byId.containsKey(id), isTrue, reason: '${c.id} -> $id');
    }
  });

  test('each movement is listed once and every body area has entries', () {
    final names = lib.moves.map((m) => m.catalogId).toList();
    expect(names.toSet().length, names.length);
    expect(lib.moves.length, lib.items.length - coachedPhotos.length + catalog.length);
    for (final a in BodyArea.values) {
      expect(lib.moves.where((m) => m.area == a).length, greaterThanOrEqualTo(20), reason: a.label);
    }
  });

  test('saved catalog IDs route to the right screen', () {
    expect(guideRouteFor('back-squat'), '/workout/guide/back-squat');
    expect(guideRouteFor('lib:Air_Bike'), '/workout/move/Air_Bike');
    expect(guideRouteFor(null), isNull);
    expect(guideRouteFor('unknown'), isNull);
    expect(areaForCatalogId('lib:Barbell_Squat', lib), BodyArea.legs);
    expect(areaForCatalogId('bench-press', lib), BodyArea.chest);
  });
}
