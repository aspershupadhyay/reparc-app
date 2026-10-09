import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/features/exercises/catalog/catalog.dart';
import 'package:reparc/features/exercises/catalog/model.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/features/exercises/library/move_groups.dart';
import 'package:reparc/features/exercises/muscle_map.dart';
import 'package:reparc/features/exercises/rig/anatomy.dart';

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
    expect(guideRouteFor('back-squat'), '/learn/guide/back-squat');
    expect(guideRouteFor('lib:Air_Bike'), '/learn/move/Air_Bike');
    expect(guideRouteFor(null), isNull);
    expect(guideRouteFor('unknown'), isNull);
    expect(areaForCatalogId('lib:Barbell_Squat', lib), BodyArea.legs);
    expect(areaForCatalogId('bench-press', lib), BodyArea.chest);
  });

  test('every muscle in the browse tree has hand-picked moves that exist', () {
    for (final entry in areaMuscles.entries) {
      for (final m in entry.value) {
        final ids = essentials[m]!;
        expect(
          lib.essentialsFor(m).length,
          ids.length,
          reason: '${m.label}: ${ids.where((id) => !lib.byCatalogId.containsKey(id))}',
        );
        for (final move in lib.essentialsFor(m)) {
          expect(move.area, entry.key, reason: '${move.name} should sit under ${entry.key.label}');
        }
        expect(lib.moves.where((x) => x.target == m && x.kind == MoveKind.strength), isNotEmpty, reason: m.label);
      }
    }
  });

  test('target muscles split shoulders, chest, and core by name', () {
    expect(targetMuscle('shoulders', 'Side Lateral Raise'), Muscle.sideDelts);
    expect(targetMuscle('shoulders', 'Seated Bent-Over Rear Delt Raise'), Muscle.rearDelts);
    expect(targetMuscle('shoulders', 'Standing Military Press'), Muscle.frontDelts);
    expect(targetMuscle('chest', 'Incline Dumbbell Press'), Muscle.upperChest);
    expect(targetMuscle('chest', 'Decline Barbell Bench Press'), Muscle.lowerChest);
    expect(targetMuscle('chest', 'Dumbbell Bench Press'), Muscle.chest);
    expect(targetMuscle('traps', 'Barbell Shrug'), Muscle.traps);
    expect(targetMuscle('abductors', 'Thigh Abductor'), Muscle.abductors);
    expect(targetMuscle('abdominals', 'Hanging Leg Raise'), Muscle.lowerAbs);
    expect(targetMuscle('biceps', 'Reverse Barbell Curl'), Muscle.forearms);
    expect(targetMuscle('abdominals', 'Russian Twist'), Muscle.obliques);
    expect(targetMuscle('abdominals', 'Plank'), Muscle.abs);
    expect(targetMuscle('hamstrings', 'Lying Leg Curls').area, BodyArea.legs);
    expect(EquipKind.of('Barbell, flat bench'), EquipKind.barbell);
    expect(EquipKind.of('No equipment'), EquipKind.bodyweight);
  });

  test('library cleanup: one word for no equipment, no stray capitals, fixed levels', () {
    expect(lib.moves.where((m) => m.equipment == 'No equipment'), isEmpty);
    expect(lib.byId['Overhead_Triceps']!.level, Level.beginner);
    expect(sentenceCase('Palms-Down Dumbbell Wrist Curl Over A Bench'), 'Palms-down dumbbell wrist curl over a bench');
    expect(sentenceCase('EZ-Bar Skullcrusher'), 'EZ-bar skullcrusher');
    expect(lib.byId['Farmers_Walk']!.equipment, 'Farmer handles or dumbbells');
    expect(EquipKind.of(lib.byId['Supine_Chest_Throw']!.equipment), EquipKind.ball);
    // "Other" is now rare kit only.
    expect(lib.moves.where((m) => m.equipment == 'Other').length, lessThan(15));
  });

  test('each muscle splits into groups; every move shows once and few are left over', () {
    for (final muscle in areaMuscles.values.expand((m) => m)) {
      final moves = lib.moves.where((m) => m.target == muscle).toList();
      final groups = groupMoves(muscle, moves);
      expect(groups.expand((g) => g.$2).length, moves.length, reason: muscle.label);
      final strength = moves.where((m) => m.kind == MoveKind.strength).length;
      final leftover = groups.where((g) => g.$1 == otherStrength).expand((g) => g.$2).length;
      expect(leftover, lessThanOrEqualTo((strength * 0.3).ceil()), reason: '${muscle.label}: $leftover of $strength');
    }
    final triceps = {for (final g in groupMoves(Muscle.triceps, lib.moves)) g.$1.label};
    expect(triceps, containsAll(['Long head', 'Lateral head', 'Heavy presses']));
    expect(groupOf(lib.byCatalogId['triceps-pushdown']!).label, 'Lateral head');
    expect(groupOf(lib.byCatalogId['skull-crusher']!).label, 'Long head');
    expect(groupOf(lib.byCatalogId['hammer-curl']!).label, 'Brachialis');
  });

  test('search understands gym shorthand and ranks the best moves first', () {
    final bi = lib.search('bi');
    expect(bi, isNotEmpty);
    expect(bi.take(10).every((m) => m.target == Muscle.biceps || m.searchText.contains('bicep')), isTrue);
    expect(bi.first.coached != null || lib.essentialIds.contains(bi.first.catalogId), isTrue);
    expect(lib.search('tris').first.target, Muscle.triceps);
    expect(lib.search('db curl').first.equipKind, EquipKind.dumbbell);
    expect(lib.search('rdl').map((m) => m.catalogId), contains('romanian-deadlift'));
    expect(lib.search('lats').every((m) => !m.name.toLowerCase().startsWith('lateral')), isTrue);
    expect(lib.search('long head').every((m) => m.target == Muscle.triceps || m.target == Muscle.biceps), isTrue);
    expect(lib.search('squat').first.coached, isNotNull);
  });

  test('swaps stay on the same muscle and lead with the same job on other equipment', () {
    final curl = lib.byCatalogId['barbell-curl']!;
    final swaps = swapsFor(lib, curl);
    expect(swaps, isNotEmpty);
    expect(swaps.every((m) => m.target == Muscle.biceps && m.kind == MoveKind.strength), isTrue);
    expect(swaps.map((m) => m.catalogId), isNot(contains('barbell-curl')));
    expect(groupOf(swaps.first), groupOf(curl));
    expect(swaps.first.equipKind, isNot(EquipKind.barbell));
    final pushdown = swapsFor(lib, lib.byCatalogId['triceps-pushdown']!);
    expect(groupOf(pushdown.first).label, 'Lateral head');
  });
}
