import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/balances/presentation/settlements_screen.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('SettlementsScreen groups suggestions by context', (
    tester,
  ) async {
    final groupId = 'g1';
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
            displayName: 'Me',
            createdAt: DateTime.now(),
          ),
        );
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm2',
            groupId: groupId,
            displayName: 'Other',
            createdAt: DateTime.now(),
          ),
        );

    // Insert expense: Other paid 20. Me owes 10.
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't1',
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Lunch',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.expenseDetails)
        .insert(
          ExpenseDetailsCompanion.insert(
            txId: 't1',
            payerMemberId: 'm2',
            totalAmountMinor: 2000,
            splitType: SplitType.equal,
          ),
        );
    await db
        .into(db.expenseParticipants)
        .insert(
          ExpenseParticipantsCompanion.insert(
            txId: 't1',
            memberId: 'm1',
            owedAmountMinor: 1000,
          ),
        );
    await db
        .into(db.expenseParticipants)
        .insert(
          ExpenseParticipantsCompanion.insert(
            txId: 't1',
            memberId: 'm2',
            owedAmountMinor: 1000,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(SettlementsScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1)); // Skeletons

    // Should see 'Which one is you?' selector initially if no self member set
    expect(find.text('Which one is you?'), findsOneWidget);

    // Select 'Me' as self
    await tester.tap(find.widgetWithText(ActionChip, 'Me'));
    await tester.pumpAndSettle();

    // Should see 'ACTION REQUIRED' (all caps in UI style)
    expect(find.text('ACTION REQUIRED'), findsOneWidget);
    expect(find.text('Pay Now'), findsOneWidget);

    // Other settlements should be in ExpansionTile
    expect(
      find.text('Other Settlements'),
      findsNothing,
    ); // Should be empty if only one suggestion involving me

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('SettlementsScreen shows empty state when all settled', (
    tester,
  ) async {
    final groupId = 'g2';
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: groupId,
            name: 'Empty Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(SettlementsScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('All settled up!'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
