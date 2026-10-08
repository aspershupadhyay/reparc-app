import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// A local notification at the end of a rest, for a locked phone or an app
/// in the background (handbook 4.13). It is made on the phone; nothing is
/// sent out.
abstract class RestAlerts {
  /// Asks for permission to notify. Returns true when allowed.
  Future<bool> askPermission();

  /// Sets the one rest alert to fire at [at], in place of any earlier one.
  Future<void> schedule(DateTime at, {required String title, required String body});

  /// Removes the rest alert.
  Future<void> cancel();
}

class LocalRestAlerts implements RestAlerts {
  static const _id = 4130;
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  Future<bool> _init() => _ready ??= () async {
    tzdata.initializeTimeZones();
    final ok = await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is asked for in context, on the first guided rest.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    return ok ?? false;
  }();

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> askPermission() async {
    try {
      await _init();
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      }
      return await _android?.requestNotificationsPermission() ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> schedule(DateTime at, {required String title, required String body}) async {
    try {
      await _init();
      // Exact when Android allows it; else Android may deliver it a little late.
      final exact = await _android?.canScheduleExactNotifications() ?? true;
      await _plugin.zonedSchedule(
        id: _id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'rest',
            'Rest timer',
            channelDescription: 'Says when a rest in a guided workout is over',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            // The voice says it when the app is open.
            presentAlert: false,
            presentSound: false,
            presentBanner: false,
            presentList: false,
          ),
        ),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {
      // A rest alert that cannot be set must never stop the workout.
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _init();
      await _plugin.cancel(id: _id);
    } catch (_) {}
  }
}

final restAlertsProvider = Provider<RestAlerts>((ref) => LocalRestAlerts());
