/// Reparc data tools for AI clients (MCP).
///
/// These tools read a Reparc export file: the JSON the user creates in
/// Me → AI connections (or Me → Export). They never change records. Tools
/// that "propose" a roadmap or meal plan only check an AI's plan against
/// the import format, so the user can review it and import it in the app.
///
/// Pure Dart: no Flutter, no network. The same code runs in the app tests
/// and in the local MCP server (tool/mcp/server.dart).
library;

import '../core/dates.dart';
import '../data/models.dart';
import '../domain/nutrition.dart';
import '../domain/roadmap.dart';
import '../domain/strength.dart';
import '../domain/targets.dart';

const _kgPerLb = 0.45359237;

/// One export file, read once.
class ReparcSnapshot {
  ReparcSnapshot(Map<String, Object?> export)
    : exportedAt = export['exportedAt'] as String?,
      scopes = [
        for (final s in (export['scopes'] as List? ?? const ['workout', 'meal', 'body'])) s as String,
      ],
      _t = (export['tables'] as Map? ?? const {}).cast<String, Object?>() {
    if (export['format'] != 'reparc-export') throw const FormatException('Not a Reparc export file.');
  }

  final String? exportedAt;

  /// Data the user chose to include: workout, meal, body.
  final List<String> scopes;
  final Map<String, Object?> _t;

  List<Map<String, Object?>> table(String name) => [
    for (final r in (_t[name] as List? ?? const [])) (r as Map).cast<String, Object?>(),
  ];

  bool has(String scope) => scopes.contains(scope);

  Map<String, String> get settings => {
    for (final r in table('settings')) r['key'] as String: r['value'] as String,
  };

  Profile get profile => Profile.fromMap({
    for (final e in settings.entries)
      if (e.key.startsWith('profile.')) e.key.substring(8): e.value,
  });
}

/// A tool an AI client can call.
class ReparcTool {
  const ReparcTool(this.name, this.description, this.inputSchema, this.scope);
  final String name;
  final String description;
  final Map<String, Object?> inputSchema;

  /// Data scope the tool needs, or null for none.
  final String? scope;

  Map<String, Object?> toJson() => {'name': name, 'description': description, 'inputSchema': inputSchema};
}

const _range = {
  'type': 'object',
  'properties': {
    'from': {'type': 'string', 'description': 'First day, yyyy-MM-dd (local). Default: 30 days before to.'},
    'to': {'type': 'string', 'description': 'Last day, yyyy-MM-dd (local). Default: the export day.'},
  },
};

const reparcTools = <ReparcTool>[
  ReparcTool(
    'get_profile_and_targets',
    'The user\'s profile (sex, age, height, weight, activity, goal, diet) and the daily nutrition targets '
        'Reparc calculates from it, each with its rule and source. Missing fields are null.',
    {'type': 'object', 'properties': {}},
    'body',
  ),
  ReparcTool(
    'get_workout_summary',
    'Workouts in a date range: sessions, training days, working sets (warm-ups excluded), reps, volume in kg '
        '(pounds converted exactly), active time, and sets per exercise.',
    _range,
    'workout',
  ),
  ReparcTool(
    'get_exercise_history',
    'Every completed set of one exercise (match by name, case-insensitive, or catalog ID), with date, load, '
        'unit, reps, set type, and an estimated one-rep max for sets of 1–10 reps.',
    {
      'type': 'object',
      'properties': {
        'exercise': {'type': 'string', 'description': 'Exercise name or catalog ID, for example "Bench press".'},
      },
      'required': ['exercise'],
    },
    'workout',
  ),
  ReparcTool(
    'list_personal_records',
    'Personal records with named rules: heaviest completed load, and best estimated one-rep max. Units are '
        'never mixed. Each record names its source session and date.',
    {'type': 'object', 'properties': {}},
    'workout',
  ),
  ReparcTool(
    'get_roadmap',
    'The training roadmap the user follows now: goal, level, equipment, weekdays, and every day with warm-up, '
        'exercises, sets, reps, rest, and reps in reserve. Null when none is active.',
    {'type': 'object', 'properties': {}},
    'workout',
  ),
  ReparcTool(
    'get_meal_totals',
    'Eaten food per day in a range: energy (kcal), protein, carbs, fibre, fat, sugar (g), and sodium (mg). A '
        'nutrient with no value stays null, never zero. Includes averages over days with values and days on '
        'target when the user has targets.',
    _range,
    'meal',
  ),
  ReparcTool(
    'get_meal_log',
    'Every planned and eaten food on one day, with meal slot, amount, unit, values for the amount, source, '
        'and whether values are estimates.',
    {
      'type': 'object',
      'properties': {
        'day': {'type': 'string', 'description': 'Day, yyyy-MM-dd (local).'},
      },
      'required': ['day'],
    },
    'meal',
  ),
  ReparcTool(
    'get_body_weight',
    'Body weight check-ins in a range, in the unit typed, with the value in kg.',
    _range,
    'body',
  ),
  ReparcTool(
    'get_import_formats',
    'The JSON formats Reparc can import: a roadmap and a day meal plan. Use them to write a plan the user can '
        'paste into Me → AI connections → Import a plan. Reparc shows a preview and asks before saving.',
    {'type': 'object', 'properties': {}},
    null,
  ),
  ReparcTool(
    'check_roadmap_proposal',
    'Checks a roadmap written in the Reparc import format and returns problems, if any. It does not save '
        'anything.',
    {
      'type': 'object',
      'properties': {
        'plan': {'type': 'object', 'description': 'A roadmap in the format from get_import_formats.'},
      },
      'required': ['plan'],
    },
    null,
  ),
  ReparcTool(
    'check_meal_plan_proposal',
    'Checks a day meal plan written in the Reparc import format, adds up its nutrients, and compares them '
        'with the user\'s targets. It does not save anything.',
    {
      'type': 'object',
      'properties': {
        'plan': {'type': 'object', 'description': 'A meal plan in the format from get_import_formats.'},
      },
      'required': ['plan'],
    },
    null,
  ),
];

