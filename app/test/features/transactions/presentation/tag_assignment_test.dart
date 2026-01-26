import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/transactions/presentation/add_expense_screen.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('AddExpenseScreen should allow selecting and saving tags', (
    tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final tagId = const Uuid().v4();

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
            id: memberId,
            groupId: groupId,
            displayName: 'Member 1',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.tags)
        .insert(
          TagsCompanion.insert(id: tagId, groupId: groupId, name: 'Food'),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(AddExpenseScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();

    // Enter amount
    await tester.enterText(find.byType(TextFormField).first, '100');

    // Select tag
    expect(find.text('Food'), findsOneWidget);
    await tester.tap(find.text('Food'));
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    // Verify transaction and tag assignment in DB
    final txs = await db.select(db.transactions).get();
    expect(txs.length, 1);

    final txTags = await db.select(db.transactionTags).get();
    expect(txTags.length, 1);
    expect(txTags.first.tagId, tagId);
    expect(txTags.first.txId, txs.first.id);

    // Mitigation for "A Timer is still pending"
    await db.close();
    await tester.pump(Duration.zero);
  });
}
