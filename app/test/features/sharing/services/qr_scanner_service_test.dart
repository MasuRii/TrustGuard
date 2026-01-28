import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/sharing/models/shareable_expense.dart';
import 'package:trustguard/src/features/sharing/services/qr_scanner_service.dart';

void main() {
  late QrScannerService service;

  setUp(() {
    service = QrScannerService();
  });

  group('QrScannerService', () {
    final validExpense = ShareableExpense(
      type: ShareableType.expense,
      description: 'Dinner',
      amountMinor: 2000,
      currencyCode: 'USD',
      date: DateTime(2023, 1, 1),
      payerName: 'Alice',
      participants: [
        const ShareableParticipant(name: 'Alice', amountMinor: 1000),
        const ShareableParticipant(name: 'Bob', amountMinor: 1000),
      ],
      tags: [],
    );

    test('parseQrData parses valid expense string', () {
      final data = 'TG:${validExpense.toCompressedString()}';
      final result = service.parseQrData(data);
      expect(result, isA<ShareableExpense>());
      expect((result as ShareableExpense).description, 'Dinner');
    });

    test('parseQrData throws QrParseException on invalid prefix', () {
      final data = 'INVALID:${validExpense.toCompressedString()}';
      expect(() => service.parseQrData(data), throwsA(isA<QrParseException>()));
    });

    test('parseQrData throws QrParseException on corrupted data', () {
      final data = 'TG:NotBase64Data';
      expect(() => service.parseQrData(data), throwsA(isA<QrParseException>()));
    });

    test(
      'validateExpense throws QrInvalidDataException on negative amount',
      () {
        final invalidExpense = validExpense.copyWith(amountMinor: -100);
        expect(
          () => service.validateExpense(invalidExpense),
          throwsA(isA<QrInvalidDataException>()),
        );
      },
    );

    test(
      'validateExpense throws QrInvalidDataException on mismatch participants',
      () {
        final invalidExpense = validExpense.copyWith(
          participants: [
            const ShareableParticipant(
              name: 'Alice',
              amountMinor: 500,
            ), // Total 500 != 2000
          ],
        );
        expect(
          () => service.validateExpense(invalidExpense),
          throwsA(isA<QrInvalidDataException>()),
        );
      },
    );
  });
}
