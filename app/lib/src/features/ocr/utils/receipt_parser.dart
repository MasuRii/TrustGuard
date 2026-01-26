import '../models/receipt_data.dart';

class ReceiptParser {
  /// Regular expressions for detecting amounts ($12.34, 12,34€, 50.00, etc.)
  static final RegExp _amountRegex = RegExp(
    r'(?:\$|€|£|USD|EUR|GBP)?\s?(\d+(?:[.,]\d{2}))\b',
    caseSensitive: false,
  );

  /// Regular expressions for detecting dates
  static final List<RegExp> _dateRegexes = [
    // DD/MM/YYYY or MM/DD/YYYY
    RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
    // YYYY-MM-DD
    RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b'),
    // DD.MM.YYYY
    RegExp(r'\b(\d{1,2})\.(\d{1,2})\.(\d{4})\b'),
  ];

  /// Regular expressions for detecting merchant from "Welcome to" or similar
  static final RegExp _welcomeRegex = RegExp(
    r'(?:Welcome to|Thanks for visiting|Store|Shop)\s+([^\n\r]+)',
    caseSensitive: false,
  );

  static double? extractAmount(String text) {
    final matches = _amountRegex.allMatches(text);
    if (matches.isEmpty) return null;

    double? maxAmount;
    for (final match in matches) {
      final amountStr = match.group(1)?.replaceAll(',', '.');
      if (amountStr != null) {
        final amount = double.tryParse(amountStr);
        if (amount != null) {
          if (maxAmount == null || amount > maxAmount) {
            maxAmount = amount;
          }
        }
      }
    }
    return maxAmount;
  }

  static DateTime? extractDate(String text) {
    for (final regex in _dateRegexes) {
      final matches = regex.allMatches(text);
      if (matches.isNotEmpty) {
        // Return the first valid date found
        for (final match in matches) {
          try {
            if (regex == _dateRegexes[1]) {
              // YYYY-MM-DD
              final y = int.parse(match.group(1)!);
              final m = int.parse(match.group(2)!);
              final d = int.parse(match.group(3)!);
              return DateTime(y, m, d);
            } else {
              // DD/MM/YYYY or MM/DD/YYYY - ambiguous but we'll try to be smart
              final g1 = int.parse(match.group(1)!);
              final g2 = int.parse(match.group(2)!);
              final g3 = int.parse(match.group(3)!);

              final int year = g3 < 100 ? 2000 + g3 : g3;

              // If g1 > 12, it's likely DD/MM
              if (g1 > 12) {
                return DateTime(year, g2, g1);
              }
              // If g2 > 12, it's likely MM/DD
              if (g2 > 12) {
                return DateTime(year, g1, g2);
              }
              // Default to DD/MM (European style favored for offline apps often)
              // or just pick one. Let's try to see if it makes a valid date.
              return DateTime(year, g2, g1);
            }
          } catch (_) {
            continue;
          }
        }
      }
    }
    return null;
  }

  static String? extractMerchant(String text) {
    final welcomeMatch = _welcomeRegex.firstMatch(text);
    if (welcomeMatch != null) {
      return welcomeMatch.group(1)?.trim();
    }

    // Fallback: first non-empty line that isn't just numbers/symbols
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length > 2 && RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
        // Skip common header noise like dates or phone numbers
        if (!RegExp(r'^\d+[\s-]\d+').hasMatch(trimmed) &&
            !trimmed.contains('/')) {
          return trimmed;
        }
      }
    }
    return null;
  }

  static ReceiptData parseReceipt(String rawText) {
    final amount = extractAmount(rawText);
    final date = extractDate(rawText);
    final merchant = extractMerchant(rawText);

    double confidence = 0.0;
    if (amount != null) confidence += 0.4;
    if (date != null) confidence += 0.3;
    if (merchant != null) confidence += 0.3;

    return ReceiptData(
      suggestedAmount: amount,
      suggestedDate: date,
      suggestedMerchant: merchant,
      rawText: rawText,
      confidence: confidence,
    );
  }
}
