import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../domain/roadmap.dart';
import 'models.dart';

part 'database.g.dart';

/// Columns shared by every user record.
///
/// IDs are UUID v4 text so a later sync retry cannot create a duplicate.
mixin RecordColumns on Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Exercises extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get variation => text().nullable()();
  TextColumn get equipment => text().nullable()();
  TextColumn get targetMuscles => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get instructionSource => text().nullable()();

  /// ID of the built-in coached exercise this row logs, if any. Added in v2.
  TextColumn get catalogId => text().nullable()();

  /// Archived exercises stay linked to old sessions but leave the library.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// Plans from schema v4 and before. Since v5 they are copied into
/// [Programs] and the app no longer reads or writes them. A later version
/// removes these two tables (handbook 4.12).
class WorkoutTemplates extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get note => text().nullable()();
}

class TemplateExercises extends Table with RecordColumns {
  TextColumn get templateId => text().references(WorkoutTemplates, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  IntColumn get targetSets => integer().nullable()();
  IntColumn get targetReps => integer().nullable()();
}

class WorkoutSessions extends Table with RecordColumns {
  TextColumn get templateId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get status => textEnum<SessionStatus>()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();

  /// Total paused time before the current pause, in milliseconds.
  IntColumn get pausedMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get pausedAt => dateTime().nullable()();

  /// Rest timer. It is stored so it survives a restart.
  DateTimeColumn get restStartedAt => dateTime().nullable()();
  IntColumn get restTargetSec => integer().nullable()();

  /// UTC offset and zone name when the session started. Used for the day view.
  IntColumn get utcOffsetMinutes => integer()();
  TextColumn get timeZoneName => text()();
  TextColumn get note => text().nullable()();

  /// Roadmap day this session came from, if any. Added in v4.
  TextColumn get programId => text().nullable()();
  IntColumn get programDay => integer().nullable()();
}

class SessionExercises extends Table with RecordColumns {
  TextColumn get sessionId => text().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get position => integer()();
  TextColumn get supersetGroup => text().nullable()();
  BoolColumn get skipped => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
}

class SetEntries extends Table with RecordColumns {
  TextColumn get sessionExerciseId => text().references(SessionExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get setType => textEnum<SetType>()();
  IntColumn get reps => integer().nullable()();
  RealColumn get load => real().nullable()();
  TextColumn get loadUnit => text().nullable()();
  IntColumn get durationSec => integer().nullable()();
  RealColumn get distance => real().nullable()();
  TextColumn get distanceUnit => text().nullable()();
  IntColumn get restSec => integer().nullable()();
  RealColumn get effort => real().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get completed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// A food the user saved for reuse. Nutrient values are per serving.
class Foods extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get brand => text().nullable()();
  RealColumn get servingAmount => real().nullable()();
  TextColumn get servingUnit => text().nullable()();
  RealColumn get energyKcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();

  /// Added in v4. Null means not recorded.
  RealColumn get fiberG => real().nullable()();
  RealColumn get sugarG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
  TextColumn get source => text()();
  DateTimeColumn get sourceCheckedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
}

class MealSlots extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 60)();
  IntColumn get position => integer()();

  /// Usual time as minutes after midnight. Optional.
  IntColumn get usualMinute => integer().nullable()();

  /// Icon and colour group: drink, breakfast, snack, lunch, dinner. Added in v2.
  TextColumn get kind => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

/// A planned or eaten food in a meal slot on one local day.
///
/// The source serving and the amount eaten are separate values. Nutrients
/// are stored per source serving. Totals are calculated, never stored.
class MealEntries extends Table with RecordColumns {
  TextColumn get day => text()();
  TextColumn get slotId => text().references(MealSlots, #id)();
  TextColumn get foodId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get brand => text().nullable()();
  RealColumn get servingAmount => real().nullable()();
  TextColumn get servingUnit => text().nullable()();
  RealColumn get energyKcal => real().nullable()();
  RealColumn get proteinG => real().nullable()();
  RealColumn get carbsG => real().nullable()();
  RealColumn get fatG => real().nullable()();

  /// Added in v4. Per source serving, like the values above.
  RealColumn get fiberG => real().nullable()();
  RealColumn get sugarG => real().nullable()();
  RealColumn get sodiumMg => real().nullable()();
  RealColumn get amount => real().nullable()();
  TextColumn get amountUnit => text().nullable()();
  BoolColumn get isEstimate => boolean().withDefault(const Constant(false))();
  TextColumn get source => text()();
  DateTimeColumn get sourceCheckedAt => dateTime().nullable()();
  TextColumn get status => textEnum<MealStatus>()();
  DateTimeColumn get eatenAt => dateTime().nullable()();
  TextColumn get timeZoneName => text()();
  TextColumn get note => text().nullable()();
}

/// A training roadmap the user chose and may have edited. Added in v4.
///
/// [plan] is a JSON document (see domain/roadmap.dart, `ProgramPlan`). The
/// user owns it: every day, exercise, set, and rep target can change.
class Programs extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get goal => text()();
  TextColumn get level => text()();
  TextColumn get equipment => text()();
  IntColumn get daysPerWeek => integer()();
  BoolColumn get active => boolean().withDefault(const Constant(false))();

  /// Index of the next day to train in [plan].
  IntColumn get nextDay => integer().withDefault(const Constant(0))();
  TextColumn get plan => text()();
}

/// Body weight check-ins. The original unit is kept. Added in v4.
class BodyWeights extends Table with RecordColumns {
  TextColumn get day => text()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  DateTimeColumn get measuredAt => dateTime()();
}

/// A change an AI client asked for. Nothing in it is applied until the user
/// approves it on this phone (handbook 10.4, D-019). Added in v3.
class AiProposals extends Table with RecordColumns {
  TextColumn get kind => textEnum<ProposalKind>()();

