import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import '../data/database.dart';
import '../data/meal_repository.dart';
import '../data/models.dart';
import '../data/program_repository.dart';
import '../data/workout_repository.dart';
import '../domain/roadmap.dart';
import '../features/exercises/catalog/catalog.dart';
import '../features/exercises/library/library.dart';

const _uuid = Uuid();

/// Source text saved on meal entries that came from an approved proposal.
String aiMealSource(String client) => 'AI suggestion from $client, approved by you';

/// Plans and meals an AI client proposed (handbook 10.4, D-019).
///
/// A proposal is data only. [approve] is the single path that turns it into
/// records, and only the user's tap in the app calls it.
class ProposalRepository {
  ProposalRepository(this.db, this.clock, this.workouts, this.meals, this.library);

  final AppDatabase db;
  final Clock clock;
  final WorkoutRepository workouts;
  final MealRepository meals;
  final Future<ExerciseLibrary> Function() library;

  DateTime get _now => clock().toUtc();

  Stream<List<AiProposal>> watchPending() =>
      (db.select(db.aiProposals)
            ..where((p) => p.status.equalsValue(ProposalStatus.pending))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .watch();

  Stream<List<AiProposal>> watchRecent() =>
      (db.select(db.aiProposals)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
            ..limit(20))
          .watch();

  Stream<AiProposal?> watch(String id) =>
      (db.select(db.aiProposals)..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<AiProposal?> find(String id) => (db.select(db.aiProposals)..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Saves a validated proposal as pending. At most 20 can wait at once,
  /// so a client cannot flood the review list.
  Future<String> create({
    required ProposalKind kind,
    required String client,
    required String via,
    required String summary,
    required Map<String, Object?> payload,
  }) async {
    final waiting = await (db.select(
      db.aiProposals,
    )..where((p) => p.status.equalsValue(ProposalStatus.pending))).get();
    if (waiting.length >= 20) {
      throw const ProposalLimit();
    }
    final id = _uuid.v4();
    final now = _now;
    await db
        .into(db.aiProposals)
        .insert(
          AiProposalsCompanion.insert(
            id: id,
            kind: kind,
            client: client,
            via: via,
            summary: summary,
            payload: jsonEncode(payload),
            status: ProposalStatus.pending,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> decline(String id) => _decide(id, ProposalStatus.declined);

  /// Applies a pending proposal in one transaction, then marks it approved.
  /// Returns the ID of the created plan, or of created meal entries.
  Future<List<String>> approve(String id) => db.transaction(() async {
    final p = await find(id);
    if (p == null || p.status != ProposalStatus.pending) throw StateError('This proposal is no longer waiting.');
    final payload = jsonDecode(p.payload) as Map<String, dynamic>;
    final created = switch (p.kind) {
      ProposalKind.workoutPlan => await _applyPlans(payload, p.client),
      ProposalKind.mealPlan => await _applyMeals(payload, p.client),
    };
    await _decide(id, ProposalStatus.approved);
    return created;
  });

  Future<void> _decide(String id, ProposalStatus status) =>
      (db.update(db.aiProposals)..where((p) => p.id.equals(id))).write(
        AiProposalsCompanion(status: Value(status), decidedAt: Value(_now), updatedAt: Value(_now)),
      );

  /// Proposed workouts become one plan with one day for each workout. It is
  /// saved, not followed; the user taps Follow (handbook 4.12).
  Future<List<String>> _applyPlans(Map<String, dynamic> payload, String client) async {
    final lib = await library();
    final plans = (payload['plans'] as List).cast<Map<String, dynamic>>();
    final days = <PlanDay>[];
    for (final plan in plans) {
      final items = <SimpleItem>[];
      for (final e in (plan['exercises'] as List).cast<Map<String, dynamic>>()) {
        final rowId = await resolveExercise(e['name'] as String, e['library_id'] as String?, lib);
        final row = await (db.select(db.exercises)..where((x) => x.id.equals(rowId))).getSingle();
        items.add((
          exerciseId: row.catalogId ?? userRef(row.id),
          name: row.name,
          sets: e['sets'] as int?,
          reps: e['reps'] as int?,
        ));
      }
      days.add(simpleDay(plan['name'] as String, items, focus: plan['note'] as String? ?? ''));
    }
    final name = plans.length == 1 ? plans.single['name'] as String : 'Plan from $client';
    return [await ProgramRepository(db, clock).create(ProgramPlan(days: days), name: name)];
  }

  /// Finds the exercise row a proposed exercise should use. A known library
  /// ID wins; then an existing exercise with the same name; then a new one.
  Future<String> resolveExercise(String name, String? libraryId, ExerciseLibrary lib) async {
    if (libraryId != null) {
      final coached = catalogById[libraryId];
      if (coached != null) {
        return workouts.ensureCatalogExercise(
          catalogId: coached.id,
          name: coached.name,
          equipment: coached.equipment,
          targetMuscles: coached.primary.map((m) => m.label).join(', '),
        );
      }
      final entry = lib.forCatalogId(libraryId);
      if (entry != null) {
        return workouts.ensureCatalogExercise(
          catalogId: entry.catalogId,
          name: entry.name,
          equipment: entry.equipment,
          targetMuscles: entry.primary.join(', '),
        );
      }
    }
    final wanted = name.trim().toLowerCase();
    final existing = await (db.select(db.exercises)..where((e) => e.archived.equals(false))).get();
    for (final e in existing) {
      if (e.name.trim().toLowerCase() == wanted) return e.id;
    }
    return workouts.createExercise(name: name.trim());
  }

  Future<List<String>> _applyMeals(Map<String, dynamic> payload, String client) async {
    final slots = await meals.allSlots();
    final ids = <String>[];
    for (final m in (payload['meals'] as List).cast<Map<String, dynamic>>()) {
      final slotId = _slotFor(slots, m['slot'] as String);
      final amount = (m['amount'] as num?)?.toDouble() ?? 1;
      final unit = m['unit'] as String? ?? 'serving';
      ids.add(
        await meals.addEntry(
          day: dayKey(parseDayKey(m['date'] as String)),
          slotId: slotId,
          food: FoodValues(
            name: m['name'] as String,
            // Values are for the whole proposed amount, so the serving is that amount.
            servingAmount: amount,
            servingUnit: unit,
            energyKcal: (m['energy_kcal'] as num?)?.toDouble(),
            proteinG: (m['protein_g'] as num?)?.toDouble(),
            carbsG: (m['carbs_g'] as num?)?.toDouble(),
            fatG: (m['fat_g'] as num?)?.toDouble(),
            isEstimate: true,
            source: aiMealSource(client),
            note: m['note'] as String?,
          ),
          amount: amount,
          amountUnit: unit,
          status: MealStatus.planned,
        ),
      );
    }
    return ids;
  }

  static String _slotFor(List<MealSlot> slots, String kind) {
    final want = kind == 'snacks' ? 'snack' : kind;
    for (final s in slots) {
      if (!s.archived && s.kind == want) return s.id;
    }
    for (final s in slots) {
      if (!s.archived) return s.id;
    }
    return slots.first.id;
  }
}

class ProposalLimit implements Exception {
  const ProposalLimit();
  @override
  String toString() => '20 proposals are already waiting for review. Ask the owner to review them in RepArc first.';
}