/// Tools the snapshot allows. A tool whose data scope the user left out of
/// the export is not offered.
List<ReparcTool> toolsFor(ReparcSnapshot s) => [
  for (final t in reparcTools)
    if (t.scope == null || s.has(t.scope!)) t,
];

/// Runs one tool. Throws [ArgumentError] on bad input.
Map<String, Object?> callTool(ReparcSnapshot s, String name, Map<String, Object?> args) {
  final tool = reparcTools.where((t) => t.name == name).firstOrNull;
  if (tool == null) throw ArgumentError('Unknown tool: $name');
  if (tool.scope != null && !s.has(tool.scope!)) {
    throw ArgumentError('The user did not share ${tool.scope} data in this export.');
  }
  return switch (name) {
    'get_profile_and_targets' => _profile(s),
    'get_workout_summary' => _workoutSummary(s, _rangeOf(s, args)),
    'get_exercise_history' => _exerciseHistory(s, args['exercise'] as String? ?? ''),
    'list_personal_records' => _records(s),
    'get_roadmap' => _roadmap(s),
    'get_meal_totals' => _mealTotals(s, _rangeOf(s, args)),
    'get_meal_log' => _mealLog(s, args['day'] as String? ?? ''),
    'get_body_weight' => _weights(s, _rangeOf(s, args)),
    'get_import_formats' => importFormats,
    'check_roadmap_proposal' => checkRoadmap(args['plan']),
    'check_meal_plan_proposal' => checkMealPlan(s, args['plan']),
    _ => throw ArgumentError('Unknown tool: $name'),
  };
}

(DateTime, DateTime) _rangeOf(ReparcSnapshot s, Map<String, Object?> args) {
  DateTime parse(Object? v, String field) {
    try {
      return parseDayKey(v as String);
    } catch (_) {
      throw ArgumentError('$field must be a day like 2026-03-02.');
    }
  }

  final exported = s.exportedAt == null ? DateTime.now() : DateTime.parse(s.exportedAt!).toLocal();
  final to = args['to'] == null ? dayOf(exported) : parse(args['to'], 'to');
  final from = args['from'] == null ? addDays(to, -29) : parse(args['from'], 'from');
  if (from.isAfter(to)) throw ArgumentError('from must be on or before to.');
  if (to.difference(from).inDays > 366) throw ArgumentError('Ask for one year or less at a time.');
  return (from, to);
}

String _day(DateTime d) => dayKey(d);

// ------------------------------------------------------------------ Profile

