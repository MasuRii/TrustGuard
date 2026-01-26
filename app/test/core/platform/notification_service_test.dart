import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';

class MockFlutterLocalNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockAndroidFlutterLocalNotificationsPlugin extends Mock
    implements AndroidFlutterLocalNotificationsPlugin {}

class MockIOSFlutterLocalNotificationsPlugin extends Mock
    implements IOSFlutterLocalNotificationsPlugin {}

class InitializationSettingsFake extends Fake
    implements InitializationSettings {}

void main() {
  late NotificationService notificationService;
  late MockFlutterLocalNotificationsPlugin mockNotifications;
  late MockFlutterSecureStorage mockStorage;

  setUpAll(() {
    registerFallbackValue(InitializationSettingsFake());
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
  });

  group('NotificationService', () {
    test('init initializes the plugin', () async {
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
