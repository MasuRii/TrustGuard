import '../../../core/models/transaction.dart';

/// Groups transactions by date (ignoring time).
/// Returns a map where keys are normalized [DateTime] objects (midnight)
/// and values are lists of transactions occurred on that day.
/// The map is sorted by date descending (newest first).
Map<DateTime, List<Transaction>> groupTransactionsByDate(
  List<Transaction> transactions,
) {
  final Map<DateTime, List<Transaction>> groups = {};

  for (final transaction in transactions) {
    final date = DateTime(
      transaction.occurredAt.year,
      transaction.occurredAt.month,
      transaction.occurredAt.day,
    );
    groups.putIfAbsent(date, () => []).add(transaction);
  }

  // Sort groups by date descending
  final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

  return Map.fromEntries(
    sortedKeys.map((date) => MapEntry(date, groups[date]!)),
  );
}
