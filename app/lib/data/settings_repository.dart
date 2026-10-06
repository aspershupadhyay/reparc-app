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
    this.aiScopes = const {},
    this.health = const {},
    this.lastBackupAt,
    this.introSeen = false,
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

  /// Data categories an AI client may use: gym, meal, health, plans.
  /// Each is a separate choice and all start off (handbook 10.5).
  final Set<String> aiScopes;

  /// Health types the user switched on in Reparc, by [HealthFeature] name.
  /// The operating system keeps its own permission state as well.
  final Set<String> health;

  /// When the user last saved an encrypted backup file.
  final DateTime? lastBackupAt;

  /// The user has seen the animated intro once.
  final bool introSeen;

  bool aiAllows(String? scope) => scope == null || aiScopes.contains(scope);

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
    aiScopes: {
      for (final k in aiScopeNames)
        if (m['ai.scope.$k'] == 'true') k,
    },
    health: {
      for (final e in m.entries)
        if (e.key.startsWith('health.') && e.value == 'true') e.key.substring('health.'.length),
    },
    lastBackupAt: DateTime.tryParse(m['backup.lastAt'] ?? ''),
    introSeen: m['introSeen'] == 'true',
  );
}

/// AI data scopes, in display order. Names match assets/mcp/tools.json.
const aiScopeNames = ['gym', 'meal', 'health', 'plans'];

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
  Future<void> setAiScope(String scope, bool on) => set('ai.scope.$scope', on ? 'true' : null);

  /// Switches a health feature. Write features remember when they were
  /// switched on, so only records saved after that are written.
  Future<void> setHealth(String feature, bool on, {DateTime? now}) async {
    await set('health.$feature', on ? 'true' : null);
    await set('healthSince.$feature', on ? (now ?? DateTime.now()).toUtc().toIso8601String() : null);
  }

  Future<DateTime?> healthSince(String feature) async {
    final row = await (db.select(db.settings)..where((s) => s.key.equals('healthSince.$feature'))).getSingleOrNull();
    return row == null ? null : DateTime.tryParse(row.value);
  }

  Future<void> setLastBackupAt(DateTime at) => set('backup.lastAt', at.toUtc().toIso8601String());
  Future<void> setIntroSeen() => set('introSeen', 'true');
}