Map<String, Object?> _profile(ReparcSnapshot s) {
  final p = s.profile;
  final on = s.settings['targetsOn'] == 'true';
  return {
    'profile': {
      'sex': p.sex?.name,
      'ageYears': p.ageYears,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'activity': p.activity?.name,
      'goal': p.goal?.name,
      'diet': p.diet?.name,
      'proteinPerKg': proteinRatio(p),
    },
    'targetsShownInApp': on,
    'targets': [
      for (final t in dailyTargets(p))
        {
          'nutrient': t.nutrient.name,
          'amount': t.amount,
          'unit': t.nutrient.unit,
          'kind': t.isLimit ? 'stay under' : 'reach',
          'rule': t.rule,
          'source': t.source,
        },
    ],
    'units': {'load': s.settings['loadUnit'] ?? 'kg'},
    'note': 'General guidance for healthy adults, not medical advice.',
  };
}

// ------------------------------------------------------------------ Workout

class _Set {
  _Set(this.set, this.exercise, this.session);
  final Map<String, Object?> set;
  final Map<String, Object?> exercise;
  final Map<String, Object?> session;

  DateTime get day {
    final at = DateTime.parse(session['startedAt'] as String).toUtc();
    final off = (session['utcOffsetMinutes'] as num?)?.toInt() ?? 0;
    return dayOf(at.add(Duration(minutes: off)));
  }

  double? get load => (set['load'] as num?)?.toDouble();
  int? get reps => (set['reps'] as num?)?.toInt();
  String? get unit => set['loadUnit'] as String?;
  bool get warmup => set['setType'] == 'warmup';
  double? get loadKg => load == null || unit == null ? null : (unit == 'lb' ? load! * _kgPerLb : load!);
  double? get estimate => load == null || reps == null || reps! > 10 || warmup ? null : estimateOneRepMax(load!, reps!);
}

List<_Set> _completedSets(ReparcSnapshot s) {
  final sessions = {for (final r in s.table('workoutSessions')) r['id']: r};
  final items = {for (final r in s.table('sessionExercises')) r['id']: r};
  final exercises = {for (final r in s.table('exercises')) r['id']: r};
  final out = <_Set>[];
  for (final set in s.table('setEntries')) {
    if (set['completed'] != true) continue;
    final item = items[set['sessionExerciseId']];
    if (item == null) continue;
    final session = sessions[item['sessionId']];
    final ex = exercises[item['exerciseId']];
    if (session == null || ex == null) continue;
    if (session['status'] == 'active' || session['status'] == 'paused') continue;
    out.add(_Set(set, ex, session));
  }
  return out;
}

bool _inRange(DateTime d, (DateTime, DateTime) r) => !d.isBefore(r.$1) && !d.isAfter(r.$2);

Map<String, Object?> _workoutSummary(ReparcSnapshot s, (DateTime, DateTime) r) {
  final sets = _completedSets(s).where((x) => _inRange(x.day, r)).toList();
  final working = sets.where((x) => !x.warmup).toList();
  final sessions = [
    for (final ses in s.table('workoutSessions'))
      if (ses['status'] == 'finished' || ses['status'] == 'incomplete')
        if (_Set(const {}, const {}, ses).day case final d when _inRange(d, r)) ses,
  ];
  var volume = 0.0, skipped = 0;
  for (final x in working) {
    final kg = x.loadKg;
    if (kg == null || x.reps == null) {
      skipped++;
    } else {
      volume += kg * x.reps!;
    }
  }
  final byExercise = <String, int>{};
  for (final x in working) {
    final n = x.exercise['name'] as String;
    byExercise[n] = (byExercise[n] ?? 0) + 1;
  }
  int? activeMinutes(Map<String, Object?> ses) {
    final end = ses['endedAt'] as String?;
    if (end == null) return null;
    final d =
        DateTime.parse(end).difference(DateTime.parse(ses['startedAt'] as String)) -
        Duration(milliseconds: (ses['pausedMs'] as num?)?.toInt() ?? 0);
    return d.isNegative ? 0 : d.inMinutes;
  }

  return {
    'from': _day(r.$1),
    'to': _day(r.$2),
    'workouts': sessions.length,
    'trainingDays': {for (final ses in sessions) _day(_Set(const {}, const {}, ses).day)}.length,
    'workingSets': working.length,
    'warmupSets': sets.length - working.length,
    'reps': working.fold<int>(0, (a, x) => a + (x.reps ?? 0)),
    'setsWithoutReps': working.where((x) => x.reps == null).length,
    'volumeKg': double.parse(volume.toStringAsFixed(2)),
    'setsWithoutLoadOrReps': skipped,
    'setsPerExercise': byExercise,
    'sessions': [
      for (final ses in sessions)
        {
          'id': ses['id'],
          'name': ses['name'],
          'day': _day(_Set(const {}, const {}, ses).day),
          'status': ses['status'],
          'activeMinutes': activeMinutes(ses),
          'roadmapDay': ses['programDay'],
        },
    ],
  };
}

