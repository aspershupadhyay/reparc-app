import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/palette.dart';
import 'package:reparc/core/theme.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/analytics.dart';
import 'package:reparc/features/workout/record_moment.dart';

import 'helpers.dart';

void main() {
  testWidgets('the PR moment names the lift and the new best', (tester) async {
    final db = memoryDb();
    final clock = FakeClock(DateTime(2026, 3, 2, 18));
    final w = WorkoutRepository(db, clock.call);
    late List<PersonalRecord> records;
    await tester.runAsync(() async {
      final bench = await w.createExercise(name: 'Bench press');
      for (final load in [80.0, 82.5]) {
        final s = await w.startSession();
        final se = await w.addSessionExercise(s, bench);
        final set = await w.addSet(se);
        await w.updateSet(
          set,
          SetEntriesCompanion(load: Value(load), loadUnit: const Value('kg'), reps: const Value(6)),
        );
        await w.setCompleted(set, true);
        await w.end(s, finished: true);
        clock.advance(const Duration(days: 2));
      }
      final all = await w.completedSets();
      final latest = all.map((r) => r.session).reduce((a, b) => a.startedAt.isAfter(b.startedAt) ? a : b);
      records = newRecordsIn(latest.id, all);
      await db.close();
    });
    expect(recordLine(records.single), 'New best: Bench press 82.5 kg × 6');

    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Palette.light),
        home: Builder(
          builder: (context) =>
              TextButton(onPressed: () => showRecordMoment(context, records), child: const Text('go')),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('NEW BEST'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('82.5 kg × 6'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('NEW BEST'), findsNothing);
  });
}
