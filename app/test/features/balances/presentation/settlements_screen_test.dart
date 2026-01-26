import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/balances/presentation/settlements_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
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

  testWidgets('SettlementsScreen shows suggestions', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupData(groupId);

    // Insert an expense: Alice paid 20.00 for Alice and Bob
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
            payerMemberId: 'm1',
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

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsWidgets);
    expect(find.text('Alice'), findsWidgets);
    expect(find.text('owes'), findsOneWidget);
    expect(find.text('is owed'), findsOneWidget);
    expect(find.text(r'$10.00'), findsOneWidget);
    expect(find.text('Record'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