  /// Name the AI client gave, for example "Claude". Shown, never trusted.
  TextColumn get client => text()();

  /// How the request arrived: 'wifi' or 'online'.
  TextColumn get via => text()();
  TextColumn get summary => text()();

  /// The validated request as JSON. Its shape depends on [kind].
  TextColumn get payload => text()();
  TextColumn get status => textEnum<ProposalStatus>()();
  DateTimeColumn get decidedAt => dateTime().nullable()();
}

/// Records Reparc wrote to Apple Health or Health Connect, so a record is
/// never written twice (handbook 9.5). Added in v3.
class HealthWrites extends Table {
  /// ID of the Reparc record, for example a workout session ID.
  TextColumn get recordId => text()();

  /// 'workout' or 'meal'.
  TextColumn get kind => text()();
  DateTimeColumn get writtenAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {recordId, kind};
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

const _defaultKinds = [
  ('slot-breakfast', 'breakfast'),
  ('slot-lunch', 'lunch'),
  ('slot-dinner', 'dinner'),
  ('slot-snacks', 'snack'),
];

@DriftDatabase(
  tables: [
    Exercises,
    WorkoutTemplates,
    TemplateExercises,
    WorkoutSessions,
    SessionExercises,
    SetEntries,
    Foods,
    MealSlots,
    MealEntries,
    Programs,
    BodyWeights,
    Settings,
    AiProposals,
    HealthWrites,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'reparc'));

  /// Current local data format. Every change needs a migration, a test from
  /// the last supported version, and a recovery plan (handbook 7.5).
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedMealSlots();
    },
    onUpgrade: (m, from, to) async {
      // v1 -> v2: built-in exercise link and meal slot kind.
      if (from < 2) {
        await m.addColumn(exercises, exercises.catalogId);
        await m.addColumn(mealSlots, mealSlots.kind);
        for (final (id, kind) in _defaultKinds) {
          await (update(mealSlots)..where((s) => s.id.equals(id))).write(MealSlotsCompanion(kind: Value(kind)));
        }
      }
      // v2 -> v3: AI proposals and the health write-back ledger.
      if (from < 3) {
        await m.createTable(aiProposals);
        await m.createTable(healthWrites);
      }
      // v3 -> v4: fiber, sugar, sodium; roadmaps; body weight.
      if (from < 4) {
        await m.addColumn(foods, foods.fiberG);
        await m.addColumn(foods, foods.sugarG);
        await m.addColumn(foods, foods.sodiumMg);
        await m.addColumn(mealEntries, mealEntries.fiberG);
        await m.addColumn(mealEntries, mealEntries.sugarG);
        await m.addColumn(mealEntries, mealEntries.sodiumMg);
        await m.addColumn(workoutSessions, workoutSessions.programId);
        await m.addColumn(workoutSessions, workoutSessions.programDay);
        await m.createTable(programs);
        await m.createTable(bodyWeights);
      }
      // v4 -> v5: plans and roadmaps become one kind of plan.
      if (from < 5) await transaction(copyLegacyPlans);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Copies plans from schema v4 and before into [programs] as one-day
  /// plans with the same IDs. Plans copied before are skipped. Sessions
  /// started from a copied plan get its ID and day 0. Returns the number of
  /// plans copied (handbook 4.12).
  Future<int> copyLegacyPlans() async {
    var copied = 0;
    for (final t in await select(workoutTemplates).get()) {
      if (await (select(programs)..where((p) => p.id.equals(t.id))).getSingleOrNull() != null) continue;
      final rows =
          await (select(templateExercises).join([
                  innerJoin(exercises, exercises.id.equalsExp(templateExercises.exerciseId)),
                ])
                ..where(templateExercises.templateId.equals(t.id))
                ..orderBy([OrderingTerm.asc(templateExercises.position)]))
              .get();
      final day = simpleDay(t.name, focus: t.note ?? '', [
        for (final r in rows)
          (
            exerciseId: r.readTable(exercises).catalogId ?? userRef(r.readTable(exercises).id),
            name: r.readTable(exercises).name,
            sets: r.readTable(templateExercises).targetSets,
            reps: r.readTable(templateExercises).targetReps,
          ),
      ]);
      await into(programs).insert(
        ProgramsCompanion.insert(
          id: t.id,
          name: t.name,
          goal: 'custom',
          level: 'custom',
          equipment: 'custom',
          daysPerWeek: 1,
          plan: ProgramPlan(days: [day]).encode(),
          createdAt: t.createdAt,
          updatedAt: t.updatedAt,
        ),
      );
      await (update(workoutSessions)..where((s) => s.templateId.equals(t.id) & s.programId.isNull())).write(
        WorkoutSessionsCompanion(programId: Value(t.id), programDay: const Value(0)),
      );
      copied++;
    }
    return copied;
  }

  /// Default meal slots. The user can rename, reorder, or remove them.
  Future<void> seedMealSlots() async {
    final now = DateTime.now().toUtc();
    const defaults = [
      ('slot-breakfast', 'Breakfast', 8 * 60, 'breakfast'),
      ('slot-lunch', 'Lunch', 13 * 60, 'lunch'),
      ('slot-snacks', 'Snacks', 16 * 60 + 30, 'snack'),
      ('slot-dinner', 'Dinner', 19 * 60 + 30, 'dinner'),
    ];
    for (final (i, d) in defaults.indexed) {
      await into(mealSlots).insert(
        MealSlotsCompanion.insert(
          id: d.$1,
          name: d.$2,
          position: i,
          usualMinute: Value(d.$3),
          kind: Value(d.$4),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}
