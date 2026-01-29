import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/features/reminders/services/reminder_service.dart';
import 'package:trustguard/src/features/groups/presentation/home_screen.dart';
import 'package:trustguard/src/features/groups/presentation/group_overview_screen.dart';
import '../../helpers/shared_prefs_helper.dart';

class MockAppLockService extends Mock implements AppLockService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockReminderService extends Mock implements ReminderService {}

void main() {
  late MockAppLockService mockAppLock;
  late MockNotificationService mockNotifications;
  late MockReminderService mockReminders;

  setUp(() {
    mockAppLock = MockAppLockService();
    mockNotifications = MockNotificationService();
    mockReminders = MockReminderService();

    when(() => mockAppLock.isPinSet()).thenAnswer((_) async => false);
    when(() => mockAppLock.isBiometricEnabled()).thenAnswer((_) async => false);
    when(
      () => mockAppLock.isBiometricAvailable(),
    ).thenAnswer((_) async => false);
    when(
      () => mockAppLock.isRequireUnlockToExportEnabled(),
    ).thenAnswer((_) async => false);

    when(() => mockNotifications.init()).thenAnswer((_) async {});
    when(
      () => mockNotifications.isPermissionGranted(),
    ).thenAnswer((_) async => false);
    when(
      () => mockNotifications.getAppLaunchDetails(),
    ).thenAnswer((_) async => null);

    when(() => mockReminders.refreshAllReminders()).thenAnswer((_) async {});
  });

  Future<AppDatabase> setupApp(
    WidgetTester tester, {
    required bool onboardingComplete,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final prefsOverrides = await getSharedPrefsOverride(
      onboardingComplete: onboardingComplete,
    );

    // Create a group so we can navigate to it
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'group_1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          appLockServiceProvider.overrideWithValue(mockAppLock),
          notificationServiceProvider.overrideWithValue(mockNotifications),
          reminderServiceProvider.overrideWithValue(mockReminders),
          ...prefsOverrides,
        ],
        child: const TrustGuardApp(),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('trustguard://groups redirects to HomeScreen', (tester) async {
    final db = await setupApp(tester, onboardingComplete: true);

    final router =
        (tester.widget(find.byType(MaterialApp)) as MaterialApp).routerConfig
            as GoRouter;
    router.go('/groups');
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('trustguard://groups/:id redirects to GroupOverviewScreen', (
    tester,
  ) async {
    final db = await setupApp(tester, onboardingComplete: true);

    final router =
        (tester.widget(find.byType(MaterialApp)) as MaterialApp).routerConfig
            as GoRouter;
    router.go('/groups/group_1');
    await tester.pumpAndSettle();

    expect(find.text('Test Group'), findsOneWidget);
    expect(find.byType(GroupOverviewScreen), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
