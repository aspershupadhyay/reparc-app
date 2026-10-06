import '../domain/targets.dart';
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
    this.themeMode = 'system',
    this.profile = const Profile(),
    this.targetsOn = false,
    this.mealHidden = const {},
  });

  final String loadUnit;
  final String distanceUnit;

  /// Rest timer that starts after a completed set. Null means off.
  final int? restAfterSetSec;

  /// The user can hide calorie views (handbook 5.5).
  final bool showEnergy;

  /// The user read the phone-only storage notice.
  final bool storageNoticeSeen;

  /// 'system', 'light', or 'dark'.
  final String themeMode;

  /// What the user told the app about themselves (Me → Body and goals).
  final Profile profile;

  /// The user chose to see daily targets (handbook 5.5: never by default).
  final bool targetsOn;

  /// Nutrients the user hid from the Meal summary. Empty shows all.
  final Set<String> mealHidden;

  /// Targets for today, or empty when the user has not turned them on.
  List<Target> get targets => targetsOn ? dailyTargets(profile) : const [];

  static AppSettings fromMap(Map<String, String> m) => AppSettings(
    loadUnit: Units.loadUnits.contains(m['loadUnit']) ? m['loadUnit']! : Units.kg,
    distanceUnit: Units.distanceUnits.contains(m['distanceUnit']) ? m['distanceUnit']! : Units.km,
    restAfterSetSec: int.tryParse(m['restAfterSetSec'] ?? ''),
    showEnergy: m['showEnergy'] != 'false',
    storageNoticeSeen: m['storageNoticeSeen'] == 'true',
    themeMode: const ['light', 'dark'].contains(m['themeMode']) ? m['themeMode']! : 'system',
    profile: Profile.fromMap({
      for (final e in m.entries)
        if (e.key.startsWith('profile.')) e.key.substring(8): e.value,
    }),
    targetsOn: m['targetsOn'] == 'true',
    mealHidden: {...?m['mealHidden']?.split(',').where((x) => x.isNotEmpty)},
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
  Future<void> setThemeMode(String m) => set('themeMode', m);
  Future<void> setTargetsOn(bool v) => set('targetsOn', v.toString());
  Future<void> setMealHidden(Set<String> hidden) => set('mealHidden', hidden.isEmpty ? null : hidden.join(','));

  Future<void> setProfile(Profile p) => db.transaction(() async {
    for (final e in p.toMap().entries) {
      await set('profile.${e.key}', e.value);
    }
  });
}
