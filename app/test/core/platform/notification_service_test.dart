import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/core/models/reminder_settings.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class InitializationSettingsFake extends Fake
    implements InitializationSettings {}

class NotificationDetailsFake extends Fake implements NotificationDetails {}

class TZDateTimeFake extends Fake implements tz.TZDateTime {}

void main() {
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockFlutterSecureStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(InitializationSettingsFake());
    registerFallbackValue(NotificationDetailsFake());
    registerFallbackValue(TZDateTimeFake());
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
    registerFallbackValue(DateTimeComponents.time);

    tz.initializeTimeZones();
  });

  setUp(() {
    mockNotifications = MockFlutterLocalNotificationsPlugin();
    mockStorage = MockFlutterSecureStorage();

    notificationService = NotificationService(mockNotifications, mockStorage);

    // Default mock behavior
    when(
      () => mockNotifications.initialize(
        any(),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);

    when(() => mockNotifications.cancel(any())).thenAnswer((_) async {});

    when(
      () => mockNotifications.zonedSchedule(
        any(),
        any(),
        any(),
        any(),
        any(),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  group('NotificationService', () {
    test('init initializes the plugin', () async {
      // Note: FlutterTimezone will likely fail in test env and fallback to UTC
      await notificationService.init();

      verify(
        () => mockNotifications.initialize(
          any(),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).called(1);
    });

    test('scheduleReminder calls zonedSchedule', () async {
      await notificationService.init(); // To set tz.local

      await notificationService.scheduleReminder(
        groupId: 'group1',
        title: 'Title',
        body: 'Body',
        schedule: ReminderSchedule.daily,
      );

      verify(
        () => mockNotifications.zonedSchedule(
          any(),
          'Title',
          'Body',
          any(),
          any(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'group1',
        ),
      ).called(1);
    });

    test('cancelReminder calls cancel', () async {
      await notificationService.cancelReminder('group1');

      verify(() => mockNotifications.cancel(any())).called(1);
    });

    test('isPermissionGranted returns true if storage says true', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => 'true');

      final result = await notificationService.isPermissionGranted();

      expect(result, isTrue);
    });

    test('isPermissionGranted returns false if storage is empty', () async {
      when(
        () => mockStorage.read(key: any(named: 'key')),
      ).thenAnswer((_) async => null);

      final result = await notificationService.isPermissionGranted();

      expect(result, isFalse);
    });
  });
}
