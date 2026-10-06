import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/data/backup.dart';
import 'package:reparc/data/data_controls.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/meal_repository.dart';
import 'package:reparc/data/models.dart';
import 'package:reparc/data/settings_repository.dart';
import 'package:reparc/data/workout_repository.dart';

import 'helpers.dart';

/// Synthetic records only.
Future<void> seed(AppDatabase db, FakeClock clock) async {
  final w = WorkoutRepository(db, clock.call);
  final ex = await w.createExercise(name: 'Deadlift', equipment: 'Barbell');
  final t = await w.createTemplate('Pull day');
  await w.addTemplateExercise(t, ex, targetSets: 3, targetReps: 5);
  final s = await w.startSession(templateId: t);
  final se = await w.addSessionExercise(s, ex);
  final set = await w.addSet(se);
  await w.updateSet(set, const SetEntriesCompanion(reps: Value(5), load: Value(140), loadUnit: Value('kg')));
  await w.setCompleted(set, true);
  await w.end(s, finished: true);
  await MealRepository(db, clock.call).addEntry(
    day: '2026-03-02',
    slotId: 'slot-lunch',
    food: const FoodValues(name: 'Rice', servingAmount: 100, servingUnit: 'g', energyKcal: 130),
    amount: 180,
    amountUnit: 'g',
    status: MealStatus.eaten,
  );
  final settings = SettingsRepository(db);
  await settings.setLoadUnit('lb');
  await settings.setAiScope('gym', true);
  await settings.setHealth('steps', true);
}

Map<String, dynamic> tablesOf(String json) =>
    (jsonDecode(json) as Map<String, dynamic>)['tables'] as Map<String, dynamic>;

void main() {
  final clock = FakeClock(DateTime.utc(2026, 3, 2, 8));

  test('a backup restores every record on a new phone, but not AI or health switches', () async {
    final a = memoryDb();
    await seed(a, clock);
    final original = await DataControls(a, clock.call).exportJson(appVersion: 'test');
    final file = await BackupCrypto.seal(original, 'correct horse battery');
    final text = utf8.decode(file);
    expect(text, isNot(contains('Deadlift')));
    expect(text, isNot(contains('Rice')));
    expect((jsonDecode(text) as Map)['kdf'], containsPair('name', 'argon2id'));

    final b = memoryDb();
    final restored = await BackupCrypto.open(file, 'correct horse battery');
    final count = await DataControls(b, clock.call).importJson(restored);
    expect(count, greaterThan(8));
    final again = tablesOf(await DataControls(b, clock.call).exportJson(appVersion: 'test'));
    final before = tablesOf(original);
    for (final t in [
      'exercises',
      'workoutTemplates',
      'templateExercises',
      'workoutSessions',
      'sessionExercises',
      'setEntries',
      'mealEntries',
      'mealSlots',
    ]) {
      expect(again[t], before[t], reason: t);
    }
    final settings = await SettingsRepository(b).watch().first;
    expect(settings.loadUnit, 'lb');
    expect(settings.aiScopes, isEmpty);
    expect(settings.health, isEmpty);
    await a.close();
    await b.close();
  });

  test('a wrong passphrase or a changed file opens nothing', () async {
    final file = await BackupCrypto.seal('{"format":"reparc-export"}', 'right passphrase');
    await expectLater(
      BackupCrypto.open(file, 'wrong passphrase'),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('Wrong passphrase'))),
    );
    final env = jsonDecode(utf8.decode(file)) as Map<String, dynamic>;
    final data = base64.decode(env['data'] as String);
    data[0] ^= 1;
    env['data'] = base64.encode(data);
    await expectLater(
      BackupCrypto.open(Uint8List.fromList(utf8.encode(jsonEncode(env))), 'right passphrase'),
      throwsA(isA<BackupException>()),
    );
    await expectLater(
      BackupCrypto.open(Uint8List.fromList(utf8.encode('hello')), 'x'),
      throwsA(isA<BackupException>()),
    );
    env['kdf'] = {...(env['kdf'] as Map), 'memoryKiB': 4194304};
    await expectLater(
      BackupCrypto.open(Uint8List.fromList(utf8.encode(jsonEncode(env))), 'right passphrase'),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('does not support'))),
    );
  });

  test('a failed restore changes nothing', () async {
    final db = memoryDb();
    await seed(db, clock);
    final controls = DataControls(db, clock.call);
    final broken = jsonEncode({
      'format': 'reparc-export',
      'schemaVersion': 3,
      'tables': {
        'exercises': [
          {'id': 'x'},
        ],
      },
    });
    await expectLater(controls.importJson(broken), throwsA(anything));
    expect((await db.select(db.exercises).get()).single.name, 'Deadlift');
    await expectLater(
      controls.importJson(jsonEncode({'format': 'reparc-export', 'schemaVersion': 99})),
      throwsFormatException,
    );
    await db.close();
  });
}
