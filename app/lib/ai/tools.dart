import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import '../data/database.dart';
import '../data/meal_repository.dart';
import '../data/models.dart';
import '../data/program_repository.dart';
import '../data/settings_repository.dart';
import '../data/workout_repository.dart';
import '../domain/analytics.dart';
import '../domain/nutrition.dart';
import '../features/exercises/catalog/model.dart';
import '../features/exercises/library/library.dart';
import '../health/health_service.dart';
import 'contract.dart';
import 'proposals.dart';
import 'schema.dart';

/// Who is calling a tool. The name comes from the AI client and is shown
/// to the user as given; it is never used for access decisions.
class ToolCaller {
  const ToolCaller({required this.client, required this.via});
  final String client;

  /// 'wifi' or 'online'.
  final String via;
}

/// An MCP `CallToolResult`.
class ToolResult {
  const ToolResult(this.data, {this.isError = false});
  ToolResult.error(String message) : data = {'error': message}, isError = true;

  final Map<String, Object?> data;
  final bool isError;

  Map<String, Object?> toMcp() => {
    'content': [
      {'type': 'text', 'text': const JsonEncoder.withIndent(' ').convert(data)},
    ],
    'structuredContent': data,
    'isError': isError,
  };
}

/// Runs Reparc's MCP tools against the local database (handbook 10.4).
///
/// Every call checks the arguments and the user's data choices on this
/// phone. Read tools return only categories the user switched on. Plan tools
/// create proposals; they never change records.
class ReparcTools {
  ReparcTools({
    required this.contract,
    required this.db,
    required this.clock,
    required this.workouts,
    required this.meals,
    required this.proposals,
    required this.health,
    required this.settings,
    required this.library,
  });

  final ToolContract contract;
  final AppDatabase db;
  final Clock clock;
  final WorkoutRepository workouts;
  final MealRepository meals;
  final ProposalRepository proposals;
  final HealthSource health;
  final Future<AppSettings> Function() settings;
  final Future<ExerciseLibrary> Function() library;

  Future<ToolResult> call(String name, Object? arguments, ToolCaller caller) async {
    final spec = contract.tools[name];
    if (spec == null) return ToolResult.error('Unknown tool: ${name.length > 64 ? name.substring(0, 64) : name}');
    final args = arguments ?? <String, dynamic>{};
    final invalid = validateSchema((spec.json['inputSchema'] as Map).cast<String, dynamic>(), args);
    if (invalid != null) return ToolResult.error(invalid);
    final a = (args as Map).cast<String, dynamic>();
    final s = await settings();
    if (!s.aiAllows(spec.scope)) {
      return ToolResult.error(
        'The owner has not shared "${spec.scope}" data (${contract.scopes[spec.scope]}). '
        'Ask them to switch it on in Reparc → Me → AI connections.',
      );
    }
    try {
      return switch (name) {
        'get_overview' => await _overview(s),
        'list_workouts' => await _listWorkouts(a, s),
        'get_exercise_history' => await _exerciseHistory(a),
        'get_personal_records' => await _records(),
        'list_workout_plans' => await _plans(),
        'search_exercise_library' => await _searchLibrary(a),
        'list_meals' => await _listMeals(a),
        'get_nutrition_totals' => await _nutrition(a),
        'get_health_summary' => await _health(a, s),
        'propose_workout_plan' => await _proposePlans(a, caller),
        'propose_meal_plan' => await _proposeMeals(a, caller),
        'get_proposal_status' => await _proposalStatus(a),
        _ => ToolResult.error('Unknown tool'),
      };
    } on RangeProblem catch (e) {
      return ToolResult.error(e.message);
    } on ProposalLimit catch (e) {
      return ToolResult.error(e.toString());
    } catch (_) {
      // Never return internal details: they could include record content.
      return ToolResult.error('Reparc could not read this data on the phone. Try again.');
    }
  }

  DateTime get _today => dayOf(clock());