Map<String, Object?> _exerciseHistory(ReparcSnapshot s, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) throw ArgumentError('exercise is required.');
  final sets = _completedSets(s)
      .where((x) => (x.exercise['name'] as String).toLowerCase() == q || (x.exercise['catalogId'] as String?) == query)
      .toList();
  sets.sort((a, b) => (a.session['startedAt'] as String).compareTo(b.session['startedAt'] as String));
  return {
    'exercise': query,
    'matches': {for (final x in sets) x.exercise['name']}.toList(),
    'sets': [
      for (final x in sets)
        {
          'day': _day(x.day),
          'setType': x.set['setType'],
          'load': x.load,
          'unit': x.unit,
          'reps': x.reps,
          'durationSec': x.set['durationSec'],
          'estimatedOneRepMax': x.estimate == null ? null : double.parse(x.estimate!.toStringAsFixed(1)),
        },
    ],
    'estimateRule': 'Mean of Epley and Brzycki for sets of 1–10 reps. Warm-up sets are left out.',
  };
}

Map<String, Object?> _records(ReparcSnapshot s) {
  final heaviest = <String, _Set>{};
  final best = <String, (double, _Set)>{};
  for (final x in _completedSets(s)) {
    if (x.load == null || x.unit == null || x.load! <= 0) continue;
    final key = '${x.exercise['id']}|${x.unit}';
    final h = heaviest[key];
    if (h == null || x.load! > h.load!) heaviest[key] = x;
    final e = x.estimate;
    if (e != null && (best[key] == null || e > best[key]!.$1)) best[key] = (e, x);
  }
  Map<String, Object?> src(_Set x) => {
    'exercise': x.exercise['name'],
    'day': _day(x.day),
    'session': x.session['name'],
    'load': x.load,
    'unit': x.unit,
    'reps': x.reps,
  };
  return {
    'heaviestCompletedLoad': [for (final x in heaviest.values) src(x)],
    'bestEstimatedOneRepMax': [
      for (final (e, x) in best.values) {...src(x), 'estimate': double.parse(e.toStringAsFixed(1))},
    ],
    'rules': {
      'heaviestCompletedLoad': 'Highest load on a completed set, per exercise and unit.',
      'bestEstimatedOneRepMax': 'Mean of Epley and Brzycki on completed working sets of 1–10 reps.',
    },
  };
}

Map<String, Object?> _roadmap(ReparcSnapshot s) {
  final active = s.table('programs').where((p) => p['active'] == true).firstOrNull;
  if (active == null) return {'roadmap': null};
  return {
    'roadmap': ProgramPlan.decode(active['plan'] as String).toJson(),
    'nextDayIndex': active['nextDay'],
    'startedAt': active['createdAt'],
  };
}

// --------------------------------------------------------------------- Meal

NutritionInput _input(Map<String, Object?> m) {
  double? d(String k) => (m[k] as num?)?.toDouble();
  return NutritionInput(
    servingAmount: d('servingAmount'),
    servingUnit: m['servingUnit'] as String?,
    amount: d('amount'),
    amountUnit: m['amountUnit'] as String?,
    energyKcal: d('energyKcal'),
    proteinG: d('proteinG'),
    carbsG: d('carbsG'),
    fatG: d('fatG'),
    fiberG: d('fiberG'),
    sugarG: d('sugarG'),
    sodiumMg: d('sodiumMg'),
    isEstimate: m['isEstimate'] == true,
    status: m['status'] == 'eaten' ? MealStatus.eaten : MealStatus.planned,
  );
}

double? _r(double? v) => v == null ? null : double.parse(v.toStringAsFixed(1));

Map<String, Object?> _nutrients(NutritionTotals t) => {
  for (final n in Nutrient.values)
    '${n.name}${n == Nutrient.energy ? 'Kcal' : (n == Nutrient.sodium ? 'Mg' : 'G')}': _r(t.of(n).value),
};

