import '../../../core/models/balance.dart';
import '../../../core/models/settlement_suggestion.dart';

class SettlementService {
  /// Computes settlement suggestions based on member balances using a greedy algorithm.
  ///
  /// The algorithm works by picking the largest debtor and the largest creditor,
  /// creating a transfer between them, and repeating until all balances are settled.
  static List<SettlementSuggestion> computeSettlementSuggestions(
    List<MemberBalance> balances,
  ) {
    final suggestions = <SettlementSuggestion>[];

    // Separate into debtors and creditors
    // Use a mutable copy of the amounts to track remaining balance to settle
    final debtors =
        balances
            .where((b) => b.netAmountMinor < 0)
            .map(
              (b) => _MutableBalance(
                b.memberId,
                b.memberName,
                b.netAmountMinor.abs(),
              ),
            )
            .toList()
          ..sort(
            (a, b) => b.amountMinor.compareTo(a.amountMinor),
          ); // Largest debtor first

    final creditors =
        balances
            .where((b) => b.netAmountMinor > 0)
            .map(
              (b) =>
                  _MutableBalance(b.memberId, b.memberName, b.netAmountMinor),
            )
            .toList()
          ..sort(
            (a, b) => b.amountMinor.compareTo(a.amountMinor),
          ); // Largest creditor first

    int debtorIdx = 0;
    int creditorIdx = 0;

    while (debtorIdx < debtors.length && creditorIdx < creditors.length) {
      final debtor = debtors[debtorIdx];
      final creditor = creditors[creditorIdx];

      // Settle the minimum of what debtor owes and what creditor is owed
      final amountToSettle = debtor.amountMinor < creditor.amountMinor
          ? debtor.amountMinor
          : creditor.amountMinor;

      if (amountToSettle > 0) {
        suggestions.add(
          SettlementSuggestion(
            fromMemberId: debtor.memberId,
            fromMemberName: debtor.memberName,
            toMemberId: creditor.memberId,
            toMemberName: creditor.memberName,
            amountMinor: amountToSettle,
          ),
        );
      }

      debtor.amountMinor -= amountToSettle;
      creditor.amountMinor -= amountToSettle;

      if (debtor.amountMinor == 0) debtorIdx++;
      if (creditor.amountMinor == 0) creditorIdx++;
    }

    return suggestions;
  }
}

class _MutableBalance {
  final String memberId;
  final String memberName;
  int amountMinor;

  _MutableBalance(this.memberId, this.memberName, this.amountMinor);
}
