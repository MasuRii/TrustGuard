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

  tearDown(() async {
    // Already closed in testWidgets for stability
  });

  Future<void> setupData(String groupId) async {
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
            displayName: 'Alice',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm2',
            groupId: groupId,
            displayName: 'Bob',
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('AddExpenseScreen handles percentage split mode', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupData(groupId);

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

    // 1. Fill in amount
    await tester.enterText(find.byType(TextFormField).first, '100.00');

    // 2. Switch to custom split
    await tester.ensureVisible(find.text('Split Equally'));
    await tester.tap(find.text('Split Equally'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Split Customly').last);
    await tester.tap(find.text('Split Customly').last);
    await tester.pumpAndSettle();

    // 3. Switch to Percentage mode
    await tester.ensureVisible(find.text('Percentage'));
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<CustomSplitMode>),
        matching: find.text('Percentage'),
      ),
    );
    await tester.pumpAndSettle();

    // 4. Verify Sliders are present
    expect(find.byType(Slider), findsAtLeast(2));
    expect(find.text('0%'), findsNWidgets(2));

    // 5. Switch back to Amount mode
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<CustomSplitMode>),
        matching: find.text('Amount'),
      ),
    );
    await tester.pumpAndSettle();

    // 6. Enter amounts: Alice=60, Bob=40
    await tester.enterText(find.byType(TextFormField).at(2), '60.00');
    await tester.enterText(find.byType(TextFormField).at(3), '40.00');
    await tester.pumpAndSettle();

    // 7. Switch to Percentage mode again - should have updated from amounts
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<CustomSplitMode>),
        matching: find.text('Percentage'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);

    // 8. Tap Save - should succeed as 60+40=100
    await tester.ensureVisible(find.byTooltip('Save'));
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    // Verify transaction created with correct amounts
    final participants = await db.select(db.expenseParticipants).get();
    expect(participants.length, 2);
    expect(
      participants.firstWhere((p) => p.memberId == 'm1').owedAmountMinor,
      6000,
    );
    expect(
      participants.firstWhere((p) => p.memberId == 'm2').owedAmountMinor,
      4000,
    );

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'AddExpenseScreen shows error if percentages do not sum to 100%',
    (WidgetTester tester) async {
      final groupId = const Uuid().v4();
      await setupData(groupId);

      final prefsOverrides = await getSharedPrefsOverride(
        customKeypadEnabled: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ...prefsOverrides,
          ],
          child: wrapWithLocalization(AddExpenseScreen(groupId: groupId)),
        ),
      );

      await tester.pumpAndSettle();

      // Fill in amount
      await tester.enterText(find.byType(TextFormField).first, '100.00');

      // Switch to custom split -> Percentage
      await tester.ensureVisible(find.text('Split Equally'));
      await tester.tap(find.text('Split Equally'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Split Customly').last);
      await tester.tap(find.text('Split Customly').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Percentage'));
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedButton<CustomSplitMode>),
          matching: find.text('Percentage'),
        ),
      );
      await tester.pumpAndSettle();

      // Default is 0% + 0% = 0% != 100%
      await tester.ensureVisible(find.byTooltip('Save'));
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(
        find.textContaining('Total percentage must be 100%'),
        findsOneWidget,
      );

      await db.close();
      await tester.pump(Duration.zero);
    },
  );
}
