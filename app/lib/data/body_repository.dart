import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/clock.dart';
import '../core/dates.dart';
import 'database.dart';

const _uuid = Uuid();

/// Exact pounds-to-kilograms factor (international pound, 1959).
const kgPerLb = 0.45359237;

double toKg(double value, String unit) => unit == 'lb' ? value * kgPerLb : value;
double fromKg(double kg, String unit) => unit == 'lb' ? kg / kgPerLb : kg;

/// Body weight check-ins. The value is saved in the unit the user typed.
class BodyRepository {
  BodyRepository(this.db, this.clock);
  final AppDatabase db;
  final Clock clock;

  Stream<List<BodyWeight>> watchWeights() =>
      (db.select(db.bodyWeights)..orderBy([(w) => OrderingTerm.asc(w.measuredAt)])).watch();

  Future<List<BodyWeight>> weights() =>
      (db.select(db.bodyWeights)..orderBy([(w) => OrderingTerm.asc(w.measuredAt)])).get();

  Future<String> addWeight(double value, String unit) async {
    if (value <= 0 || value.isNaN) throw StateError('Enter a weight above 0.');
    final local = clock();
    final now = local.toUtc();
    final id = _uuid.v4();
    await db
        .into(db.bodyWeights)
        .insert(
          BodyWeightsCompanion.insert(
            id: id,
            day: dayKey(dayOf(local)),
            value: value,
            unit: unit,
            measuredAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> deleteWeight(String id) => (db.delete(db.bodyWeights)..where((w) => w.id.equals(id))).go();
}