  (DateTime, DateTime) _range(Map<String, dynamic> a, {required int defaultDays, required int maxDays}) {
    final to = a['to'] is String ? _parse(a['to'] as String, 'to') : _today;
    final from = a['from'] is String ? _parse(a['from'] as String, 'from') : addDays(to, -(defaultDays - 1));
    if (from.isAfter(to)) throw const RangeProblem('from must be on or before to');
    if (to.difference(from).inDays + 1 > maxDays) throw RangeProblem('The range is longer than $maxDays days');
    return (from, to);
  }

  DateTime _parse(String key, String field) {
    final d = DateTime.tryParse(key);
    if (d == null || dayKey(d) != key) throw RangeProblem('$field is not a real date');
    return DateTime(d.year, d.month, d.day);
  }

  Map<String, Object?> _range2(DateTime from, DateTime to) => {'from': dayKey(from), 'to': dayKey(to)};

  // ---------------------------------------------------------------- Overview

  Future<ToolResult> _overview(AppSettings s) async {
    final now = clock();
    Future<int> count(TableInfo<Table, dynamic> t) async {
      final c = countAll();
      final row = await (db.selectOnly(t)..addColumns([c])).getSingle();
      return row.read(c) ?? 0;
    }

    final out = <String, Object?>{
      'today': dayKey(now),
      'time_zone': now.timeZoneName,
      'utc_offset_minutes': now.timeZoneOffset.inMinutes,
      'units': {'load': s.loadUnit, 'distance': s.distanceUnit, 'energy': 'kcal'},
      'shared': {for (final k in contract.scopes.keys) k: s.aiScopes.contains(k)},
      'scopes': contract.scopes,
    };
    if (s.aiAllows('gym')) {
      final last = await workouts.sessionSummaries();
      final saved = last.where((x) => !x.session.status.isLive).toList();
      out['gym'] = {
        'saved_workouts': saved.length,
        'plans': await count(db.programs),
        'latest_workout': saved.isEmpty
            ? null
            : {
                'name': saved.first.session.name,
                'date': dayKey(localDayOfInstant(saved.first.session.startedAt, saved.first.session.utcOffsetMinutes)),
                'exercises': saved.first.exerciseCount,
                'completed_sets': saved.first.completedSets,
              },
      };
    }
    if (s.aiAllows('meal')) {
      final today = await meals.entriesInRange(dayKey(now), dayKey(now));
      out['meal_today'] = _totalsJson(
        totalsOf(today.map((e) => e.input)),
        planned: today.where((e) => e.status == MealStatus.planned).length,
      );
    }
    if (s.aiAllows('health')) {
      out['health'] = {
        'source': health.platformName,
        'allowed_types': [
          for (final f in HealthFeature.values)
            if (!f.writes && s.health.contains(f.name)) f.label,
        ],
      };
    }
    out['pending_proposals'] = (await (db.select(
      db.aiProposals,
    )..where((p) => p.status.equalsValue(ProposalStatus.pending))).get()).length;
    return ToolResult(out);
  }

  // ------------------------------------------------------------------- Gym

  Map<String, Object?> _set(SetEntry x) => {
    'type': x.setType.name,
    'reps': x.reps,
    'load': x.load,
    'load_unit': x.loadUnit,
    'duration_s': x.durationSec,
    'distance': x.distance,
    'distance_unit': x.distanceUnit,
    'effort_rpe': x.effort,
    'completed': x.completed,
    if (x.note != null) 'note': x.note,
  };