Map<String, Object?> _mealTotals(ReparcSnapshot s, (DateTime, DateTime) r) {
  final byDay = <String, List<NutritionInput>>{};
  for (final m in s.table('mealEntries')) {
    final day = m['day'] as String;
    if (!_inRange(parseDayKey(day), r)) continue;
    (byDay[day] ??= []).add(_input(m));
  }
  final totals = {
    for (final e in byDay.entries)
      if (e.value.any((i) => i.status == MealStatus.eaten)) e.key: totalsOf(e.value),
  };
  final targets = s.settings['targetsOn'] == 'true' ? dailyTargets(s.profile) : const <Target>[];
  final keys = totals.keys.toList()..sort();
  return {
    'from': _day(r.$1),
    'to': _day(r.$2),
    'daysInRange': r.$2.difference(r.$1).inDays + 1,
    'daysWithFood': keys.length,
    'days': [
      for (final k in keys)
        {'day': k, ..._nutrients(totals[k]!), 'foods': totals[k]!.entries, 'estimates': totals[k]!.estimates},
    ],
    'averagePerDay': {
      for (final n in Nutrient.values)
        n.name: () {
          final v = [for (final t in totals.values) t.of(n).value].whereType<double>().toList();
          return {
            'value': _r(v.isEmpty ? null : v.reduce((a, b) => a + b) / v.length),
            'days': v.length,
            'unit': n.unit,
          };
        }(),
    },
    'targets': [
      for (final t in targets)
        {
          'nutrient': t.nutrient.name,
          'amount': t.amount,
          'kind': t.isLimit ? 'stay under' : 'reach',
          'daysOnTarget': totals.values.where((d) {
            final v = d.of(t.nutrient).value;
            return v != null && (t.isLimit ? v <= t.amount : v >= t.amount);
          }).length,
          'daysWithValue': totals.values.where((d) => d.of(t.nutrient).value != null).length,
        },
    ],
    'note': 'Eaten foods only. Planned foods are not counted. null means no food that day had that value.',
  };
}

Map<String, Object?> _mealLog(ReparcSnapshot s, String day) {
  try {
    parseDayKey(day);
  } catch (_) {
    throw ArgumentError('day must be like 2026-03-02.');
  }
  final slots = {for (final r in s.table('mealSlots')) r['id']: r['name']};
  return {
    'day': day,
    'foods': [
      for (final m in s.table('mealEntries'))
        if (m['day'] == day)
          () {
            final e = _input(m).eaten;
            return {
              'name': m['name'],
              'meal': slots[m['slotId']],
              'status': m['status'],
              'amount': m['amount'],
              'unit': m['amountUnit'],
              'energyKcal': _r(e.energyKcal),
              'proteinG': _r(e.proteinG),
              'carbsG': _r(e.carbsG),
              'fiberG': _r(e.fiberG),
              'fatG': _r(e.fatG),
              'sugarG': _r(e.sugarG),
              'sodiumMg': _r(e.sodiumMg),
              'source': m['source'],
              'isEstimate': m['isEstimate'],
            };
          }(),
    ],
  };
}

Map<String, Object?> _weights(ReparcSnapshot s, (DateTime, DateTime) r) => {
  'from': _day(r.$1),
  'to': _day(r.$2),
  'checkIns': [
    for (final w in s.table('bodyWeights'))
      if (_inRange(parseDayKey(w['day'] as String), r))
        {
          'day': w['day'],
          'value': w['value'],
          'unit': w['unit'],
          'kg': _r(w['unit'] == 'lb' ? (w['value'] as num) * _kgPerLb : (w['value'] as num).toDouble()),
        },
  ],
};

// ------------------------------------------------------------------ Imports

