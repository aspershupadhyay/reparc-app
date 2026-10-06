import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/data_controls.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/roadmap.dart';
import 'package:reparc/domain/targets.dart';
import 'package:reparc/mcp/mcp_server.dart';
import 'package:reparc/mcp/reparc_tools.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late FakeClock clock;

  setUp(() async {
    db = memoryDb();
    clock = FakeClock(DateTime.utc(2026, 3, 2, 18));
    final w = WorkoutRepository(db, clock.call);
    final m = MealRepository(db, clock.call);
    await SettingsRepository(db).setProfile(
      const Profile(
        sex: Sex.male,
        ageYears: 30,
        heightCm: 180,
        weightKg: 80,
        activity: Activity.moderate,
        goal: BodyGoal.maintain,
      ),
    );
    await SettingsRepository(db).setTargetsOn(true);
    final bench = await w.createExercise(name: 'Bench press');
    final id = await w.startSession();
    final se = await w.addSessionExercise(id, bench);
    for (final (load, unit, reps, type) in [
      (40.0, 'kg', 8, SetType.warmup),
      (100.0, 'kg', 5, SetType.working),
      (225.0, 'lb', 5, SetType.working),
    ]) {
      final s = await w.addSet(se, type: type);
      await w.updateSet(s, SetEntriesCompanion(load: Value(load), loadUnit: Value(unit), reps: Value(reps)));
      await w.setCompleted(s, true);
    }
    await w.end(id, finished: true);
    await m.addEntry(
      day: '2026-03-02',
      slotId: 'slot-lunch',
      food: const FoodValues(name: 'Lentils', servingAmount: 100, servingUnit: 'g', proteinG: 9, fiberG: 7.9),
      amount: 200,
      amountUnit: 'g',
      status: MealStatus.eaten,
    );
    await ProgramRepository(db, clock.call).adopt(
      buildProgram(goal: RoadmapGoal.strength, level: RoadmapLevel.beginner, setup: GymSetup.fullGym, days: 2),
    );
  });
  tearDown(() => db.close());

  Future<ReparcSnapshot> snap([Set<String> scopes = DataControls.allScopes]) async => ReparcSnapshot(
    (jsonDecode(await DataControls(db, clock.call).exportJson(appVersion: 't', scopes: scopes)) as Map)
        .cast<String, Object?>(),
  );

  test('tools read the export with correct numbers', () async {
    final s = await snap();
    final w = callTool(s, 'get_workout_summary', {'from': '2026-03-01', 'to': '2026-03-07'});
    expect(w['workouts'], 1);
    expect(w['workingSets'], 2);
    expect(w['warmupSets'], 1);
    expect(w['volumeKg'], closeTo(500 + 225 * 0.45359237 * 5, 0.01));

    final meal = callTool(s, 'get_meal_totals', {'from': '2026-03-01', 'to': '2026-03-07'});
    final day = (meal['days'] as List).single as Map;
    expect(day['proteinG'], 18);
    expect(day['fiberG'], 15.8);
    expect(day['energyKcal'], isNull, reason: 'No kcal value was recorded; it must not become 0');

    final prof = callTool(s, 'get_profile_and_targets', {});
    final targets = {for (final t in prof['targets'] as List) (t as Map)['nutrient']: t['amount']};
    expect(targets['protein'], 130);

    final pr = callTool(s, 'list_personal_records', {});
    expect((pr['heaviestCompletedLoad'] as List).length, 2, reason: 'kg and lb stay apart');

    final hist = callTool(s, 'get_exercise_history', {'exercise': 'bench press'});
    expect((hist['sets'] as List).length, 3);

    final road = callTool(s, 'get_roadmap', {});
    expect((road['roadmap'] as Map)['goal'], 'strength');
  });

  test('scopes the user left out are not offered and cannot be read', () async {
    final s = await snap({'workout'});
    final names = toolsFor(s).map((t) => t.name).toSet();
    expect(names, contains('get_workout_summary'));
    expect(names, isNot(contains('get_meal_totals')));
    expect(names, isNot(contains('get_profile_and_targets')));
    expect(() => callTool(s, 'get_meal_totals', {}), throwsArgumentError);
    expect(s.table('mealEntries'), isEmpty);
    expect(s.settings.keys.where((k) => k.startsWith('profile.')), isEmpty);
  });

  test('proposals are checked, never saved', () async {
    final s = await snap();
    final bad = callTool(s, 'check_roadmap_proposal', {
      'plan': {'kind': 'reparc-roadmap', 'days': []},
    });
    expect(bad['ok'], isFalse);
    final example = (importFormats['roadmap']! as Map)['example'];
    final good = callTool(s, 'check_roadmap_proposal', {'plan': example});
    expect(good['ok'], isTrue, reason: '${good['problems']}');
    final meal = callTool(s, 'check_meal_plan_proposal', {'plan': (importFormats['mealPlan']! as Map)['example']});
    expect(meal['ok'], isTrue);
    expect((meal['totals'] as Map)['protein'], 6.6);
    expect(
      mealPlanProblems({
        'kind': 'reparc-meal-plan',
        'meals': [
          {
            'slot': 'lunch',
            'foods': [
              {
                'name': 'X',
                'grams': 100,
                'per100g': {'protein': 60, 'carbs': 50, 'fat': 10},
              },
            ],
          },
        ],
      }),
      isNotEmpty,
    );
    expect(await db.select(db.mealEntries).get(), hasLength(1));
  });

  test('MCP server answers initialize, tools/list, and tools/call', () async {
    final server = McpServer(await snap());
    final init = server.handle({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {
        'protocolVersion': '2025-06-18',
        'capabilities': {},
        'clientInfo': {'name': 't', 'version': '1'},
      },
    })!;
    expect((init['result'] as Map)['protocolVersion'], '2025-06-18');
    expect(server.handle({'jsonrpc': '2.0', 'method': 'notifications/initialized'}), isNull);
    final list = server.handle({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'})!;
    expect(((list['result'] as Map)['tools'] as List).length, reparcTools.length);
    final call = server.handle({
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/call',
      'params': {
        'name': 'get_meal_log',
        'arguments': {'day': '2026-03-02'},
      },
    })!;
    final result = call['result'] as Map;
    expect(result['isError'], isFalse);
    expect(((result['structuredContent'] as Map)['foods'] as List).single['name'], 'Lentils');
    final err = server.handle({
      'jsonrpc': '2.0',
      'id': 4,
      'method': 'tools/call',
      'params': {
        'name': 'get_meal_log',
        'arguments': {'day': 'yesterday'},
      },
    })!;
    expect((err['result'] as Map)['isError'], isTrue);
    expect(server.handle({'jsonrpc': '2.0', 'id': 5, 'method': 'nope'})!['error'], isNotNull);
  });
}
