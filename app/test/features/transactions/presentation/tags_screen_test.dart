import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/tags_screen.dart';
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

  testWidgets('TagsScreen shows empty state when no tags', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TagsScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('No tags'), findsOneWidget);
    expect(find.text('Add Tag'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('TagsScreen lists tags and usage count', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final tagId = const Uuid().v4();
    final txId = const Uuid().v4();

    await setupGroup(groupId);

    // Insert a tag
    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(id: tagId, groupId: groupId, name: 'Food'),
        );

    // Insert a transaction and associate with tag
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            note: 'Lunch',
            occurredAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.transactionTags)
        .insert(TransactionTagsCompanion.insert(txId: txId, tagId: tagId));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TagsScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('1 transactions'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('TagsScreen can add a new tag', (WidgetTester tester) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: TagsScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Click FAB
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Enter tag name
    await tester.enterText(find.byType(TextField), 'Travel');
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('0 transactions'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
