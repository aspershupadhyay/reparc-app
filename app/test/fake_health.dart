import 'dart:async';

import 'package:reparc/domain/track.dart';
import 'package:reparc/health/health_service.dart';
import 'package:reparc/health/live_steps.dart';

/// In-memory health store for tests. Synthetic values only.
class FakeHealth implements HealthSource {
  Map<String, int> steps = {};
  Map<String, double> energy = {};
  Map<String, double> distance = {};
  WeightReading? weight;
  HealthAvailability state = HealthAvailability.available;
  final requested = <HealthFeature>[];
  final workouts = <String>[];
  final activities = <String, ActivityKind>{};
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
  Future<Map<String, double>> dailyDistance(DateTime fromDay, DateTime toDay) async => distance;

  @override
  Future<WeightReading?> latestWeight(DateTime until) async => weight;

  @override
  Future<bool> writeWorkout({
    required String id,
    required String title,
    required DateTime start,
    required DateTime end,
    ActivityKind? activity,
  }) async {
    workouts.add(id);
    if (activity != null) activities[id] = activity;
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

/// The phone's step sensor in tests. Tests push counts by hand.
class FakeStepSensor implements StepSensor {
  final controller = StreamController<int>.broadcast();
  bool allow = true;
  int listens = 0;

  @override
  Future<bool> request() async => allow;

  @override
  Stream<int> counts() {
    listens++;
    return controller.stream;
  }
}

/// Activity recognition in tests.
class FakeMotion implements MotionSource {
  final controller = StreamController<Motion>.broadcast();

  @override
  Stream<Motion> motion() => controller.stream;
}
