import 'package:intl/intl.dart';

/// Utilities for handling money using minor units (cents).
class MoneyUtils {
  /// Converts a double amount to minor units (e.g., 10.50 -> 1050).
  /// Uses rounding to the nearest integer.
  static int toMinorUnits(double amount) {
    return (amount * 100).round();
  }

  /// Converts minor units to a double amount (e.g., 1050 -> 10.50).
  static double fromMinorUnits(int minorUnits) {
    return minorUnits / 100.0;
  }

  /// Formats minor units as a currency string.
  static String format(
    int minorUnits, {
    String currencyCode = 'USD',
    String? locale,
  }) {
    final format = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencyCode,
    );
    return format.format(fromMinorUnits(minorUnits));
  }

  /// Splits a total amount into equal parts, handling remainders.
  ///
  /// The remainder is distributed one cent at a time to the first participants.
  /// Example: splitEqual(100, 3) -> [34, 33, 33]
  static List<int> splitEqual(int totalMinor, int participantCount) {
    if (participantCount <= 0) return [];

    final quotient = totalMinor ~/ participantCount;
    final remainder = totalMinor % participantCount;

    return List.generate(participantCount, (index) {
      return quotient + (index < remainder ? 1 : 0);
    });
  }
}
