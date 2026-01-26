import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/settings/providers/theme_providers.dart';
import 'package:trustguard/src/features/settings/services/theme_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User Flow: Create Group, Add Members, Add Expense, Verify UI', (
    tester,
  ) async {
    // 1. Setup mocks and providers
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    final prefs = await SharedPreferences.getInstance();

    // Use in-memory database for clean state
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(database),
        ],
        child: const TrustGuardApp(),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // 2. Dashboard displays
    expect(find.text('Your Overview'), findsOneWidget);

    // 3. Create new group
    await tester.tap(find.text('New Group'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Trip to Paris');
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    // 4. Navigate to group and add members
    expect(find.text('Trip to Paris'), findsOneWidget);
    await tester.tap(find.text('Trip to Paris'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    // Add Alice
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Alice');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Add Bob
    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Bob');
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Go back to group overview
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 5. Create expense
    // Scroll to see Quick Actions
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Expense'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note'),
      'Dinner',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Amount'), '30');

    // Select payer (Alice)
    await tester.tap(find.text('Alice').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    // 6. Verify expense and date header
    await tester.tap(find.text('Transactions'));
    await tester.pumpAndSettle();

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);

    // 7. Swipe to delete
    await tester.drag(find.text('Dinner'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Confirmation dialog
    expect(find.text('Delete Transaction'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Dinner'), findsNothing);

    // 8. Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Dinner'), findsOneWidget);

    // 9. Navigate to settlements
    await tester.pageBack(); // back to group overview
    await tester.pumpAndSettle();

    await tester.tap(find.text('Balances'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Other Settlements'), findsOneWidget);

    // 10. Change theme
    await tester.pageBack(); // back to Balances
    await tester.pumpAndSettle();
    await tester.pageBack(); // back to GroupOverview
    await tester.pumpAndSettle();
    await tester.pageBack(); // back to Home
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final themeState = ProviderScope.containerOf(
      tester.element(find.byType(TrustGuardApp)),
    ).read(themeStateProvider);
    expect(themeState.currentMode, ThemeModePreference.dark);
  });
}
