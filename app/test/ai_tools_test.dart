import 'dart:io';

import 'package:drift/drift.dart' show Value;

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/ai/contract.dart';
import 'package:reparc/ai/proposals.dart';
import 'package:reparc/ai/rpc.dart';
import 'package:reparc/ai/schema.dart';
import 'package:reparc/ai/tools.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/features/exercises/library/library.dart';

import 'fake_health.dart';
import 'helpers.dart';

/// Shared setup for AI tool tests. Synthetic records only.
class AiFixture {
  AiFixture() {
    db = memoryDb();
    clock = FakeClock(DateTime(2026, 3, 10, 9));
    workouts = WorkoutRepository(db, clock.call);
    meals = MealRepository(db, clock.call);
    settings = SettingsRepository(db);
    proposals = ProposalRepository(db, clock.call, workouts, meals, () async => library);
    tools = ReparcTools(
      contract: contract,
      db: db,
      clock: clock.call,
      workouts: workouts,
      meals: meals,
      proposals: proposals,
      health: health,
      settings: () => settings.watch().first,
      library: () async => library,
    );
  }

  static final contract = ToolContract.parse(File('assets/mcp/tools.json').readAsStringSync());
  static final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());

  late final AppDatabase db;
  late final FakeClock clock;
  late final WorkoutRepository workouts;
  late final MealRepository meals;
  late final SettingsRepository settings;
  late final ProposalRepository proposals;
  late final ReparcTools tools;
  final health = FakeHealth();

  static const caller = ToolCaller(client: 'Test AI', via: 'wifi');

  Future<ToolResult> call(String name, [Map<String, Object?> args = const {}]) => tools.call(name, args, caller);

  Future<void> share(List<String> scopes) async {
    for (final s in scopes) {
      await settings.setAiScope(s, true);
    }
  }
}