/// The formats an AI can write for the user to import.
const importFormats = <String, Object?>{
  'roadmap': {
    'kind': 'reparc-roadmap',
    'description':
        'A weekly training roadmap. Days in order. Every day should start with warm-up items. '
        'exerciseId: a Reparc ID when known (for example "bench-press" or "lib:Pushups"), else any short '
        'ID starting with "ai:". sets, repsLow, repsHigh, seconds, restSec, and rir are whole numbers.',
    'example': {
      'kind': 'reparc-roadmap',
      'goal': 'aesthetic',
      'level': 'beginner',
      'setup': 'fullGym',
      'weekdays': [1, 3, 5],
      'progression': 'Add a rep each week, then add weight.',
      'deload': 'Every 6–8 weeks, do half the sets for one week.',
      'days': [
        {
          'name': 'Full body A',
          'focus': 'Squat, push, pull',
          'items': [
            {'kind': 'warmup', 'exerciseId': 'lib:Rope_Jumping', 'name': 'Easy cardio', 'seconds': 300},
            {
              'kind': 'main',
              'exerciseId': 'back-squat',
              'name': 'Back squat',
              'sets': 3,
              'repsLow': 6,
              'repsHigh': 10,
              'restSec': 150,
              'rir': 2,
              'rampUp': true,
            },
          ],
        },
      ],
    },
    'allowed': {
      'goal': ['aesthetic', 'bodybuilding', 'strength', 'calisthenics', 'leanFit'],
      'level': ['beginner', 'intermediate', 'advanced'],
      'setup': ['fullGym', 'dumbbells', 'home'],
      'kind': ['warmup', 'main', 'secondary', 'accessory', 'core', 'finisher', 'cooldown'],
    },
  },
  'mealPlan': {
    'kind': 'reparc-meal-plan',
    'description':
        'One day of meals. Values are per 100 g of each food. Leave a value out if you do not know it; do not '
        'write 0 for unknown. Reparc adds the foods as planned, not eaten, after the user approves.',
    'example': {
      'kind': 'reparc-meal-plan',
      'day': '2026-03-02',
      'meals': [
        {
          'slot': 'breakfast',
          'name': 'Oats with Greek yogurt',
          'foods': [
            {
              'name': 'Oats, dry',
              'grams': 50,
              'per100g': {'kcal': 379, 'protein': 13.2, 'carbs': 67.7, 'fiber': 10.1, 'fat': 6.5},
              'source': 'USDA FDC 173904',
            },
          ],
        },
      ],
    },
    'allowed': {
      'slot': ['breakfast', 'lunch', 'snack', 'dinner'],
      'per100g keys': ['kcal', 'protein', 'carbs', 'fiber', 'fat', 'sugar', 'sodium'],
    },
  },
};

/// Problems in a proposed roadmap. Empty means it can be imported.
List<String> roadmapProblems(Object? json) {
  final p = <String>[];
  if (json is! Map) return ['The plan must be a JSON object.'];
  if (json['kind'] != 'reparc-roadmap') p.add('kind must be "reparc-roadmap".');
  final days = json['days'];
  if (days is! List || days.isEmpty) {
    p.add('days must be a list with at least one day.');
    return p;
  }
  if (days.length > 7) p.add('A roadmap has at most 7 days.');
  for (final (i, d) in days.indexed) {
    if (d is! Map || d['name'] is! String || (d['name'] as String).trim().isEmpty) {
      p.add('Day ${i + 1} needs a name.');
      continue;
    }
    final items = d['items'];
    if (items is! List || items.isEmpty) {
      p.add('${d['name']} has no items.');
      continue;
    }
    if ((items.first as Map?)?['kind'] != 'warmup') p.add('${d['name']} should start with a warm-up item.');
    for (final it in items) {
      if (it is! Map || it['name'] is! String || it['exerciseId'] is! String) {
        p.add('Each item in ${d['name']} needs a name and an exerciseId.');
        continue;
      }
      for (final k in ['sets', 'repsLow', 'repsHigh', 'seconds', 'restSec', 'rir']) {
        final v = it[k];
        if (v != null && (v is! num || v < 0 || v != v.roundToDouble())) {
          p.add('${it['name']}: $k must be a whole number of 0 or more.');
        }
      }
      final lo = it['repsLow'], hi = it['repsHigh'];
      if (lo is num && hi is num && lo > hi) p.add('${it['name']}: repsLow is above repsHigh.');
      if ((it['sets'] as num? ?? 1) > 10) p.add('${it['name']}: more than 10 sets.');
    }
  }
  return p;
}

/// Turns a checked roadmap proposal into a plan.
ProgramPlan roadmapFromProposal(Map<String, Object?> json) {
  final days = (json['days'] as List).cast<Map<Object?, Object?>>();
  return ProgramPlan.fromJson({
    ...json,
    'weekdays': json['weekdays'] ?? [for (var i = 0; i < days.length; i++) i + 1],
    'days': [
      for (final d in days)
        {
          'name': d['name'],
          'focus': d['focus'] ?? '',
          'items': [
            for (final it in (d['items'] as List).cast<Map<Object?, Object?>>())
              {
                ...it.cast<String, Object?>(),
                'sets': (it['sets'] as num?)?.toInt() ?? 1,
                'note': it['note'] ?? (it['exerciseId'].toString().startsWith('ai:') ? 'Suggested by AI' : null),
              },
          ],
        },
    ],
  });
}

