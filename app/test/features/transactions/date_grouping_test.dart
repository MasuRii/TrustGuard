import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:trustguard/src/features/transactions/presentation/widgets/date_group_header.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  testWidgets('DateGroupHeader shows Today for current date', (tester) async {
    final today = DateTime.now();
    await tester.pumpWidget(wrapWithLocalization(DateGroupHeader(date: today)));
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('DateGroupHeader shows Yesterday for previous date', (
    tester,
  ) async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await tester.pumpWidget(
      wrapWithLocalization(DateGroupHeader(date: yesterday)),
    );
    expect(find.text('Yesterday'), findsOneWidget);
  });

  testWidgets('DateGroupHeader shows formatted date for older dates', (
    tester,
  ) async {
    final olderDate = DateTime(2025, 12, 25);
    await tester.pumpWidget(
      wrapWithLocalization(DateGroupHeader(date: olderDate)),
    );
    expect(find.text('December 25, 2025'), findsOneWidget);
  });

  testWidgets('TransactionListScreen displays date headers', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
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

    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't1',
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: today,
            note: 'Today Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: 't2',
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: yesterday,
            note: 'Yesterday Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
    await tester.pump(const Duration(seconds: 1)); // Skeletons

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Today Tx'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Yesterday Tx'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
