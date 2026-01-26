import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> setupGroup(String id) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: id,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> setupMember(String id, String groupId, String name) async {
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: id,
            groupId: groupId,
            displayName: name,
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> setupTag(String id, String groupId, String name) async {
    await db
        .into(db.tags)
        .insert(TagsCompanion.insert(id: id, groupId: groupId, name: name));
  }

  Future<void> insertExpense(
    String id,
    String groupId,
    String memberId,
    String note, {
    List<String> tagIds = const [],
  }) async {
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: note,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.expenseDetails)
        .insert(
          ExpenseDetailsCompanion.insert(
            txId: id,
            payerMemberId: memberId,
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
          ),
        );
    await db
        .into(db.expenseParticipants)
        .insert(
          ExpenseParticipantsCompanion.insert(
            txId: id,
            memberId: memberId,
            owedAmountMinor: 1000,
          ),
        );
    for (final tagId in tagIds) {
      await db
          .into(db.transactionTags)
          .insert(TransactionTagsCompanion.insert(txId: id, tagId: tagId));
    }
  }

  testWidgets('TransactionListScreen filters by search query', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();
    await setupGroup(groupId);
    await setupMember(memberId, groupId, 'Alice');

    await insertExpense(const Uuid().v4(), groupId, memberId, 'Lunch');
    await insertExpense(const Uuid().v4(), groupId, memberId, 'Dinner');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TransactionListScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);

    // Type 'Lunch' in search bar
    await tester.enterText(find.byType(TextField), 'Lunch');
    await tester.pumpAndSettle();

    // Now 'Lunch' should be in the TextField AND in the list item
    expect(find.text('Lunch'), findsNWidgets(2));
    expect(find.text('Dinner'), findsNothing);

    // Clear search
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('TransactionListScreen filters by tag', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final tagId = const Uuid().v4();
    await setupGroup(groupId);
    await setupMember(memberId, groupId, 'Alice');
    await setupTag(tagId, groupId, 'Food');

    await insertExpense(
      const Uuid().v4(),
      groupId,
      memberId,
      'Lunch',
      tagIds: [tagId],
    );
    await insertExpense(const Uuid().v4(), groupId, memberId, 'Cinema');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TransactionListScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Cinema'), findsOneWidget);

    // Open filter sheet
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Select 'Food' chip in the filter sheet
    final foodChip = find.descendant(
      of: find.byType(FilterChip),
      matching: find.text('Food'),
    );
    await tester.tap(foodChip);
    await tester.pumpAndSettle();

    // Apply filters
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Cinema'), findsNothing);
    expect(find.text('Tag: Food'), findsOneWidget);

    // Remove filter chip (the one with 'Tag: Food')
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text('Cinema'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