Map<String, Object?> checkRoadmap(Object? plan) {
  final problems = roadmapProblems(plan);
  if (problems.isNotEmpty) return {'ok': false, 'problems': problems};
  final p = roadmapFromProposal((plan! as Map).cast<String, Object?>());
  return {
    'ok': true,
    'problems': const <String>[],
    'summary': [
      for (final d in p.days)
        {'day': d.name, 'workSets': d.workSets, 'minutes': d.minutes, 'warmupItems': d.warmup.length},
    ],
    'next': 'Ask the user to paste this JSON into Me → AI connections → Import a plan.',
  };
}

/// Problems in a proposed meal plan. Empty means it can be imported.
List<String> mealPlanProblems(Object? json) {
  final p = <String>[];
  if (json is! Map) return ['The plan must be a JSON object.'];
  if (json['kind'] != 'reparc-meal-plan') p.add('kind must be "reparc-meal-plan".');
  final meals = json['meals'];
  if (meals is! List || meals.isEmpty) return [...p, 'meals must be a list with at least one meal.'];
  for (final m in meals) {
    if (m is! Map || m['foods'] is! List || (m['foods'] as List).isEmpty) {
      p.add('Each meal needs a list of foods.');
      continue;
    }
    if (!const ['breakfast', 'lunch', 'snack', 'dinner'].contains(m['slot'])) {
      p.add('${m['name'] ?? 'A meal'}: slot must be breakfast, lunch, snack, or dinner.');
    }
    for (final f in m['foods'] as List) {
      if (f is! Map || f['name'] is! String || f['grams'] is! num || (f['grams'] as num) <= 0) {
        p.add('Each food needs a name and grams above 0.');
        continue;
      }
      final per = f['per100g'];
      if (per is! Map) {
        p.add('${f['name']}: per100g is missing.');
        continue;
      }
      for (final e in per.entries) {
        if (!const ['kcal', 'protein', 'carbs', 'fiber', 'fat', 'sugar', 'sodium'].contains(e.key)) {
          p.add('${f['name']}: unknown nutrient "${e.key}".');
        } else if (e.value is! num || (e.value as num) < 0) {
          p.add('${f['name']}: ${e.key} must be a number of 0 or more.');
        }
      }
      final g = per['protein'], c = per['carbs'], fat = per['fat'];
      if ([g, c, fat].every((x) => x is num) && (g as num) + (c as num) + (fat as num) > 100) {
        p.add('${f['name']}: protein, carbs, and fat add up to more than 100 g per 100 g.');
      }
    }
  }
  return p;
}

Map<String, Object?> checkMealPlan(ReparcSnapshot s, Object? plan) {
  final problems = mealPlanProblems(plan);
  if (problems.isNotEmpty) return {'ok': false, 'problems': problems};
  final totals = <String, double>{};
  for (final m in ((plan! as Map)['meals'] as List).cast<Map<Object?, Object?>>()) {
    for (final f in (m['foods'] as List).cast<Map<Object?, Object?>>()) {
      final g = (f['grams'] as num).toDouble();
      for (final e in (f['per100g'] as Map).entries) {
        totals[e.key as String] = (totals[e.key] ?? 0) + (e.value as num) * g / 100;
      }
    }
  }
  final targets = s.has('body') ? dailyTargets(s.profile) : const <Target>[];
  const keyOf = {
    Nutrient.energy: 'kcal',
    Nutrient.protein: 'protein',
    Nutrient.carbs: 'carbs',
    Nutrient.fiber: 'fiber',
    Nutrient.fat: 'fat',
    Nutrient.sugar: 'sugar',
    Nutrient.sodium: 'sodium',
  };
  return {
    'ok': true,
    'problems': const <String>[],
    'totals': {for (final e in totals.entries) e.key: _r(e.value)},
    'againstTargets': [
      for (final t in targets)
        {
          'nutrient': t.nutrient.name,
          'planned': _r(totals[keyOf[t.nutrient]]),
          'target': t.amount,
          'kind': t.isLimit ? 'stay under' : 'reach',
        },
    ],
    'next': 'Ask the user to paste this JSON into Me → AI connections → Import a plan.',
  };
}