  Future<ToolResult> _listWorkouts(Map<String, dynamic> a, AppSettings s) async {
    final (from, to) = _range(a, defaultDays: 28, maxDays: 92);
    final limit = (a['limit'] as int?) ?? 10;
    final all = await workouts.sessionSummaries(
      fromUtc: addDays(from, -1).toUtc(),
      toUtc: addDays(to, 2).toUtc(),
    );
    final inRange = all.where((x) {
      if (x.session.status.isLive) return false;
      final d = localDayOfInstant(x.session.startedAt, x.session.utcOffsetMinutes);
      return !d.isBefore(from) && !d.isAfter(to);
    }).toList()..sort((x, y) => y.session.startedAt.compareTo(x.session.startedAt));
    final list = <Map<String, Object?>>[];
    for (final x in inRange.take(limit)) {
      final d = await workouts.loadSession(x.session.id);
      if (d == null) continue;
      final ses = d.session;
      list.add({
        'id': ses.id,
        'name': ses.name,
        'date': dayKey(localDayOfInstant(ses.startedAt, ses.utcOffsetMinutes)),
        'started_at': ses.startedAt.toUtc().toIso8601String(),
        'ended_at': ses.endedAt?.toUtc().toIso8601String(),
        'status': ses.status.name,
        if (ses.note != null) 'note': ses.note,
        'exercises': [
          for (final e in d.exercises)
            {
              'name': e.exercise.name,
              if (e.exercise.variation != null) 'variation': e.exercise.variation,
              if (e.exercise.equipment != null) 'equipment': e.exercise.equipment,
              'skipped': e.item.skipped,
              'sets': [for (final x in e.sets) _set(x)],
            },
        ],
      });
    }
    return ToolResult({
      'range': _range2(from, to),
      'total_in_range': inRange.length,
      'returned': list.length,
      'workouts': list,
      'note': 'null means not recorded. Loads keep the unit they were logged in; the owner prefers ${s.loadUnit}.',
    });
  }

  Future<ToolResult> _exerciseHistory(Map<String, dynamic> a) async {
    final q = (a['exercise'] as String).trim().toLowerCase();
    final limit = (a['limit'] as int?) ?? 40;
    final all = await db.select(db.exercises).get();
    final exact = all.where((e) => e.name.toLowerCase() == q).toList();
    final matches = exact.isNotEmpty ? exact : all.where((e) => e.name.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) {
      return ToolResult({
        'exercise': a['exercise'],
        'matches': <Object>[],
        'note': 'No logged exercise has this name.',
      });
    }
    final out = <Map<String, Object?>>[];
    for (final e in matches.take(5)) {
      final sets = await workouts.completedSets(exerciseId: e.id);
      out.add({
        'name': e.name,
        if (e.variation != null) 'variation': e.variation,
        'completed_sets_total': sets.length,
        'sets': [
          for (final r in sets.take(limit))
            {
              'date': dayKey(localDayOfInstant(r.session.startedAt, r.session.utcOffsetMinutes)),
              'workout': r.session.name,
              ..._set(r.set),
            },
        ],
      });
    }
    return ToolResult({'exercise': a['exercise'], 'matches': out});
  }

  Future<ToolResult> _records() async {
    final records = heaviestLoads(await workouts.completedSets());
    return ToolResult({
      'rule': heaviestLoadRule,
      'records': [
        for (final r in records)
          {
            'exercise': r.source.exercise.name,
            'load': r.source.set.load,
            'load_unit': r.source.set.loadUnit,
            'reps': r.source.set.reps,
            'date': dayKey(localDayOfInstant(r.source.session.startedAt, r.source.session.utcOffsetMinutes)),
          },
      ],
    });
  }

  /// Every plan with its days. The followed plan is marked.
  Future<ToolResult> _plans() async {
    final list = await ProgramRepository(db, clock).all();
    return ToolResult({
      'plans': [
        for (final p in list)
          {
            'name': p.name,
            'followed': p.followed,
            'about': ?p.plan.about,
            'days': [
              for (final d in p.plan.days)
                {
                  'name': d.name,
                  if (d.focus.isNotEmpty) 'focus': d.focus,
                  'exercises': [
                    for (final i in d.work)
                      {
                        'name': i.name,
                        'sets': i.sets,
                        'reps_low': i.repsLow,
                        'reps_high': i.repsHigh,
                        'seconds': i.seconds,
                        'rest_sec': i.restSec,
                      },
                  ],
                },
            ],
          },
      ],
    });
  }

