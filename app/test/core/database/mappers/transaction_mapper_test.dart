import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/mappers/transaction_mapper.dart';
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/core/models/transfer.dart' as model;

void main() {
  group('TransactionMapper', () {
    final now = DateTime(2026, 1, 26, 12, 0);

    final transactionData = Transaction(
      id: 'tx1',
      groupId: 'g1',
      type: model.TransactionType.expense,
      occurredAt: now,
      note: 'Dinner',
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      isRecurring: false,
    );

    const expenseDetailData = ExpenseDetail(
      txId: 'tx1',
      payerMemberId: 'm1',
      totalAmountMinor: 1000,
      splitType: model.SplitType.equal,
      splitMetaJson: null,
    );

    final participantsData = [
      const ExpenseParticipant(
        txId: 'tx1',
        memberId: 'm1',
        owedAmountMinor: 500,
      ),
      const ExpenseParticipant(
        txId: 'tx1',
        memberId: 'm2',
        owedAmountMinor: 500,
      ),
    ];

    test('toModel should convert expense data to Transaction model', () {
      final result = TransactionMapper.toModel(
        transaction: transactionData,
        expenseDetail: expenseDetailData,
        participants: participantsData,
      );

      expect(result.id, equals(transactionData.id));
      expect(result.type, equals(model.TransactionType.expense));
      expect(result.expenseDetail?.totalAmountMinor, equals(1000));
      expect(result.expenseDetail?.participants.length, equals(2));
      expect(result.expenseDetail?.participants[0].memberId, equals('m1'));
      expect(result.transferDetail, isNull);
    });

    test('toModel should convert transfer data to Transaction model', () {
      final transferTxData = Transaction(
        id: 'tx2',
        groupId: 'g1',
        type: model.TransactionType.transfer,
        occurredAt: now,
        note: 'Settlement',
        createdAt: now,
        updatedAt: now,
        deletedAt: null,
        isRecurring: false,
      );

      const transferDetailData = TransferDetail(
        txId: 'tx2',
        fromMemberId: 'm1',
        toMemberId: 'm2',
        amountMinor: 500,
      );

      final result = TransactionMapper.toModel(
        transaction: transferTxData,
        transferDetail: transferDetailData,
      );

      expect(result.id, equals(transferTxData.id));
      expect(result.type, equals(model.TransactionType.transfer));
      expect(result.transferDetail?.amountMinor, equals(500));
      expect(result.transferDetail?.fromMemberId, equals('m1'));
      expect(result.expenseDetail, isNull);
    });

    test(
      'toTransactionCompanion should convert Transaction model to TransactionsCompanion',
      () {
        final domain = model.Transaction(
          id: 'tx1',
          groupId: 'g1',
          type: model.TransactionType.expense,
          occurredAt: now,
          note: 'Dinner',
          createdAt: now,
          updatedAt: now,
        );

        final result = TransactionMapper.toTransactionCompanion(domain);
        expect(result.id.value, equals(domain.id));
        expect(result.type.value, equals(domain.type));
        expect(result.note.value, equals(domain.note));
      },
    );

    test(
      'toExpenseDetailCompanion should convert Transaction model to ExpenseDetailsCompanion',
      () {
        final domain = model.Transaction(
          id: 'tx1',
          groupId: 'g1',
          type: model.TransactionType.expense,
          occurredAt: now,
          note: 'Dinner',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const model.ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: model.SplitType.equal,
            participants: [],
          ),
        );

        final result = TransactionMapper.toExpenseDetailCompanion(domain);
        expect(result?.txId.value, equals(domain.id));
        expect(
          result?.payerMemberId.value,
          equals(domain.expenseDetail?.payerMemberId),
        );
        expect(
          result?.totalAmountMinor.value,
          equals(domain.expenseDetail?.totalAmountMinor),
        );
      },
    );

    test(
      'toExpenseParticipantsCompanions should convert Transaction model to ExpenseParticipantsCompanions',
      () {
        final domain = model.Transaction(
          id: 'tx1',
          groupId: 'g1',
          type: model.TransactionType.expense,
          occurredAt: now,
          note: 'Dinner',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const model.ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: model.SplitType.equal,
            participants: [
              model.ExpenseParticipant(memberId: 'm1', owedAmountMinor: 500),
              model.ExpenseParticipant(memberId: 'm2', owedAmountMinor: 500),
            ],
          ),
        );

        final result = TransactionMapper.toExpenseParticipantsCompanions(
          domain,
        );
        expect(result.length, equals(2));
        expect(result[0].txId.value, equals(domain.id));
        expect(result[0].memberId.value, equals('m1'));
        expect(result[0].owedAmountMinor.value, equals(500));
      },
    );

    test(
      'toTransferDetailCompanion should convert Transaction model to TransferDetailsCompanion',
      () {
        final domain = model.Transaction(
          id: 'tx2',
          groupId: 'g1',
          type: model.TransactionType.transfer,
          occurredAt: now,
          note: 'Settlement',
          createdAt: now,
          updatedAt: now,
          transferDetail: const model.TransferDetail(
            fromMemberId: 'm1',
            toMemberId: 'm2',
            amountMinor: 500,
          ),
        );

        final result = TransactionMapper.toTransferDetailCompanion(domain);
        expect(result?.txId.value, equals(domain.id));
        expect(
          result?.fromMemberId.value,
          equals(domain.transferDetail?.fromMemberId),
        );
        expect(
          result?.toMemberId.value,
          equals(domain.transferDetail?.toMemberId),
        );
        expect(
          result?.amountMinor.value,
          equals(domain.transferDetail?.amountMinor),
        );
      },
    );
  });
}
