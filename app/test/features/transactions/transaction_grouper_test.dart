import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/utils/transaction_grouper.dart';

void main() {
  group('TransactionGrouper', () {
    test('groupTransactionsByDate groups transactions by day correctly', () {
      final t1 = Transaction(
        id: '1',
        groupId: 'g1',
        type: TransactionType.expense,
        occurredAt: DateTime(2026, 1, 20, 10, 0),
        note: 'Note 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final t2 = Transaction(
        id: '2',
        groupId: 'g1',
        type: TransactionType.expense,
        occurredAt: DateTime(2026, 1, 20, 15, 0),
        note: 'Note 2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final t3 = Transaction(
        id: '3',
        groupId: 'g1',
        type: TransactionType.expense,
        occurredAt: DateTime(2026, 1, 19, 10, 0),
        note: 'Note 3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final grouped = groupTransactionsByDate([t1, t2, t3]);

      expect(grouped.length, 2);
      expect(grouped.keys.first, DateTime(2026, 1, 20));
      expect(grouped.keys.last, DateTime(2026, 1, 19));
      expect(grouped[DateTime(2026, 1, 20)]!.length, 2);
      expect(grouped[DateTime(2026, 1, 19)]!.length, 1);
    });

    test('groupTransactionsByDate sorts groups by date descending', () {
      final t1 = Transaction(
        id: '1',
        groupId: 'g1',
        type: TransactionType.expense,
        occurredAt: DateTime(2026, 1, 18),
        note: 'Old',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final t2 = Transaction(
        id: '2',
        groupId: 'g1',
        type: TransactionType.expense,
        occurredAt: DateTime(2026, 1, 20),
        note: 'New',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final grouped = groupTransactionsByDate([t1, t2]);

      expect(grouped.keys.first, DateTime(2026, 1, 20));
      expect(grouped.keys.last, DateTime(2026, 1, 18));
    });
  });
}
