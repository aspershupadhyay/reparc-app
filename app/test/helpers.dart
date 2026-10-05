import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:reparc/data/database.dart';

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

/// A controllable clock for tests.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
  void advance(Duration d) => now = now.add(d);
}
