import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_list_screen.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('TransactionListItem reveals edit and delete on swipe', (
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
            displayName: 'Alice',
            createdAt: DateTime.now(),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't1',
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.expenseDetails)
        .insert(
          ExpenseDetailsCompanion.insert(
            txId: 't1',
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(TransactionListScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(
      const Duration(seconds: 1),
    ); // Wait for skeletons to finish

    expect(find.text('Test Tx'), findsOneWidget);

    // Swipe right to reveal edit
    // Offset must be large enough to trigger the action pane
    await tester.drag(find.text('Test Tx'), const Offset(500, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.edit), findsOneWidget);

    // Swipe back
    await tester.drag(find.text('Test Tx'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Swipe left to reveal delete
    await tester.drag(find.text('Test Tx'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Tap delete
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Should be removed from list (optimistically)
    expect(find.text('Test Tx'), findsNothing);

    // Should see undo snackbar
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
