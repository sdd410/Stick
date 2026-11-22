import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../controller/stick_controller.dart';
import '../data/repository.dart';
import '../domain/reminder_planner.dart';

/// Daily local reminders. Inexact only: no exact-alarm permission is declared.
class NotificationService implements ReminderSink {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'daily',
      'Daily reminder',
      channelDescription: 'Your daily nudge to show up',
      importance: Importance.defaultImportance,
    ),
  );

  /// [onTap] gets the payload of a tapped notification (null for plain ones).
  Future<void> init(void Function(String? payload) onTap) async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint('Timezone lookup failed, using UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
  }

  /// Payload of the notification that launched the app, if any.
  Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    if (d == null || !d.didNotificationLaunchApp) return null;
    return d.notificationResponse?.payload;
  }

  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async {
    await _plugin.cancelAll();
    if (s == null) return;
    for (final r in planReminders(s, now)) {
      await _plugin.zonedSchedule(
        id: r.id,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime(
          tz.local,
          r.at.year,
          r.at.month,
          r.at.day,
          r.at.hour,
          r.at.minute,
        ),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: r.payload,
      );
    }
  }

  @override
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    // Null means Android before 13: nothing to ask, so treat it as granted.
    return await android?.requestNotificationsPermission() ?? true;
  }
}
