import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:trustguard/src/ui/components/balance_progress_bar.dart';
import 'package:trustguard/src/ui/components/speed_dial_fab.dart';
import 'package:trustguard/src/ui/components/haptic_slider.dart';
import 'package:trustguard/src/ui/animations/staggered_list_animation.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';
import 'package:trustguard/src/features/transactions/services/amount_suggestion_service.dart';

class MockAmountSuggestionService extends Mock
    implements AmountSuggestionService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('v1.4 Features Integration Test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));

    final db = AppDatabase(NativeDatabase.memory());
    final mockAmountSuggestions = MockAmountSuggestionService();
    final mockNotifications = MockNotificationService();
    final mockAppLock = MockAppLockService();

    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'theme_mode': 'light',
      'coachmarks_shown': '',
      'custom_keypad_enabled': false,
    });

    when(
      () => mockAmountSuggestions.getSuggestions(any()),
    ).thenAnswer((_) async => [1050, 2000, 5000]);
    when(() => mockNotifications.init()).thenAnswer((_) async {});
    when(
      () => mockNotifications.getAppLaunchDetails(),
    ).thenAnswer((_) async => null);
    when(() => mockAppLock.isPinSet()).thenAnswer((_) async => false);
    when(() => mockAppLock.isBiometricEnabled()).thenAnswer((_) async => false);
    when(
      () => mockAppLock.isRequireUnlockToExportEnabled(),
    ).thenAnswer((_) async => false);

    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          amountSuggestionServiceProvider.overrideWithValue(
            mockAmountSuggestions,
          ),
          notificationServiceProvider.overrideWithValue(mockNotifications),
          appLockServiceProvider.overrideWithValue(mockAppLock),
        ],
        child: const TrustGuardApp(),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Create Group
    await tester.tap(find.byType(SpeedDialFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New Group').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'V1.4 Group');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    // 2. Add Member
    await tester.tap(find.text('V1.4 Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Alice');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 3. Staggered Entrance
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();
    expect(find.byType(StaggeredListItem), findsWidgets);

    // 4. Speed Dial & Quick Add
    await tester.tap(find.text('V1.4 Group'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SpeedDialFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick Add').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Amount'),
      '10.50',
    );
    await tester.pump();
    final saveBtn = find.text('Save');
    await tester.ensureVisible(saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // 5. Balance ProgressBar
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    final balanceBtn = find.text('Balance').last;
    await tester.ensureVisible(balanceBtn);
    await tester.tap(balanceBtn);
    await tester.pumpAndSettle();
    expect(find.byType(BalanceProgressBar), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Transactions & Staggered Items
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.pump();
    expect(find.byType(StaggeredListItem), findsWidgets);

    // 7. Undo
    await tester.drag(
      find.byType(StaggeredListItem).first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // 8. Haptic Slider (via Add Expense)
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SpeedDialFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Expense').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '20');
    await tester.tap(find.text('Alice').first);
    await tester.pump();
    await tester.tap(find.text('Select All'));
    await tester.pump();

    final splitEquallyBtn = find.text('Split Equally');
    await tester.ensureVisible(splitEquallyBtn);
    await tester.tap(splitEquallyBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Split Customly').last);
    await tester.pumpAndSettle();
    expect(find.byType(HapticSlider), findsWidgets);

    await db.close();
  });
}
