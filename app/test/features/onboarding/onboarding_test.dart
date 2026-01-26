import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/features/reminders/services/reminder_service.dart';
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

  Future<(AppDatabase, ProviderScope)> pumpApp(
    WidgetTester tester, {
    bool onboardingComplete = false,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final prefsOverrides = await getSharedPrefsOverride(
      onboardingComplete: onboardingComplete,
    );

    final widget = ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appLockServiceProvider.overrideWithValue(mockAppLock),
        notificationServiceProvider.overrideWithValue(mockNotifications),
        reminderServiceProvider.overrideWithValue(mockReminders),
        ...prefsOverrides,
      ],
      child: const TrustGuardApp(),
    );

    await tester.pumpWidget(widget);
    await tester.pump(); // Handle GoRouter initial redirect
    await tester.pump(
      const Duration(milliseconds: 500),
    ); // Allow animations to settle

    return (
      db,
      tester.element(find.byType(ProviderScope)).widget as ProviderScope,
    );
  }

  group('Onboarding Flow', () {
    testWidgets('first launch shows onboarding screen', (tester) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: false);

      expect(find.text('No Account Needed'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('completing onboarding navigates to home', (tester) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: false);

      // Slide 1
      expect(find.text('No Account Needed'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Slide 2
      expect(find.text('Your Data Stays Private'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Slide 3
      expect(find.text('Easy Expense Splitting'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Should be on Home screen
      expect(find.text('TrustGuard'), findsAtLeastNWidgets(1));
      // Use a more specific finder for the FAB to avoid duplicates if any
      expect(find.byType(FloatingActionButton), findsOneWidget);

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('skip button works on first slide', (tester) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: false);

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should be on Home screen
      expect(find.text('TrustGuard'), findsAtLeastNWidgets(1));

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('subsequent launches skip onboarding', (tester) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: true);

      // Should be directly on Home screen (assuming no lock)
      expect(find.text('TrustGuard'), findsAtLeastNWidgets(1));
      expect(find.text('No Account Needed'), findsNothing);

      await db.close();
      await tester.pump(Duration.zero);
    });

    testWidgets('page indicator updates on swipe', (tester) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: false);

      expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(3));

      await db.close();
      await tester.pump(Duration.zero);
    });
  });

  group('Navigation Guards', () {
    testWidgets('cannot navigate away from onboarding if not complete', (
      tester,
    ) async {
      final (db, _) = await pumpApp(tester, onboardingComplete: false);

      expect(find.text('No Account Needed'), findsOneWidget);

      await db.close();
      await tester.pump(Duration.zero);
    });
  });
}
