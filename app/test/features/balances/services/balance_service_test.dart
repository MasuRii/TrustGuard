import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/transfer.dart';
import 'package:trustguard/src/features/balances/services/balance_service.dart';

void main() {
  group('BalanceService', () {
    test('computes balances correctly for simple expense', () {
      final memberIds = ['m1', 'm2', 'm3'];
      final memberNames = {'m1': 'Alice', 'm2': 'Bob', 'm3': 'Charlie'};
      final transactions = [
        Transaction(
          id: 't1',
          groupId: 'g1',
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Lunch',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 3000,
            splitType: SplitType.equal,
            participants: [
              ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1000),
              ExpenseParticipant(memberId: 'm2', owedAmountMinor: 1000),
              ExpenseParticipant(memberId: 'm3', owedAmountMinor: 1000),
            ],
          ),
        ),
      ];

      final balances = BalanceService.computeBalances(
        memberIds: memberIds,
        memberNames: memberNames,
        transactions: transactions,
      );

      // Alice paid 3000, owes 1000 -> +2000
      expect(
        balances.firstWhere((b) => b.memberId == 'm1').netAmountMinor,
        2000,
      );
      expect(balances.firstWhere((b) => b.memberId == 'm1').isCreditor, true);

      // Bob owes 1000 -> -1000
      expect(
        balances.firstWhere((b) => b.memberId == 'm2').netAmountMinor,
        -1000,
      );
      expect(balances.firstWhere((b) => b.memberId == 'm2').isCreditor, false);

      // Charlie owes 1000 -> -1000
      expect(
        balances.firstWhere((b) => b.memberId == 'm3').netAmountMinor,
        -1000,
      );
    });

    test('computes balances correctly with transfers', () {
      final memberIds = ['m1', 'm2'];
      final memberNames = {'m1': 'Alice', 'm2': 'Bob'};
      final transactions = [
        // Alice paid 2000 for both (1000 each)
        Transaction(
          id: 't1',
          groupId: 'g1',
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Movie',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 2000,
            splitType: SplitType.equal,
            participants: [
              ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1000),
              ExpenseParticipant(memberId: 'm2', owedAmountMinor: 1000),
            ],
          ),
        ),
        // Bob pays Alice 500
        Transaction(
          id: 't2',
          groupId: 'g1',
          type: TransactionType.transfer,
          occurredAt: DateTime.now(),
          note: 'Partial settlement',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          transferDetail: const TransferDetail(
            fromMemberId: 'm2',
            toMemberId: 'm1',
            amountMinor: 500,
          ),
        ),
      ];

      final balances = BalanceService.computeBalances(
        memberIds: memberIds,
        memberNames: memberNames,
        transactions: transactions,
      );

      // Alice: +1000 (from expense) - 500 (received transfer) = +500
      // Wait, if Bob transfers to Alice, Alice's credit REDUCES.
      // In my implementation:
      // Expense: Alice +2000, Alice -1000, Bob -1000 -> Alice +1000, Bob -1000
      // Transfer: Bob (from) +500, Alice (to) -500
      // Alice: +1000 - 500 = +500
      // Bob: -1000 + 500 = -500
      // Correct!

      expect(
        balances.firstWhere((b) => b.memberId == 'm1').netAmountMinor,
        500,
      );
      expect(
        balances.firstWhere((b) => b.memberId == 'm2').netAmountMinor,
        -500,
      );
    });

    test('excludes deleted transactions', () {
      final memberIds = ['m1'];
      final memberNames = {'m1': 'Alice'};
      final transactions = [
        Transaction(
          id: 't1',
          groupId: 'g1',
          type: TransactionType.expense,
          occurredAt: DateTime.now(),
          note: 'Deleted',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deletedAt: DateTime.now(),
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [
              ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1000),
            ],
          ),
        ),
      ];

      final balances = BalanceService.computeBalances(
        memberIds: memberIds,
        memberNames: memberNames,
        transactions: transactions,
      );

      expect(balances.firstWhere((b) => b.memberId == 'm1').netAmountMinor, 0);
    });
  });
}
