import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/track.dart';

/// What the phone allows for location.
enum LocationAccess {
  /// Location can be used while RepArc is in use, which covers a recording
  /// that started on screen and goes on with the screen off.
  allowed,

  /// The user said no this time. The app can ask again.
  denied,

  /// The user said "Don't ask again". Only the phone's settings can change it.
  deniedForever,

  /// Location is switched off for the whole phone.
  serviceOff,
}

/// The phone's GPS (handbook 4.14). Tests use a fake.
abstract class LocationSource {
  /// Checks, and asks if needed, for location while the app is in use.
  /// RepArc never asks for "Allow all the time".
  Future<LocationAccess> ensureAccess();

  /// Fixes as they come, about one a second, while listened to. On Android
  /// a notification shows the whole time, so the recording goes on with the
  /// screen off or in another app.
  Stream<TrackPoint> fixes(ActivityKind kind);

  Future<void> openSettings();
}

class PlatformLocationSource implements LocationSource {
  @override
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return switch (p) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.allowed,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  @override
  Stream<TrackPoint> fixes(ActivityKind kind) {
    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        // Every fix: the filters in track.dart decide what counts.
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'Recording your ${kind.label.toLowerCase()}',
          notificationText: 'RepArc is using GPS. Open the app to pause or finish.',
          notificationChannelName: 'Activity recording',
          notificationIcon: const AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
          setOngoing: true,
          enableWakeLock: true,
          color: const Color(0xFFC6F24E),
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: kind == ActivityKind.ride ? ActivityType.otherNavigation : ActivityType.fitness,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        // The blue indicator tells the user that GPS is on.
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.best);
    }
    return Geolocator.getPositionStream(locationSettings: settings).map(
      (p) => TrackPoint(
        at: p.timestamp.toUtc(),
        lat: p.latitude,
        lon: p.longitude,
        accuracy: p.accuracy,
        altitude: p.altitudeAccuracy > 0 || p.altitude != 0 ? p.altitude : null,
        altitudeAccuracy: p.altitudeAccuracy > 0 ? p.altitudeAccuracy : null,
      ),
    );
  }

  @override
  Future<void> openSettings() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}

final locationSourceProvider = Provider<LocationSource>((ref) => PlatformLocationSource());
