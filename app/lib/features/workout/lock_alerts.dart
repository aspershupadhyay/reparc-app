import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// One spoken cue for a locked phone: a notification at [at] that plays the
/// voice [clip], such as "Three" or "Rest is up".
class AlertCue {
  const AlertCue({required this.at, required this.clip, required this.title, required this.body, this.brief = false});
  final DateTime at;
  final String clip;
  final String title;
  final String body;

  /// A countdown word or a mid-way cue. It leaves the screen after a few
  /// seconds, so the lock screen does not fill up.
  final bool brief;
}

/// The live card on the Android lock screen: a silent, ongoing notification
/// with a clock that counts down to [countdownTo] or up from [countUpFrom].
class LiveCard {
  const LiveCard({required this.title, required this.body, this.countdownTo, this.countUpFrom});
  final String title;
  final String body;
  final DateTime? countdownTo;
  final DateTime? countUpFrom;
}

/// Cues and a live card for a locked phone or an app in the background
/// (handbook 4.13). Everything is made on the phone; nothing is sent out.
abstract class LockAlerts {
  /// Asks for permission to notify. Returns true when allowed.
  Future<bool> askPermission();

  /// True when Android lets alerts fire on the second. Always true on iPhone.
  Future<bool> onTime();

  /// Opens Android's "Alarms & reminders" setting for this app.
  Future<void> askOnTime();

  /// Replaces any cues and card with these. [voice] is 'charlie',
  /// 'matilda', or 'off' (the phone's own alert sound).
  Future<void> show(List<AlertCue> cues, {required String voice, LiveCard? card});

  /// Removes every cue, waiting or shown, and the live card.
  Future<void> clear();
}

class LocalLockAlerts implements LockAlerts {
  static const _cardId = 4100;
  static const _firstCueId = 4101;
  static const _group = 'reparc-workout';
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _ready;

  bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

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
    if (_ios) await _copySounds();
    return ok ?? false;
  }();

  /// iOS plays a notification sound from the app's Library/Sounds folder,
  /// so the voice clips are copied there once.
  Future<void> _copySounds() async {
    try {
      final dir = Directory('${(await getLibraryDirectory()).path}/Sounds');
      await dir.create(recursive: true);
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      for (final a in manifest.listAssets().where((a) => a.startsWith('assets/voice/alerts/'))) {
        final file = File('${dir.path}/${a.split('/').last}');
        if (await file.exists()) continue;
        final data = await rootBundle.load(a);
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
    } catch (_) {
      // Without the files, iOS plays its own alert sound.
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> askPermission() async {
    try {
      await _init();
      if (_ios) {
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
  Future<bool> onTime() async {
    try {
      await _init();
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> askOnTime() async {
    try {
      await _init();
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  @override
  Future<void> show(List<AlertCue> cues, {required String voice, LiveCard? card}) async {
    try {
      await _init();
      await _plugin.cancelAll();
      if (card != null && !_ios) await _showCard(card);
      final exact = await onTime();
      var id = _firstCueId;
      for (final c in cues) {
        await _plugin.zonedSchedule(
          id: id++,
          title: c.title,
          body: c.body,
          scheduledDate: tz.TZDateTime.from(c.at.toUtc(), tz.UTC),
          notificationDetails: _details(c, voice),
          androidScheduleMode: exact
              ? AndroidScheduleMode.exactAllowWhileIdle
              : AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    } catch (_) {
      // An alert that cannot be set must never stop the workout.
    }
  }

  NotificationDetails _details(AlertCue c, String voice) {
    final spoken = voice != 'off';
    // Android fixes a channel's sound when it is made, so each voice clip
    // has its own channel.
    final channel = spoken ? 'cue_${voice}_${c.clip}' : 'cue_plain';
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        spoken ? 'Voice: ${_names[c.clip] ?? c.clip} (${voice[0].toUpperCase()}${voice.substring(1)})' : 'Workout cues',
        channelDescription: 'Spoken workout cues while the phone is locked',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        sound: spoken ? RawResourceAndroidNotificationSound('voice_${voice}_${c.clip}') : null,
        enableVibration: !c.brief,
        groupKey: _group,
        visibility: NotificationVisibility.public,
        timeoutAfter: c.brief ? 4000 : 120000,
      ),
      iOS: DarwinNotificationDetails(
        sound: spoken ? '${voice}_${c.clip}.caf' : null,
        threadIdentifier: _group,
        // The app shows and says the cue itself while it is open.
        presentAlert: false,
        presentSound: false,
        presentBanner: false,
        presentList: false,
      ),
    );
  }

  Future<void> _showCard(LiveCard card) => _plugin.show(
    id: _cardId,
    title: card.title,
    body: card.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'workout_live',
        'Workout in progress',
        channelDescription: 'A quiet card with the rest or set clock on the lock screen',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        silent: true,
        onlyAlertOnce: true,
        showWhen: true,
        when: (card.countdownTo ?? card.countUpFrom)?.millisecondsSinceEpoch,
        usesChronometer: card.countdownTo != null || card.countUpFrom != null,
        chronometerCountDown: card.countdownTo != null,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.workout,
        groupKey: _group,
      ),
    ),
  );

  @override
  Future<void> clear() async {
    try {
      await _init();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static const _names = {
    'halfway': 'Halfway',
    'ten_left': 'Ten seconds',
    'three': 'Three',
    'two': 'Two',
    'one': 'One',
    'time': 'Time',
    'rest_over': 'Rest is up',
  };
}

final lockAlertsProvider = Provider<LockAlerts>((ref) => LocalLockAlerts());