  Future<ToolResult> _searchLibrary(Map<String, dynamic> a) async {
    final lib = await library();
    final area = BodyArea.values.asNameMap()[a['body_area']];
    final equipment = (a['equipment'] as String?)?.toLowerCase();
    final limit = (a['limit'] as int?) ?? 15;
    // Same matching and order as the app's search: name matches first, then
    // coached guides and hand-picked moves, then shorter names.
    final hits = lib.search(
      (a['query'] as String?) ?? '',
      within: lib.moves.where(
        (m) => (area == null || m.area == area) && (equipment == null || m.equipment.toLowerCase().contains(equipment)),
      ),
    );
    return ToolResult({
      'total': hits.length,
      'results': [
        for (final m in hits.take(limit))
          {
            'library_id': m.catalogId,
            'name': m.name,
            'body_area': m.area.name,
            'equipment': m.equipment,
            'level': m.level.name,
            'muscles': m.muscles,
            'coached_guide': m.coached != null,
          },
      ],
    });
  }

  // ------------------------------------------------------------------ Meal

  Future<ToolResult> _listMeals(Map<String, dynamic> a) async {
    final from = a['from'] is String ? _parse(a['from'] as String, 'from') : _today;
    final to = a['to'] is String ? _parse(a['to'] as String, 'to') : from;
    if (from.isAfter(to)) throw const RangeProblem('from must be on or before to');
    if (to.difference(from).inDays + 1 > 31) throw const RangeProblem('The range is longer than 31 days');
    final slots = {for (final s in await meals.allSlots()) s.id: s.name};
    final entries = await meals.entriesInRange(dayKey(from), dayKey(to));
    final days = <String, List<Map<String, Object?>>>{};
    for (final e in entries) {
      (days[e.day] ??= []).add({
        'slot': slots[e.slotId] ?? 'Other',
        'name': e.name,
        if (e.brand != null) 'brand': e.brand,
        'status': e.status.name,
        'amount': e.amount,
        'amount_unit': e.amountUnit,
        'per_serving': {
          'serving_amount': e.servingAmount,
          'serving_unit': e.servingUnit,
          'energy_kcal': e.energyKcal,
          'protein_g': e.proteinG,
          'carbs_g': e.carbsG,
          'fat_g': e.fatG,
        },
        'is_estimate': e.isEstimate,
        'source': e.source,
        if (e.note != null) 'note': e.note,
      });
    }
    return ToolResult({
      'range': _range2(from, to),
      'days': [
        for (final d in days.keys) {'date': d, 'entries': days[d]},
      ],
      'note': 'Nutrient values are per source serving. amount is what was eaten or planned. null means not recorded.',
    });
  }

  Map<String, Object?> _nutrient(NutrientTotal t) => {
    'value': t.value == null ? null : double.parse(t.value!.toStringAsFixed(1)),
    'entries_without_value': t.missing,
  };

  Map<String, Object?> _totalsJson(NutritionTotals t, {int? planned}) => {
    'eaten_entries': t.entries,
    'planned_entries': ?planned,
    'estimates': t.estimates,
    'energy_kcal': _nutrient(t.energyKcal),
    'protein_g': _nutrient(t.proteinG),
    'carbs_g': _nutrient(t.carbsG),
    'fat_g': _nutrient(t.fatG),
  };

  Future<ToolResult> _nutrition(Map<String, dynamic> a) async {
    final (from, to) = _range(a, defaultDays: 7, maxDays: 92);
    final entries = await meals.entriesInRange(dayKey(from), dayKey(to));
    final byDay = <String, List<MealEntry>>{};
    for (final e in entries) {
      (byDay[e.day] ??= []).add(e);
    }
    NutritionInput asEaten(MealEntry e) {
      final i = e.input;
      return NutritionInput(
        servingAmount: i.servingAmount,
        servingUnit: i.servingUnit,
        amount: i.amount,
        amountUnit: i.amountUnit,
        energyKcal: i.energyKcal,
        proteinG: i.proteinG,
        carbsG: i.carbsG,
        fatG: i.fatG,
        isEstimate: i.isEstimate,
        status: MealStatus.eaten,
      );
    }

    return ToolResult({
      'range': _range2(from, to),
      'rule': 'eaten counts entries marked as eaten. planned counts planned entries as if eaten. Values are scaled to the amount.',
      'days': [
        for (var d = from; !d.isAfter(to); d = addDays(d, 1))
          {
            'date': dayKey(d),
            'eaten': _totalsJson(totalsOf((byDay[dayKey(d)] ?? const []).map((e) => e.input))),
            'planned': _totalsJson(
              totalsOf((byDay[dayKey(d)] ?? const []).where((e) => e.status == MealStatus.planned).map(asEaten)),
            ),
          },
      ],
    });
  }

