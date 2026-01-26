import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/reminder_settings.dart';

/// Service for handling local notifications and permissions.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final FlutterSecureStorage _storage;

  static const _permissionKey = 'notification_permission_granted';

  /// Callback for notification taps.
  void Function(String?)? onNotificationTap;

  NotificationService(this._notifications, this._storage);

  /// Initializes the notification plugin.
  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final identifier = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(identifier));
    } catch (_) {
      // Fallback to UTC if timezone cannot be determined (e.g., in tests)
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        onNotificationTap?.call(details.payload);
      },
    );
  }

  /// Schedules a reminder notification for a group.
  Future<void> scheduleReminder({
    required String groupId,
    required String title,
    required String body,
    required ReminderSchedule schedule,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    // Set default time to 10:00 AM
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      10,
    );

    // If it's already past 10 AM, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'group_reminders',
      'Group Reminders',
      channelDescription: 'Notifications for outstanding group balances',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    DateTimeComponents matchComponents;
    switch (schedule) {
      case ReminderSchedule.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case ReminderSchedule.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case ReminderSchedule.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
    }

    await _notifications.zonedSchedule(
      id: groupId.hashCode.abs(),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
      payload: groupId,
    );
  }

  /// Cancels a reminder notification for a group.
  Future<void> cancelReminder(String groupId) async {
    await _notifications.cancel(id: groupId.hashCode.abs());
  }

  /// Gets the details of the notification that launched the app.
  Future<NotificationAppLaunchDetails?> getAppLaunchDetails() {
    return _notifications.getNotificationAppLaunchDetails();
  }

  /// Requests notification permissions from the user.
  Future<bool> requestPermissions() async {
    bool granted = false;

    if (Platform.isIOS) {
      granted =
          await _notifications
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } else if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      granted =
          await androidImplementation?.requestNotificationsPermission() ??
          false;
    }

    await _storage.write(key: _permissionKey, value: granted.toString());
    return granted;
  }

  /// Checks if notification permissions are currently granted.
  Future<bool> isPermissionGranted() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }

    // For iOS, we rely on the stored value or a re-request if needed.
    // Ideally, we'd use a permission handler package for a more robust check.
    final storedValue = await _storage.read(key: _permissionKey);
    return storedValue == 'true';
  }
}
