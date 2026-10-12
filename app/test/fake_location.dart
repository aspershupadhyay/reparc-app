import 'dart:async';

import 'package:reparc/activity/location_source.dart';
import 'package:reparc/domain/track.dart';

/// GPS in tests. Tests push fixes by hand.
class FakeLocation implements LocationSource {
  LocationAccess access = LocationAccess.allowed;
  StreamController<TrackPoint>? controller;
  int starts = 0;

  bool get on => controller != null && controller!.hasListener;

  @override
  Future<LocationAccess> ensureAccess() async => access;

  @override
  Stream<TrackPoint> fixes(ActivityKind kind) {
    starts++;
    controller = StreamController<TrackPoint>();
    return controller!.stream;
  }

  void add(TrackPoint p) => controller?.add(p);

  @override
  Future<void> openSettings() async {}
}
