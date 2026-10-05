import 'database.dart';
import 'models.dart';

/// User preferences. Stored on this phone only.
class AppSettings {
  const AppSettings({
    this.loadUnit = Units.kg,
    this.distanceUnit = Units.km,
    this.restAfterSetSec,
    this.showEnergy = true,
    this.storageNoticeSeen = false,
  });

  final String loadUnit;
  final String distanceUnit;

  /// Rest timer that starts after a completed set. Null means off.
  final int? restAfterSetSec;

  /// The user can hide calorie views (handbook 5.5).
  final bool showEnergy;

  /// The user read the phone-only storage notice.
  final bool storageNoticeSeen;

  static AppSettings fromMap(Map<String, String> m) => AppSettings(
    loadUnit: Units.loadUnits.contains(m['loadUnit']) ? m['loadUnit']! : Units.kg,
    distanceUnit: Units.distanceUnits.contains(m['distanceUnit']) ? m['distanceUnit']! : Units.km,
    restAfterSetSec: int.tryParse(m['restAfterSetSec'] ?? ''),
    showEnergy: m['showEnergy'] != 'false',
    storageNoticeSeen: m['storageNoticeSeen'] == 'true',
  );
}

class SettingsRepository {
  SettingsRepository(this.db);
  final AppDatabase db;

  Stream<AppSettings> watch() => db
      .select(db.settings)
      .watch()
      .map(
        (rows) => AppSettings.fromMap({for (final r in rows) r.key: r.value}),
      );

  Future<void> set(String key, String? value) async {
    if (value == null) {
      await (db.delete(db.settings)..where((s) => s.key.equals(key))).go();
    } else {
      await db.into(db.settings).insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));
    }
  }

  Future<void> setLoadUnit(String u) => set('loadUnit', u);
  Future<void> setDistanceUnit(String u) => set('distanceUnit', u);
  Future<void> setRestAfterSet(int? sec) => set('restAfterSetSec', sec?.toString());
  Future<void> setShowEnergy(bool v) => set('showEnergy', v.toString());
  Future<void> setStorageNoticeSeen() => set('storageNoticeSeen', 'true');
}
