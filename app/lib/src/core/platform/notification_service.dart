import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for handling local notifications and permissions.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications;
  final FlutterSecureStorage _storage;

  static const _permissionKey = 'notification_permission_granted';

  NotificationService(this._notifications, this._storage);

  /// Initializes the notification plugin.
  Future<void> init() async {
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
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap - to be expanded in 4.3.3
      },
    );
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
