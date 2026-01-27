import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/settings/presentation/settings_screen.dart';
import 'package:trustguard/src/features/settings/providers/lock_providers.dart';
import 'package:trustguard/src/features/settings/providers/notification_providers.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import '../../../helpers/localization_helper.dart';

class MockAppLockService extends Mock implements AppLockService {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockAppLockService mockLockService;
  late MockNotificationService mockNotificationService;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    mockLockService = MockAppLockService();
    mockNotificationService = MockNotificationService();

    when(() => mockLockService.isPinSet()).thenAnswer((_) async => false);
    when(
      () => mockLockService.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockLockService.setBiometricEnabled(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockLockService.isRequireUnlockToExportEnabled(),
    ).thenAnswer((_) async => false);
    when(
      () => mockLockService.setRequireUnlockToExportEnabled(any()),
    ).thenAnswer((_) async {});
    when(() => mockLockService.removePin()).thenAnswer((_) async {});

    when(
      () => mockNotificationService.isPermissionGranted(),
    ).thenAnswer((_) async => false);
    when(
      () => mockNotificationService.requestPermissions(),
    ).thenAnswer((_) async => true);
    when(() => mockNotificationService.init()).thenAnswer((_) async {});
  });

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: wrapWithLocalization(const SettingsScreen()),
    );
  }

  testWidgets('renders settings screen correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appLockServiceProvider.overrideWithValue(mockLockService),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Display'), findsOneWidget);
    expect(find.text('Rounding'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Set PIN'), findsOneWidget);

    // Scroll to find Notifications
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Enable Reminders'), findsOneWidget);

    // Scroll to find Data
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Data'), findsOneWidget);

    // Scroll to bottom to find 'About'
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('shows change pin when pin is set', (tester) async {
    when(() => mockLockService.isPinSet()).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appLockServiceProvider.overrideWithValue(mockLockService),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appLockStateProvider.notifier).init();
    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    expect(find.text('Change PIN'), findsOneWidget);
    expect(find.text('Biometric Unlock'), findsOneWidget);

    // Scroll to find other items
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Export Protection'), findsOneWidget);
    expect(find.text('Remove PIN'), findsOneWidget);
  });

  testWidgets('toggling biometric unlock updates state', (tester) async {
    when(() => mockLockService.isPinSet()).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appLockServiceProvider.overrideWithValue(mockLockService),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appLockStateProvider.notifier).init();
    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Biometric Unlock',
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    verify(() => mockLockService.setBiometricEnabled(true)).called(1);
    expect(container.read(appLockStateProvider).isBiometricEnabled, true);
  });

  testWidgets('toggling notifications requests permission', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appLockServiceProvider.overrideWithValue(mockLockService),
        notificationServiceProvider.overrideWithValue(mockNotificationService),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.pumpAndSettle();

    // Scroll to find Notifications
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    final switchFinder = find.widgetWithText(
      SwitchListTile,
      'Enable Reminders',
    );
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    verify(() => mockNotificationService.requestPermissions()).called(1);
    expect(container.read(notificationPermissionProvider), true);
  });
}
