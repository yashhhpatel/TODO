import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../core/app_config.dart';

/// Local notifications for the daily streak / coin reward reminder.
///
/// The reminder is scheduled through AlarmManager, so it fires even when the
/// app is closed or in the background. Exactly one reminder is pending at a
/// time and it targets the next un-claimed day, so it is never sent twice or
/// unnecessarily.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _dailyId = 1001;

  // Flip to true for a one-off on-device self-test (fires immediately).
  static const bool _selfTest = false;

  Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // Fall back to whatever the timezone package defaults to.
      }
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      await _plugin.initialize(const InitializationSettings(android: android));
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
      if (_selfTest) {
        await _plugin.show(9999, 'Claim Your Coins! 🎁',
            'Keep your streak going and claim your daily coin reward.',
            _details());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Notification init failed: $e');
    }
  }

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reward',
          'Daily Rewards',
          channelDescription: 'Reminders to claim your daily coin reward',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );

  /// (Re)schedules the daily reminder, or cancels it when disabled. If the
  /// reward was already claimed today, the reminder is moved to tomorrow.
  Future<void> scheduleDailyReminder({
    required bool enabled,
    required bool claimedToday,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_dailyId);
      if (!enabled) return;

      final now = tz.TZDateTime.now(tz.local);
      var when = tz.TZDateTime(tz.local, now.year, now.month, now.day,
          AppConfig.dailyReminderHour, AppConfig.dailyReminderMinute);
      // Already claimed today, or today's slot has passed -> aim for tomorrow.
      if (claimedToday || !when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }

      await _plugin.zonedSchedule(
        _dailyId,
        'Claim Your Coins! 🎁',
        'Keep your streak going and claim your daily coin reward.',
        when,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('scheduleDailyReminder failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (_ready) await _plugin.cancelAll();
  }
}
