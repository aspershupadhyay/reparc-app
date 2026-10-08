import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../domain/roadmap.dart';
import 'database.dart';

const _uuid = Uuid();

/// A saved plan row with its days decoded.
class SavedProgram {
  const SavedProgram(this.row, this.plan);
  final Program row;
  final ProgramPlan plan;

  String get id => row.id;
  String get name => row.name;

  /// The plan the user follows. Home and the start card use its next day.
  bool get followed => row.active;
  int get nextDay => plan.days.isEmpty ? 0 : row.nextDay.clamp(0, plan.days.length - 1);
}

/// Plans and roadmaps: one kind of record (handbook 4.12). The user follows
/// at most one plan at a time; any day of any plan can start at any time.
class ProgramRepository {
  ProgramRepository(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  DateTime get _now => clock().toUtc();

  static SavedProgram _saved(Program r) => SavedProgram(r, ProgramPlan.decode(r.plan));

  Stream<SavedProgram?> watchActive() =>
      (db.select(db.programs)
            ..where((p) => p.active.equals(true))
            ..limit(1))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _saved(r));

  /// Every plan: the followed one first, then the newest.
  Stream<List<SavedProgram>> watchAll() =>
      (db.select(db.programs)..orderBy([
            (p) => OrderingTerm.desc(p.active),
            (p) => OrderingTerm.desc(p.updatedAt),
          ]))
          .watch()
          .map((rows) => [for (final r in rows) _saved(r)]);

  Stream<SavedProgram?> watch(String id) => (db.select(
    db.programs,
  )..where((p) => p.id.equals(id))).watchSingleOrNull().map((r) => r == null ? null : _saved(r));

  Future<SavedProgram?> active() async {
    final r = await (db.select(db.programs)..where((p) => p.active.equals(true))).getSingleOrNull();
    return r == null ? null : _saved(r);
  }

  /// Every plan: the followed one first, then the newest.
  Future<List<SavedProgram>> all() async => [
    for (final r in await (db.select(
      db.programs,
    )..orderBy([(p) => OrderingTerm.desc(p.active), (p) => OrderingTerm.desc(p.updatedAt)])).get())
      _saved(r),
  ];

  /// Saves [plan] and follows it. Other plans stay saved but are no longer
  /// followed, so their workout history keeps its link.
  Future<String> adopt(ProgramPlan plan, {String? name}) => create(plan, name: name, follow: true);

  /// Saves a new plan. It is followed only when [follow] is true.
  Future<String> create(ProgramPlan plan, {String? name, bool follow = false}) => db.transaction(() async {
    final now = _now;
    if (follow) await _unfollowAll(now);
    final id = _uuid.v4();
    await db
        .into(db.programs)
        .insert(
          ProgramsCompanion.insert(
            id: id,
            name: (name ?? plan.title).trim(),
            goal: plan.goal?.name ?? 'custom',
            level: plan.level?.name ?? 'custom',
            equipment: plan.setup?.name ?? 'custom',
            daysPerWeek: plan.days.length,
            active: Value(follow),
            plan: plan.encode(),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  });

  /// Saves the user's edits to a plan.
  Future<void> save(String id, ProgramPlan plan) => (db.update(db.programs)..where((p) => p.id.equals(id))).write(
    ProgramsCompanion(plan: Value(plan.encode()), daysPerWeek: Value(plan.days.length), updatedAt: Value(_now)),
  );

  Future<void> rename(String id, String name) => (db.update(
    db.programs,
  )..where((p) => p.id.equals(id))).write(ProgramsCompanion(name: Value(name.trim()), updatedAt: Value(_now)));

  Future<void> setNextDay(String id, int day) => (db.update(
    db.programs,
  )..where((p) => p.id.equals(id))).write(ProgramsCompanion(nextDay: Value(day), updatedAt: Value(_now)));

  /// Follows [id]. The plan followed before stays saved.
  Future<void> follow(String id) => db.transaction(() async {
    final now = _now;
    await _unfollowAll(now);
    await (db.update(
      db.programs,
    )..where((p) => p.id.equals(id))).write(ProgramsCompanion(active: const Value(true), updatedAt: Value(now)));
  });

  /// Stops following a plan. It stays saved.
  Future<void> stop(String id) => (db.update(
    db.programs,
  )..where((p) => p.id.equals(id))).write(ProgramsCompanion(active: const Value(false), updatedAt: Value(_now)));

  /// Saves a copy that is not followed.
  Future<String> copy(String id) async {
    final src = await (db.select(db.programs)..where((p) => p.id.equals(id))).getSingle();
    return create(ProgramPlan.decode(src.plan), name: '${src.name} (copy)');
  }

  /// Deletes a plan. Saved workouts keep their exercises and sets.
  Future<void> delete(String id) => (db.delete(db.programs)..where((p) => p.id.equals(id))).go();

  Future<void> _unfollowAll(DateTime now) => (db.update(db.programs)..where((p) => p.active.equals(true))).write(
    ProgramsCompanion(active: const Value(false), updatedAt: Value(now)),
  );
}
