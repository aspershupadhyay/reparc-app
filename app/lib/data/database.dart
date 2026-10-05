import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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

  /// Archived exercises stay linked to old sessions but leave the library.
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
}

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

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

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
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Opens the on-device database file.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'reparc'));

  /// Current local data format. Every change needs a migration, a test from
  /// the last supported version, and a recovery plan (handbook 7.5).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await seedMealSlots();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Default meal slots. The user can rename, reorder, or remove them.
  Future<void> seedMealSlots() async {
    final now = DateTime.now().toUtc();
    const defaults = [
      ('slot-breakfast', 'Breakfast', 8 * 60),
      ('slot-lunch', 'Lunch', 13 * 60),
      ('slot-dinner', 'Dinner', 19 * 60),
      ('slot-snacks', 'Snacks', null),
    ];
    for (final (i, d) in defaults.indexed) {
      await into(mealSlots).insert(
        MealSlotsCompanion.insert(
          id: d.$1,
          name: d.$2,
          position: i,
          usualMinute: Value(d.$3),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}
