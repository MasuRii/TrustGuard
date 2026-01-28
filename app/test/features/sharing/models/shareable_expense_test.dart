import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/sharing/models/shareable_expense.dart';

void main() {
  group('ShareableExpense', () {
    final testExpense = ShareableExpense(
      type: ShareableType.expense,
      description: 'Dinner',
      amountMinor: 5000,
      currencyCode: 'USD',
      date: DateTime(2023, 1, 1),
      payerName: 'Alice',
      participants: [
        const ShareableParticipant(name: 'Alice', amountMinor: 2500),
        const ShareableParticipant(name: 'Bob', amountMinor: 2500),
      ],
      tags: ['Food'],
      sourceId: 'tx-123',
    );

    test('serializes to JSON correctly', () {
      final json = testExpense.toJson();
      expect(json['description'], 'Dinner');
      expect(json['amountMinor'], 5000);
      expect(json['type'], 'expense');
      expect(json['version'], 1);
      expect(json['sourceId'], 'tx-123');
    });

    test('deserializes from JSON correctly', () {
      final json =
          jsonDecode(jsonEncode(testExpense.toJson())) as Map<String, dynamic>;
      final result = ShareableExpense.fromJson(json);
      expect(result, testExpense);
    });

    test('compresses and decompresses correctly', () {
      final compressed = testExpense.toCompressedString();
      final result = ShareableExpense.fromCompressedString(compressed);
      expect(result, testExpense);
      expect(
        compressed.length,
        lessThan(jsonEncode(testExpense.toJson()).length),
      );
    });
  });

  group('ShareableBatch', () {
    final testBatch = ShareableBatch(
      groupName: 'Trip',
      expenses: [
        ShareableExpense(
          type: ShareableType.expense,
          description: 'Taxi',
          amountMinor: 2000,
          currencyCode: 'USD',
          date: DateTime(2023, 1, 1),
          payerName: 'Alice',
          participants: [
            const ShareableParticipant(name: 'Alice', amountMinor: 1000),
            const ShareableParticipant(name: 'Bob', amountMinor: 1000),
          ],
        ),
      ],
    );

    test('serializes to JSON correctly', () {
      final json = testBatch.toJson();
      expect(json['groupName'], 'Trip');
      expect(json['expenses'], hasLength(1));
    });

    test('compresses and decompresses correctly', () {
      final compressed = testBatch.toCompressedString();
      final result = ShareableBatch.fromCompressedString(compressed);
      expect(result, testBatch);
    });
  });
}
