import 'package:reparc/health/health_service.dart';

/// In-memory health store for tests. Synthetic values only.
class FakeHealth implements HealthSource {
  Map<String, int> steps = {};
  Map<String, double> energy = {};
  WeightReading? weight;
  HealthAvailability state = HealthAvailability.available;
  final requested = <HealthFeature>[];
  final workouts = <String>[];
  final meals = <String>[];

  @override
  String get platformName => 'Test Health';

  @override
  Future<HealthAvailability> availability() async => state;

  @override
  Future<bool> request(HealthFeature feature) async {
    requested.add(feature);
    return true;
  }

  @override
  Future<void> install() async {}

  @override
  Future<Map<String, int>> dailySteps(DateTime fromDay, DateTime toDay) async => steps;

  @override
  Future<Map<String, double>> dailyActiveEnergy(DateTime fromDay, DateTime toDay) async => energy;

  @override
  Future<WeightReading?> latestWeight(DateTime until) async => weight;

  @override
  Future<bool> writeWorkout({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
  }) async {
    workouts.add(id);
    return true;
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
    meals.add(id);
    return true;
  }
}
