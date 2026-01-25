import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/core/models/transfer.dart' as model;

void main() {
  late AppDatabase db;
  late TransactionRepository repository;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTransactionRepository(db);

    // Setup: Create a group and members
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'group-1',
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-1',
            groupId: 'group-1',
            displayName: 'Member 1',
            createdAt: DateTime(2026, 1, 1),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'member-2',
            groupId: 'group-1',
            displayName: 'Member 2',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('TransactionRepository', () {
    final now = DateTime(2026, 1, 26, 10);

    final testExpense = model.Transaction(
      id: 'tx-1',
      groupId: 'group-1',
      type: model.TransactionType.expense,
      occurredAt: now,
      note: 'Dinner',
      createdAt: now,
      updatedAt: now,
      expenseDetail: const model.ExpenseDetail(
        payerMemberId: 'member-1',
        totalAmountMinor: 1000,
        splitType: model.SplitType.equal,
        participants: [
          model.ExpenseParticipant(memberId: 'member-1', owedAmountMinor: 500),
          model.ExpenseParticipant(memberId: 'member-2', owedAmountMinor: 500),
        ],
      ),
    );

    final testTransfer = model.Transaction(
      id: 'tx-2',
      groupId: 'group-1',
      type: model.TransactionType.transfer,
      occurredAt: now.add(const Duration(hours: 1)),
      note: 'Settlement',
      createdAt: now,
      updatedAt: now,
      transferDetail: const model.TransferDetail(
        fromMemberId: 'member-2',
        toMemberId: 'member-1',
        amountMinor: 500,
      ),
    );

    test('create and get expense', () async {
      await repository.createTransaction(testExpense);
      final tx = await repository.getTransactionById('tx-1');

      expect(tx, isNotNull);
      expect(tx!.id, equals('tx-1'));
      expect(tx.type, equals(model.TransactionType.expense));
      expect(tx.expenseDetail, isNotNull);
      expect(tx.expenseDetail!.totalAmountMinor, equals(1000));
      expect(tx.expenseDetail!.participants, hasLength(2));
    });

    test('create and get transfer', () async {
      await repository.createTransaction(testTransfer);
      final tx = await repository.getTransactionById('tx-2');

      expect(tx, isNotNull);
      expect(tx!.id, equals('tx-2'));
      expect(tx.type, equals(model.TransactionType.transfer));
      expect(tx.transferDetail, isNotNull);
      expect(tx.transferDetail!.amountMinor, equals(500));
    });

    test('getTransactionsByGroup and watchTransactionsByGroup', () async {
      await repository.createTransaction(testExpense);
      await repository.createTransaction(testTransfer);

      final transactions = await repository.getTransactionsByGroup('group-1');
      expect(transactions, hasLength(2));
      // Should be sorted by occurredAt desc
      expect(transactions.first.id, equals('tx-2'));
      expect(transactions.last.id, equals('tx-1'));

      final stream = repository.watchTransactionsByGroup('group-1');
      expect(stream, emits(hasLength(2)));
    });

    test('update transaction', () async {
      await repository.createTransaction(testExpense);
      final updatedExpense = testExpense.copyWith(
        note: 'Updated Dinner',
        expenseDetail: testExpense.expenseDetail!.copyWith(
          totalAmountMinor: 1200,
          participants: [
            const model.ExpenseParticipant(
              memberId: 'member-1',
              owedAmountMinor: 600,
            ),
            const model.ExpenseParticipant(
              memberId: 'member-2',
              owedAmountMinor: 600,
            ),
          ],
        ),
      );

      await repository.updateTransaction(updatedExpense);
      final tx = await repository.getTransactionById('tx-1');

      expect(tx?.note, equals('Updated Dinner'));
      expect(tx?.expenseDetail?.totalAmountMinor, equals(1200));
      expect(
        tx?.expenseDetail?.participants.first.owedAmountMinor,
        equals(600),
      );
    });

    test('soft delete and undo', () async {
      await repository.createTransaction(testExpense);

      await repository.softDeleteTransaction('tx-1');
      var tx = await repository.getTransactionById('tx-1');
      expect(tx?.deletedAt, isNotNull);

      final activeTxs = await repository.getTransactionsByGroup(
        'group-1',
        includeDeleted: false,
      );
      expect(activeTxs, isEmpty);

      final allTxs = await repository.getTransactionsByGroup(
        'group-1',
        includeDeleted: true,
      );
      expect(allTxs, hasLength(1));

      await repository.undoSoftDeleteTransaction('tx-1');
      tx = await repository.getTransactionById('tx-1');
      expect(tx?.deletedAt, isNull);

      final activeTxsAfter = await repository.getTransactionsByGroup(
        'group-1',
        includeDeleted: false,
      );
      expect(activeTxsAfter, hasLength(1));
    });
  });
}
