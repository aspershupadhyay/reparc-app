import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../domain/roadmap.dart';
import 'database.dart';

const _uuid = Uuid();

/// A saved roadmap row with its plan decoded.
class SavedProgram {
  const SavedProgram(this.row, this.plan);
  final Program row;
  final ProgramPlan plan;

  String get id => row.id;
  int get nextDay => plan.days.isEmpty ? 0 : row.nextDay.clamp(0, plan.days.length - 1);
}

/// Roadmaps the user chose. Only one is active at a time.
class ProgramRepository {
  ProgramRepository(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  DateTime get _now => clock().toUtc();

  Stream<SavedProgram?> watchActive() =>
      (db.select(db.programs)
            ..where((p) => p.active.equals(true))
            ..limit(1))
          .watchSingleOrNull()
          .map((r) => r == null ? null : SavedProgram(r, ProgramPlan.decode(r.plan)));

  Stream<SavedProgram?> watch(String id) => (db.select(db.programs)..where((p) => p.id.equals(id)))
      .watchSingleOrNull()
      .map((r) => r == null ? null : SavedProgram(r, ProgramPlan.decode(r.plan)));

  Future<SavedProgram?> active() async {
    final r = await (db.select(db.programs)..where((p) => p.active.equals(true))).getSingleOrNull();
    return r == null ? null : SavedProgram(r, ProgramPlan.decode(r.plan));
  }

  /// Saves [plan] as the active roadmap. Older roadmaps stay saved but
  /// inactive, so their workout history keeps its link.
  Future<String> adopt(ProgramPlan plan) => db.transaction(() async {
    final now = _now;
    await (db.update(db.programs)..where((p) => p.active.equals(true))).write(
      ProgramsCompanion(active: const Value(false), updatedAt: Value(now)),
    );
    final id = _uuid.v4();
    await db
        .into(db.programs)
        .insert(
          ProgramsCompanion.insert(
            id: id,
            name: plan.title,
            goal: plan.goal.name,
            level: plan.level.name,
            equipment: plan.setup.name,
            daysPerWeek: plan.days.length,
            active: const Value(true),
            plan: plan.encode(),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  });

  /// Saves the user's edits to a roadmap.
  Future<void> save(String id, ProgramPlan plan) => (db.update(db.programs)..where((p) => p.id.equals(id))).write(
    ProgramsCompanion(plan: Value(plan.encode()), daysPerWeek: Value(plan.days.length), updatedAt: Value(_now)),
  );

  Future<void> setNextDay(String id, int day) => (db.update(
    db.programs,
  )..where((p) => p.id.equals(id))).write(ProgramsCompanion(nextDay: Value(day), updatedAt: Value(_now)));

  /// Stops following the active roadmap. It stays saved.
  Future<void> stop(String id) => (db.update(
    db.programs,
  )..where((p) => p.id.equals(id))).write(ProgramsCompanion(active: const Value(false), updatedAt: Value(_now)));
}