void main() {
  late AiFixture f;
  setUp(() => f = AiFixture());
  tearDown(() => f.db.close());

  test('the contract ships in the app bundle', () async {
    // The phone reads it through rootBundle, so pubspec.yaml must list it.
    TestWidgetsFlutterBinding.ensureInitialized();
    final bundled = ToolContract.parse(await rootBundle.loadString('assets/mcp/tools.json'));
    expect(bundled.tools.length, AiFixture.contract.tools.length);
  });

  test('the contract lists twelve tools with known scopes', () {
    expect(AiFixture.contract.tools, hasLength(12));
    for (final t in AiFixture.contract.tools.values) {
      expect(t.scope == null || aiScopeNames.contains(t.scope), isTrue, reason: t.name);
      expect(t.json['inputSchema'], isA<Map<String, dynamic>>());
    }
    expect(AiFixture.contract.listed.first.containsKey('scope'), isFalse);
  });

  test('every data category starts off and read tools refuse until shared', () async {
    final overview = await f.call('get_overview');
    expect(overview.isError, isFalse);
    expect(overview.data['shared'], {'gym': false, 'meal': false, 'health': false, 'plans': false});
    expect(overview.data.containsKey('gym'), isFalse);

    final denied = await f.call('list_workouts');
    expect(denied.isError, isTrue);
    expect(denied.data['error'], contains('Me → AI connections'));

    final plans = await f.call('propose_workout_plan', {
      'summary': 'x',
      'plans': [
        {
          'name': 'A',
          'exercises': [
            {'name': 'Squat'},
          ],
        },
      ],
    });
    expect(plans.isError, isTrue);
    expect(await f.db.select(f.db.aiProposals).get(), isEmpty);
  });

  test('arguments are validated against the schema on the phone', () async {
    await f.share(['gym', 'meal']);
    expect((await f.call('list_workouts', {'from': '2026-13-01'})).isError, isTrue);
    expect((await f.call('list_workouts', {'from': '2026-02-30'})).data['error'], contains('not a real date'));
    expect((await f.call('list_workouts', {'limit': 500})).data['error'], contains('at most 50'));
    expect((await f.call('list_workouts', {'evil': true})).data['error'], contains('not a known field'));
    expect((await f.call('list_meals', {'from': '2026-01-01', 'to': '2026-03-01'})).data['error'], contains('31 days'));
    expect(await f.tools.call('get_overview', [1, 2], AiFixture.caller).then((r) => r.isError), isTrue);
    expect(validateSchema({'type': 'string', 'maxLength': 5}, 'a\u0000b'), contains('control'));
  });

  test('list_workouts returns saved sets and keeps missing values as null', () async {
    await f.share(['gym']);
    final ex = await f.workouts.createExercise(name: 'Bench press');
    final s = await f.workouts.startSession();
    final se = await f.workouts.addSessionExercise(s, ex);
    final set = await f.workouts.addSet(se);
    await f.workouts.updateSet(set, const SetEntriesCompanion(reps: Value(5), load: Value(80), loadUnit: Value('kg')));
    await f.workouts.setCompleted(set, true);
    f.clock.advance(const Duration(minutes: 40));
    await f.workouts.end(s, finished: true);

    final r = await f.call('list_workouts');
    expect(r.isError, isFalse);
    final w = (r.data['workouts'] as List).single as Map;
    expect(w['date'], '2026-03-10');
    final sets = ((w['exercises'] as List).single as Map)['sets'] as List;
    expect((sets.single as Map)['load'], 80);
    expect((sets.single as Map)['load_unit'], 'kg');
    expect((sets.single as Map)['effort_rpe'], isNull);

    final records = await f.call('get_personal_records');
    expect(((records.data['records'] as List).single as Map)['load'], 80);
    final history = await f.call('get_exercise_history', {'exercise': 'bench'});
    expect((((history.data['matches'] as List).single as Map)['sets'] as List), hasLength(1));
  });

  test('library search finds coached guides first with usable IDs', () async {
    final r = await f.call('search_exercise_library', {'query': 'squat', 'body_area': 'legs', 'limit': 5});
    final results = r.data['results'] as List;
    expect(results, isNotEmpty);
    expect((results.first as Map)['coached_guide'], isTrue);
    expect(results.map((r) => (r as Map)['library_id']), contains('back-squat'));
    expect((results.first as Map)['name'].toString().toLowerCase(), contains('squat'));
  });

  test('a workout proposal changes nothing until the owner approves it', () async {
    await f.share(['plans', 'gym']);
    final r = await f.call('propose_workout_plan', {
      'summary': 'Two-day full body plan.',
      'plans': [
        {
          'name': 'Day A',
          'note': 'Rest 2 min between sets.',
          'exercises': [
            {'name': 'Back squat', 'library_id': 'back-squat', 'sets': 3, 'reps': 5},
            {'name': 'Barbell Squat', 'library_id': 'lib:Barbell_Squat', 'sets': 2, 'reps': 8},
            {'name': 'Made-up move', 'sets': 3, 'reps': 12},
          ],
        },
        {
          'name': 'Day B',
          'exercises': [
            {'name': 'Push-up'},
          ],
        },
      ],
    });
    expect(r.isError, isFalse);
    final id = r.data['proposal_id'] as String;
    expect(await f.db.select(f.db.workoutTemplates).get(), isEmpty);
    expect((await f.call('get_proposal_status', {'proposal_id': id})).data['status'], 'pending');

    final created = await f.proposals.approve(id);
    expect(created, hasLength(2));
    final a = await f.workouts.loadTemplate(created.first);
    expect(a!.template.name, 'Day A');
    expect(a.template.note, 'Rest 2 min between sets.');
    expect(a.items.map((i) => i.exercise.name), ['Back squat', 'Barbell Squat', 'Made-up move']);
    expect(a.items.first.exercise.catalogId, 'back-squat');
    expect(a.items[1].exercise.catalogId, 'lib:Barbell_Squat');
    expect(a.items.first.item.targetSets, 3);
    expect((await f.call('get_proposal_status', {'proposal_id': id})).data['status'], 'approved');
    await expectLater(f.proposals.approve(id), throwsStateError);
  });

  test('approved meal plans are planned estimates with the AI as source', () async {
    await f.share(['plans', 'meal']);
    final r = await f.call('propose_meal_plan', {
      'summary': 'High-protein day.',
      'meals': [
        {
          'date': '2026-03-11',
          'slot': 'breakfast',
          'name': 'Greek yogurt and oats',
          'energy_kcal': 420,
          'protein_g': 32,
        },
        {'date': '2026-03-11', 'slot': 'snacks', 'name': 'Apple', 'amount': 1, 'unit': 'piece'},
      ],
    });
    final id = r.data['proposal_id'] as String;
    expect(await f.meals.entriesInRange('2026-03-11', '2026-03-11'), isEmpty);
    await f.proposals.approve(id);
    final entries = await f.meals.entriesInRange('2026-03-11', '2026-03-11');
    expect(entries, hasLength(2));
    final yogurt = entries.firstWhere((e) => e.name.startsWith('Greek'));
    expect(yogurt.status, MealStatus.planned);
    expect(yogurt.isEstimate, isTrue);
    expect(yogurt.slotId, 'slot-breakfast');
    expect(yogurt.carbsG, isNull);
    expect(yogurt.source, aiMealSource('Test AI'));
    expect(entries.firstWhere((e) => e.name == 'Apple').slotId, 'slot-snacks');

    final totals = await f.call('get_nutrition_totals', {'from': '2026-03-11', 'to': '2026-03-11'});
    final day = (totals.data['days'] as List).single as Map;
    expect(((day['planned'] as Map)['energy_kcal'] as Map)['value'], 420.0);
    expect(((day['planned'] as Map)['energy_kcal'] as Map)['entries_without_value'], 1);
    expect(((day['eaten'] as Map)['energy_kcal'] as Map)['value'], isNull);
  });

  test('meal proposals outside the next two weeks are refused', () async {
    await f.share(['plans']);
    final r = await f.call('propose_meal_plan', {
      'summary': 'x',
      'meals': [
        {'date': '2026-05-01', 'slot': 'lunch', 'name': 'Rice'},
      ],
    });
    expect(r.isError, isTrue);
    expect(await f.db.select(f.db.aiProposals).get(), isEmpty);
  });

  test('a declined proposal saves nothing', () async {
    await f.share(['plans']);
    final r = await f.call('propose_workout_plan', {
      'summary': 'x',
      'plans': [
        {
          'name': 'A',
          'exercises': [
            {'name': 'Row'},
          ],
        },
      ],
    });
    await f.proposals.decline(r.data['proposal_id'] as String);
    expect(await f.db.select(f.db.workoutTemplates).get(), isEmpty);
    expect((await f.db.select(f.db.aiProposals).getSingle()).status, ProposalStatus.declined);
  });

  test('health summary uses only the types the owner switched on', () async {
    await f.share(['health']);
    f.health.steps = {'2026-03-09': 8000, '2026-03-10': 1200};
    f.health.energy = {'2026-03-10': 310.4};
    var r = await f.call('get_health_summary', {'from': '2026-03-09', 'to': '2026-03-10'});
    expect(r.data['note'], contains('not connected'));

    await f.settings.setHealth('steps', true);
    r = await f.call('get_health_summary', {'from': '2026-03-08', 'to': '2026-03-10'});
    final days = r.data['days'] as List;
    expect((days[0] as Map)['steps'], isNull);
    expect((days[1] as Map)['steps'], 8000);
    expect((days[2] as Map).containsKey('active_energy_kcal'), isFalse);
    expect(r.data.containsKey('latest_weight'), isFalse);
  });

  test('JSON-RPC: initialize, list, call, and errors', () async {
    final log = <ActivityEntry>[];
    final rpc = McpRpc(AiFixture.contract, f.tools, onActivity: log.add);
    final init = await rpc.handle({
      'jsonrpc': '2.0',
      'id': 1,
      'method': 'initialize',
      'params': {'protocolVersion': '2025-06-18'},
    }, caller: AiFixture.caller);
    expect((init!['result'] as Map)['protocolVersion'], '2025-06-18');
    expect(
      await rpc.handle({'jsonrpc': '2.0', 'method': 'notifications/initialized'}, caller: AiFixture.caller),
      isNull,
    );
    final list = await rpc.handle({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'}, caller: AiFixture.caller);
    expect(((list!['result'] as Map)['tools'] as List), hasLength(12));
    final call = await rpc.handle({
      'jsonrpc': '2.0',
      'id': 3,
      'method': 'tools/call',
      'params': {'name': 'get_overview'},
    }, caller: AiFixture.caller);
    expect(((call!['result'] as Map)['isError']), isFalse);
    expect(log.single.tool, 'get_overview');
    final bad = await rpc.handle({
      'jsonrpc': '2.0',
      'id': 4,
      'method': 'tools/call',
      'params': {'name': 'drop_tables'},
    }, caller: AiFixture.caller);
    expect((bad!['error'] as Map)['code'], -32602);
    expect(cleanClientName('Claude\u0000 Desktop'), 'Claude Desktop');
    expect(cleanClientName(''), 'An AI app');
  });
}
