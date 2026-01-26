import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/features/ocr/utils/receipt_parser.dart';

void main() {
  group('ReceiptParser', () {
    test('extractAmount finds currency values and returns the largest', () {
      const text = '''
        WELCOME TO SUPERMART
        Milk: 2.50
        Bread: 1.20
        Eggs: 4.00
        TOTAL: 7.70
        CASH: 10.00
        CHANGE: 2.30
      ''';
      expect(
        ReceiptParser.extractAmount(text),
        10.00,
      ); // CASH is larger than TOTAL in this example

      const text2 = 'Price: 15.50 EUR, Discount: 2.00, Pay: 13.50';
      expect(ReceiptParser.extractAmount(text2), 15.50);
    });

    test('extractAmount handles comma as decimal separator', () {
      const text = 'TOTAL: 12,34€';
      expect(ReceiptParser.extractAmount(text), 12.34);
    });

    test('extractDate handles multiple date formats', () {
      expect(
        ReceiptParser.extractDate('Date: 25/12/2023'),
        DateTime(2023, 12, 25),
      );
      expect(
        ReceiptParser.extractDate('Date: 12-25-2023'),
        DateTime(2023, 12, 25),
      );
      expect(
        ReceiptParser.extractDate('Date: 2023-12-25'),
        DateTime(2023, 12, 25),
      );
      expect(
        ReceiptParser.extractDate('Date: 25.12.2023'),
        DateTime(2023, 12, 25),
      );
    });

    test('extractDate handles ambiguous dates smartly', () {
      // 05/10/2023 -> Default to DD/MM (European) -> Oct 5
      expect(ReceiptParser.extractDate('05/10/2023'), DateTime(2023, 10, 5));

      // 15/10/2023 -> DD/MM (since 15 > 12) -> Oct 15
      expect(ReceiptParser.extractDate('15/10/2023'), DateTime(2023, 10, 15));

      // 10/15/2023 -> MM/DD (since 15 > 12) -> Oct 15
      expect(ReceiptParser.extractDate('10/15/2023'), DateTime(2023, 10, 15));
    });

    test('extractMerchant extracts merchant from keywords or first line', () {
      expect(
        ReceiptParser.extractMerchant('Welcome to Starbucks\nDate: ...'),
        'Starbucks',
      );
      expect(
        ReceiptParser.extractMerchant('Store #1234\nAddress: ...'),
        'Store #1234',
      );
      expect(
        ReceiptParser.extractMerchant('Apple Store\nInfinite Loop'),
        'Apple Store',
      );
    });

    test('parseReceipt combines extractors and calculates confidence', () {
      const text = '''
        Welcome to Walmart
        Date: 01/20/2024
        Total: 45.99
      ''';
      final data = ReceiptParser.parseReceipt(text);
      expect(data.suggestedMerchant, 'Walmart');
      expect(data.suggestedDate, DateTime(2024, 1, 20));
      expect(data.suggestedAmount, 45.99);
      expect(data.confidence, closeTo(1.0, 0.01));
    });

    test('parseReceipt handles missing data with lower confidence', () {
      const text = 'Total: 45.99';
      final data = ReceiptParser.parseReceipt(text);
      expect(data.suggestedAmount, 45.99);
      expect(data.suggestedDate, isNull);
      expect(data.suggestedMerchant, isNull);
      expect(data.confidence, closeTo(0.4, 0.01));
    });
  });
}
