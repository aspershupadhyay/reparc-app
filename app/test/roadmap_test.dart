import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/domain/roadmap.dart';
import 'package:reparc/features/exercises/catalog/catalog.dart';

void main() {
  final lib = {
    for (final e in (jsonDecode(File('assets/exercises/library.json').readAsStringSync())['exercises'] as List))
      'lib:${e['id']}',
  };
  bool known(String id) => id.startsWith('lib:') ? lib.contains(id) : catalogById.containsKey(id);

  test('every exercise a roadmap can use exists in the app', () {
    for (final row in [...patterns.values, ...skillLadders.values]) {
      for (final (id, _) in [row.$1, row.$2, row.$3]) {
        expect(known(id), isTrue, reason: '$id is missing');
      }
    }
  });

  for (final goal in RoadmapGoal.values) {
    for (final level in RoadmapLevel.values) {
      for (final setup in GymSetup.values) {
        for (final days in goal.dayOptions) {
          test('${goal.name} ${level.name} ${setup.name} $days days', () {
            final p = buildProgram(goal: goal, level: level, setup: setup, days: days);
            expect(p.days, hasLength(days));
            expect(p.weekdays, hasLength(days));
            for (final d in p.days) {
              expect(d.warmup, isNotEmpty, reason: 'Every day starts with a warm-up');
              expect(d.items.first.kind, ItemKind.warmup);
              expect(d.work, isNotEmpty);
              for (final i in d.items) {
                expect(known(i.exerciseId), isTrue, reason: '${i.exerciseId} on ${d.name}');
                expect(i.sets, greaterThan(0));
                if (i.repsLow != null && i.repsHigh != null) expect(i.repsLow!, lessThanOrEqualTo(i.repsHigh!));
              }
              // Sessions stay a sensible length.
              expect(d.workSets, inInclusiveRange(4, 30), reason: d.name);
            }
            // The plan survives a save and load unchanged.
            expect(ProgramPlan.decode(p.encode()).encode(), p.encode());
          });
        }
      }
    }
  }

  test('beginners get fewer sets and more reps in reserve than advanced lifters', () {
    final b = buildProgram(
      goal: RoadmapGoal.bodybuilding,
      level: RoadmapLevel.beginner,
      setup: GymSetup.fullGym,
      days: 4,
    );
    final a = buildProgram(
      goal: RoadmapGoal.bodybuilding,
      level: RoadmapLevel.advanced,
      setup: GymSetup.fullGym,
      days: 4,
    );
    int sets(ProgramPlan p) => p.days.fold(0, (s, d) => s + d.workSets);
    expect(sets(b), lessThan(sets(a)));
    expect(b.days.first.work.first.rir, greaterThan(a.days.first.work.first.rir!));
  });

  test('home setup never asks for a barbell or machine', () {
    final p = buildProgram(
      goal: RoadmapGoal.aesthetic,
      level: RoadmapLevel.intermediate,
      setup: GymSetup.home,
      days: 4,
    );
    final ids = [
      for (final d in p.days)
        for (final i in d.items) i.exerciseId,
    ];
    for (final banned in [
      'back-squat',
      'bench-press',
      'deadlift',
      'lat-pulldown',
      'leg-extension',
      'triceps-pushdown',
    ]) {
      expect(ids, isNot(contains(banned)));
    }
  });

  test('a balanced week trains each muscle group about twice', () {
    final p = buildProgram(
      goal: RoadmapGoal.bodybuilding,
      level: RoadmapLevel.intermediate,
      setup: GymSetup.fullGym,
      days: 4,
    );
    final w = weeklySetsByPattern(p);
    expect(w['hPress']! + w['inclinePress']!, greaterThanOrEqualTo(6));
    expect((w['vPull'] ?? 0) + (w['pullUp'] ?? 0) + w['hPull']! + w['cableRow']!, greaterThanOrEqualTo(9));
  });

  test('alternatives cover every setup and ladder step', () {
    final item = buildProgram(
      goal: RoadmapGoal.calisthenics,
      level: RoadmapLevel.beginner,
      setup: GymSetup.home,
      days: 3,
    ).days.first.work.first;
    expect(alternativesFor(item).length, greaterThanOrEqualTo(2));
    expect(rampUpSets(RoadmapLevel.beginner), hasLength(2));
  });
}
