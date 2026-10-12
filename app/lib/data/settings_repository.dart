import '../domain/guide.dart';
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
    this.liveSteps = false,
    this.onboarded = false,
    this.foodCountry,
    this.updatesAuto = true,
    this.updatesCheckedAt,
    this.updatesLatest,
    this.updatesDismissed,
    this.guideOn = true,
    this.voice = 'charlie',
    this.finishRepSets = true,
    this.autoStartSets = true,
    this.lockAlerts = true,
    this.restAlertAsked = false,
    this.cuesOff = const {},
    this.setSec,
    this.warmupSec,
    this.warmupRestSec,
    this.loadStyle = LoadStyle.same,
  });

  /// Guided workout: set and rest timers that run on their own (handbook
  /// 4.13). On unless the user turns it off.
  final bool guideOn;

  /// Voice for spoken cues: 'charlie', 'matilda', or 'off'.
  final String voice;

  /// End a rep set when its set time runs out, then start the rest. On by
  /// default, so a workout runs on its own (owner request 2026-10-08). Off:
  /// the user taps Set done. A timed set always ends on its time.
  final bool finishRepSets;

  /// Start the next set on its own when the rest ends, after a 3-2-1
  /// countdown. On by default. Off: the voice says the rest is over and the
  /// user starts the set.
  final bool autoStartSets;

  /// Time for each warm-up move done for reps, such as arm circles. Null
  /// means about 3 s a rep. A timed move, such as 5 min on the bike, keeps
  /// its own time.
  final int? warmupSec;

  /// Rest after the last warm-up move. Null means [defaultWarmupRestSec].
  /// There is no rest between warm-up moves.
  final int? warmupRestSec;

  /// Same weight each set, or a pyramid: more weight and fewer reps.
  final LoadStyle loadStyle;

  /// With the phone locked or the app in the background, the cues come as
  /// notifications that play the same voice clips.
  final bool lockAlerts;

  /// Cues the user turned off. All are on by default.
  final Set<Cue> cuesOff;

  /// Cues to say: every cue the user did not turn off.
  Set<Cue> get cues => {...Cue.values}..removeAll(cuesOff);

  /// The app asked for the notification permission once, on the first
  /// guided rest. It does not ask again; the phone's settings decide.
  final bool restAlertAsked;

  /// Set time for rep sets when [finishRepSets] is on. Null means an
  /// estimate from the reps (about 3 s a rep, 20–90 s).
  final int? setSec;

  final String loadUnit;
  final String distanceUnit;

  /// Rest between sets. Null means the plan's rest, else 90 s. A value
  /// the user picks is used for every rest between sets.
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

  /// Health types the user switched on in RepArc, by [HealthFeature] name.
  /// The operating system keeps its own permission state as well.
  final Set<String> health;

  /// When the user last saved an encrypted backup file.
  final DateTime? lastBackupAt;

  /// The user has seen the animated intro once.
  final bool introSeen;

  /// Count steps live with the phone's step sensor while RepArc is open,
  /// on top of the health store's total (handbook 9.5). Off by default; it
  /// needs the "Physical activity" (Android) or "Motion & Fitness"
  /// (iPhone) permission.
  final bool liveSteps;

  /// The first-run setup (goal, level, days) was finished or skipped.
  final bool onboarded;

  /// The country whose foods come first in food search ("IN"), or "ALL"
  /// for no country. Null follows the phone's region (handbook 5.10).
  final String? foodCountry;

  /// Check GitHub for a newer build once a day when the app opens (D-029).
  /// On unless the user turns it off in Me → App updates.
  final bool updatesAuto;

  /// When the last update check finished.
  final DateTime? updatesCheckedAt;

  /// The latest release seen by the last check, as JSON (ReleaseInfo).
  final String? updatesLatest;

  /// A version the user chose to hide from the Home notice.
  final String? updatesDismissed;

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
    liveSteps: m['liveSteps'] == 'true',
    onboarded: m['onboarded'] == 'true',
    foodCountry: m['food.country'],
    updatesAuto: m['updates.auto'] != 'false',
    updatesCheckedAt: DateTime.tryParse(m['updates.checkedAt'] ?? ''),
    updatesLatest: m['updates.latest'],
    updatesDismissed: m['updates.dismissed'],
    guideOn: m['guide.on'] != 'false',
    voice: const ['charlie', 'matilda', 'off'].contains(m['guide.voice']) ? m['guide.voice']! : 'charlie',
    finishRepSets: m['guide.finishReps'] != 'false',
    autoStartSets: m['guide.autoStart'] != 'false',
    lockAlerts: m['guide.restAlert'] != 'false',
    cuesOff: {
      for (final c in Cue.values)
        if (m['guide.cueOff.${c.name}'] == 'true') c,
    },
    restAlertAsked: m['guide.restAlertAsked'] == 'true',
    setSec: int.tryParse(m['guide.setSec'] ?? ''),
    warmupSec: int.tryParse(m['guide.warmupSec'] ?? ''),
    warmupRestSec: int.tryParse(m['guide.warmupRestSec'] ?? ''),
    loadStyle: m['guide.loadStyle'] == 'pyramid' ? LoadStyle.pyramid : LoadStyle.same,
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

  /// One stored value, or null.
  Future<String?> read(String key) async =>
      (await (db.select(db.settings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<void> setLoadUnit(String u) => set('loadUnit', u);
  Future<void> setDistanceUnit(String u) => set('distanceUnit', u);
  Future<void> setRestAfterSet(int? sec) => set('restAfterSetSec', sec?.toString());
  Future<void> setShowEnergy(bool v) => set('showEnergy', v.toString());
  Future<void> setStorageNoticeSeen() => set('storageNoticeSeen', 'true');
  Future<void> setThemeMode(String m) => set('themeMode', m);
  Future<void> setTargetsOn(bool v) => set('targetsOn', v.toString());
  Future<void> setUpdatesAuto(bool v) => set('updates.auto', v ? null : 'false');
  Future<void> setUpdatesDismissed(String? version) => set('updates.dismissed', version);
  Future<void> setUpdateResult({required DateTime at, String? latestJson}) => db.transaction(() async {
    await set('updates.checkedAt', at.toUtc().toIso8601String());
    if (latestJson != null) await set('updates.latest', latestJson);
  });
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
  Future<void> setLiveSteps(bool on) => set('liveSteps', on ? 'true' : null);
  Future<void> setOnboarded() => set('onboarded', 'true');
  Future<void> setFoodCountry(String? code) => set('food.country', code);
  Future<void> setGuideOn(bool v) => set('guide.on', v ? null : 'false');
  Future<void> setVoice(String v) => set('guide.voice', v);
  Future<void> setFinishRepSets(bool v) => set('guide.finishReps', v ? null : 'false');
  Future<void> setAutoStartSets(bool v) => set('guide.autoStart', v ? null : 'false');
  Future<void> setLockAlerts(bool v) => set('guide.restAlert', v ? null : 'false');
  Future<void> setCue(Cue c, bool on) => set('guide.cueOff.${c.name}', on ? null : 'true');
  Future<void> setRestAlertAsked() => set('guide.restAlertAsked', 'true');
  Future<void> setSetSec(int? sec) => set('guide.setSec', sec?.toString());
  Future<void> setWarmupSec(int? sec) => set('guide.warmupSec', sec?.toString());
  Future<void> setWarmupRestSec(int? sec) => set('guide.warmupRestSec', sec?.toString());
  Future<void> setLoadStyle(LoadStyle s) => set('guide.loadStyle', s == LoadStyle.same ? null : s.name);
}
