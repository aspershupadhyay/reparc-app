import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health/health.dart';

/// One health feature the user can switch on by itself (handbook 9.2).
///
/// Each feature names one data type, whether RepArc reads or writes it, and
/// why. RepArc asks the operating system for that type only when the user
/// switches the feature on. Heart rate, sleep, location, and clinical records
/// are not requested (handbook 9.3).
enum HealthFeature {
  steps(
    'Steps',
    'Read',
    'Shows today\'s steps on Home and in your AI summary.',
    HealthDataType.STEPS,
    HealthDataAccess.READ,
  ),
  activeEnergy(
    'Active energy',
    'Read',
    'Shows energy burned through activity next to the energy you ate.',
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataAccess.READ,
  ),
  weight(
    'Body weight',
    'Read',
    'Shows your latest weight so meal targets can use it. RepArc does not write weight.',
    HealthDataType.WEIGHT,
    HealthDataAccess.READ,
  ),
  writeWorkouts(
    'Workouts',
    'Write',
    'Saves each finished RepArc workout as a strength training workout, with its start and end time.',
    HealthDataType.WORKOUT,
    HealthDataAccess.WRITE,
  ),
  writeMeals(
    'Nutrition',
    'Write',
    'Saves meals you mark as eaten with their energy, protein, carbohydrate, and fat values.',
    HealthDataType.NUTRITION,
    HealthDataAccess.WRITE,
  );

  const HealthFeature(this.label, this.access, this.purpose, this.type, this.permission);

  final String label;

  /// 'Read' or 'Write', shown to the user before the system sheet opens.
  final String access;
  final String purpose;
  final HealthDataType type;
  final HealthDataAccess permission;

  bool get writes => permission == HealthDataAccess.WRITE;
}

enum HealthAvailability {
  /// Apple Health or Health Connect can be used.
  available,

  /// Android: Health Connect must be installed or updated first.
  needsInstall,

  /// This device has no supported health store (for example an iPad or an
  /// old Android version).
  unsupported,
}

/// A body weight reading with its source and time (handbook 9.5).
class WeightReading {
  const WeightReading(this.kg, this.at, this.source);
  final double kg;
  final DateTime at;
  final String source;
}

/// Access to Apple Health or Health Connect.
///
/// The app reads health values when it needs them and does not copy them
/// into its database. An empty answer never means the user denied access:
/// Apple does not tell apps about denied read access (handbook 9.4).
abstract class HealthSource {
  String get platformName;
  Future<HealthAvailability> availability();

  /// Opens the system permission sheet for one feature. True if the
  /// request finished; this does not prove that read access was granted.
  Future<bool> request(HealthFeature feature);

  /// Opens the platform's install page (Android) when Health Connect is missing.
  Future<void> install();

  /// Steps per local day, keyed yyyy-MM-dd. A missing key means no data.
  Future<Map<String, int>> dailySteps(DateTime fromDay, DateTime toDay);

  /// Active energy per local day in kcal.
  Future<Map<String, double>> dailyActiveEnergy(DateTime fromDay, DateTime toDay);

  /// Latest weight on or before [until], within the last 90 days.
  Future<WeightReading?> latestWeight(DateTime until);

  Future<bool> writeWorkout({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
  });

  Future<bool> writeMeal({
    required String id,
    required String name,
    required String? slotKind,
    required DateTime at,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  });
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The real platform stores through the `health` package.
class PlatformHealth implements HealthSource {
  PlatformHealth();

  final Health _health = Health();
  bool _configured = false;

  Future<void> _ready() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  String get platformName => Platform.isIOS ? 'Apple Health' : 'Health Connect';

  @override
  Future<HealthAvailability> availability() async {
    if (!Platform.isIOS && !Platform.isAndroid) return HealthAvailability.unsupported;
    try {
      await _ready();
      if (Platform.isIOS) return HealthAvailability.available;
      final status = await _health.getHealthConnectSdkStatus();
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired => HealthAvailability.needsInstall,
        _ => HealthAvailability.unsupported,
      };
    } catch (_) {
      return HealthAvailability.unsupported;
    }
  }

  @override
  Future<void> install() async {
    await _ready();
    await _health.installHealthConnect();
  }

  @override
  Future<bool> request(HealthFeature feature) async {
    await _ready();
    return _health.requestAuthorization([feature.type], permissions: [feature.permission]);
  }

  Future<List<HealthDataPoint>> _points(HealthDataType type, DateTime fromDay, DateTime toDay) async {
    await _ready();
    final end = DateTime(toDay.year, toDay.month, toDay.day + 1);
    // The plugin already removes duplicate points.
    return _health.getHealthDataFromTypes(types: [type], startTime: fromDay, endTime: end);
  }

  @override
  Future<Map<String, int>> dailySteps(DateTime fromDay, DateTime toDay) async {
    await _ready();
    final out = <String, int>{};
    // Per-day totals from the platform avoid double counting between sources.
    for (var d = fromDay; !d.isAfter(toDay); d = DateTime(d.year, d.month, d.day + 1)) {
      final n = await _health.getTotalStepsInInterval(d, DateTime(d.year, d.month, d.day + 1));
      if (n != null) out[_day(d)] = n;
    }
    return out;
  }

  @override
  Future<Map<String, double>> dailyActiveEnergy(DateTime fromDay, DateTime toDay) async {
    final out = <String, double>{};
    for (final p in await _points(HealthDataType.ACTIVE_ENERGY_BURNED, fromDay, toDay)) {
      final v = p.value;
      if (v is! NumericHealthValue) continue;
      final key = _day(p.dateFrom.toLocal());
      out[key] = (out[key] ?? 0) + v.numericValue.toDouble();
    }
    return out;
  }

  @override
  Future<WeightReading?> latestWeight(DateTime until) async {
    final from = DateTime(until.year, until.month, until.day - 90);
    final points = await _points(HealthDataType.WEIGHT, from, until);
    points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
    for (final p in points) {
      final v = p.value;
      if (v is NumericHealthValue) return WeightReading(v.numericValue.toDouble(), p.dateFrom, p.sourceName);
    }
    return null;
  }

  @override
  Future<bool> writeWorkout({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    await _ready();
    return _health.writeWorkoutData(
      activityType: Platform.isIOS
          ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
          : HealthWorkoutActivityType.STRENGTH_TRAINING,
      start: start,
      end: end,
      title: title,
      recordingMethod: RecordingMethod.manual,
    );
  }

  @override
  Future<bool> writeMeal({
    required String id,
    required String name,
    required String? slotKind,
    required DateTime at,
    double? energyKcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) async {
    await _ready();
    return _health.writeMeal(
      mealType: switch (slotKind) {
        'breakfast' => MealType.BREAKFAST,
        'lunch' => MealType.LUNCH,
        'dinner' => MealType.DINNER,
        'snack' => MealType.SNACK,
        _ => MealType.UNKNOWN,
      },
      startTime: at,
      endTime: at.add(const Duration(minutes: 1)),
      clientRecordId: id,
      caloriesConsumed: energyKcal,
      protein: proteinG,
      carbohydrates: carbsG,
      fatTotal: fatG,
      name: name,
    );
  }
}

/// The health store. Tests override it with a fake.
final healthSourceProvider = Provider<HealthSource>((ref) => PlatformHealth());