  // ---------------------------------------------------------------- Health

  Future<ToolResult> _health(Map<String, dynamic> a, AppSettings s) async {
    final (from, to) = _range(a, defaultDays: 7, maxDays: 31);
    final on = {
      for (final f in HealthFeature.values)
        if (!f.writes && s.health.contains(f.name)) f,
    };
    if (on.isEmpty) {
      return ToolResult({
        'source': health.platformName,
        'note': 'The owner has not connected any health data type in Reparc → Me → Health apps.',
      });
    }
    final steps = on.contains(HealthFeature.steps) ? await health.dailySteps(from, to) : null;
    final energy = on.contains(HealthFeature.activeEnergy) ? await health.dailyActiveEnergy(from, to) : null;
    final weight = on.contains(HealthFeature.weight) ? await health.latestWeight(addDays(to, 1)) : null;
    return ToolResult({
      'source': health.platformName,
      'range': _range2(from, to),
      'types': [for (final f in on) f.label],
      'days': [
        for (var d = from; !d.isAfter(to); d = addDays(d, 1))
          {
            'date': dayKey(d),
            if (steps != null) 'steps': steps[dayKey(d)],
            if (energy != null) 'active_energy_kcal': energy[dayKey(d)]?.round(),
          },
      ],
      if (on.contains(HealthFeature.weight))
        'latest_weight': weight == null
            ? null
            : {
                'kg': double.parse(weight.kg.toStringAsFixed(1)),
                'measured_at': weight.at.toUtc().toIso8601String(),
                'source_app': weight.source,
              },
      'note': 'A missing day means no data was found. It does not mean zero, and it does not prove access was denied.',
    });
  }

  // ------------------------------------------------------------- Proposals

  Future<ToolResult> _proposePlans(Map<String, dynamic> a, ToolCaller caller) async {
    final id = await proposals.create(
      kind: ProposalKind.workoutPlan,
      client: caller.client,
      via: caller.via,
      summary: (a['summary'] as String).trim(),
      payload: {'plans': a['plans']},
    );
    return ToolResult({
      'proposal_id': id,
      'status': 'pending',
      'message': 'Sent to the owner\'s phone. Nothing is saved until they approve it in Reparc.',
    });
  }

  Future<ToolResult> _proposeMeals(Map<String, dynamic> a, ToolCaller caller) async {
    final today = _today;
    for (final m in (a['meals'] as List).cast<Map<String, dynamic>>()) {
      final d = _parse(m['date'] as String, 'meals.date');
      if (d.isBefore(addDays(today, -1)) || d.isAfter(addDays(today, 14))) {
        throw const RangeProblem('Meal dates must be from yesterday to 14 days ahead');
      }
    }
    final id = await proposals.create(
      kind: ProposalKind.mealPlan,
      client: caller.client,
      via: caller.via,
      summary: (a['summary'] as String).trim(),
      payload: {'meals': a['meals']},
    );
    return ToolResult({
      'proposal_id': id,
      'status': 'pending',
      'message': 'Sent to the owner\'s phone. Nothing is saved until they approve it in Reparc.',
    });
  }

  Future<ToolResult> _proposalStatus(Map<String, dynamic> a) async {
    final p = await proposals.find(a['proposal_id'] as String);
    if (p == null) return ToolResult.error('No proposal has this ID.');
    return ToolResult({
      'proposal_id': p.id,
      'status': p.status.name,
      'decided_at': p.decidedAt?.toUtc().toIso8601String(),
    });
  }
}

class RangeProblem implements Exception {
  const RangeProblem(this.message);
  final String message;
}
