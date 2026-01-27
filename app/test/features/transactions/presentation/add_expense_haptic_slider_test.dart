import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/transactions/presentation/add_expense_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> setupGroupAndMembers(String groupId) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: groupId,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm1',
            groupId: groupId,
            displayName: 'Member 1',
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('AddExpenseScreen shows HapticSlider in custom split mode', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroupAndMembers(groupId);

    final prefsOverrides = await getSharedPrefsOverride(
      customKeypadEnabled: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(AddExpenseScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();

    // Enter total amount
    await tester.enterText(find.byType(TextField).first, '100.00');
    await tester.pumpAndSettle();

    // Change split type to custom
    final splitDropdown = find.text('Split Equally');
    await tester.ensureVisible(splitDropdown);
    await tester.tap(splitDropdown);
    await tester.pumpAndSettle();

    final customSplitItem = find.text('Split Customly').last;
    await tester.tap(customSplitItem);
    await tester.pumpAndSettle();

    // Verify HapticSlider is visible
    expect(find.byType(Slider), findsOneWidget);

    // Slide to change value
    final slider = find.byType(Slider);
    await tester.tap(slider); // Taps center (50%)
    await tester.pumpAndSettle();

    // Verify text field updated to 50.00
    expect(find.text('50.00'), findsOneWidget);

    await db.close();
  });
}
