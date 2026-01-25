import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/utils/money.dart';

void main() {
  group('MoneyUtils', () {
    test('toMinorUnits converts double to int correctly', () {
      expect(MoneyUtils.toMinorUnits(10.50), 1050);
      expect(MoneyUtils.toMinorUnits(10.504), 1050);
      expect(MoneyUtils.toMinorUnits(10.505), 1051);
      expect(MoneyUtils.toMinorUnits(0), 0);
      expect(MoneyUtils.toMinorUnits(-10.50), -1050);
    });

    test('fromMinorUnits converts int to double correctly', () {
      expect(MoneyUtils.fromMinorUnits(1050), 10.50);
      expect(MoneyUtils.fromMinorUnits(0), 0.0);
      expect(MoneyUtils.fromMinorUnits(-1050), -10.50);
    });

    test('format returns correctly formatted string', () {
      // Default locale (en_US usually in tests)
      expect(MoneyUtils.format(1050, currencyCode: 'USD'), contains('10.50'));
      expect(MoneyUtils.format(1050, currencyCode: 'USD'), contains('\$'));

      // Different currency
      expect(MoneyUtils.format(1050, currencyCode: 'EUR'), contains('10.50'));
    });

    group('splitEqual', () {
      test('splits evenly when no remainder', () {
        final result = MoneyUtils.splitEqual(300, 3);
        expect(result, [100, 100, 100]);
        expect(result.reduce((a, b) => a + b), 300);
      });

      test('distributes remainder correctly', () {
        final result = MoneyUtils.splitEqual(100, 3);
        expect(result, [34, 33, 33]);
        expect(result.reduce((a, b) => a + b), 100);
      });

      test('handles large remainders', () {
        final result = MoneyUtils.splitEqual(104, 5);
        // 104 / 5 = 20 with remainder 4
        expect(result, [21, 21, 21, 21, 20]);
        expect(result.reduce((a, b) => a + b), 104);
      });

      test('handles zero or negative participants', () {
        expect(MoneyUtils.splitEqual(100, 0), <int>[]);
        expect(MoneyUtils.splitEqual(100, -1), <int>[]);
      });

      test('handles zero total', () {
        expect(MoneyUtils.splitEqual(0, 3), [0, 0, 0]);
      });
    });
  });
}
