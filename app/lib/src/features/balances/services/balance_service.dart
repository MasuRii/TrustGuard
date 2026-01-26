import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/balance.dart';
import '../../../core/models/transaction.dart';
import '../../groups/presentation/groups_providers.dart';
import '../../transactions/presentation/transactions_providers.dart';

class BalanceService {
  /// Computes the net balance for each member in a group.
  /// Positive netAmountMinor means the member is a creditor (owed money).
  /// Negative netAmountMinor means the member is a debtor (owes money).
  static List<MemberBalance> computeBalances({
    required List<String> memberIds,
    required Map<String, String> memberNames,
    required List<Transaction> transactions,
  }) {
    final netAmounts = {for (var id in memberIds) id: 0};

    for (final tx in transactions) {
      if (tx.deletedAt != null) continue;

      if (tx.type == TransactionType.expense && tx.expenseDetail != null) {
        final detail = tx.expenseDetail!;
        // Payer gets the total amount as "credit"
        netAmounts[detail.payerMemberId] =
            (netAmounts[detail.payerMemberId] ?? 0) + detail.totalAmountMinor;

        // Each participant gets their owed amount as "debt"
        for (final participant in detail.participants) {
          netAmounts[participant.memberId] =
              (netAmounts[participant.memberId] ?? 0) -
              participant.owedAmountMinor;
        }
      } else if (tx.type == TransactionType.transfer &&
          tx.transferDetail != null) {
        final detail = tx.transferDetail!;
        // From member gets amount as "credit" (they paid someone)
        netAmounts[detail.fromMemberId] =
            (netAmounts[detail.fromMemberId] ?? 0) + detail.amountMinor;

        // To member gets amount as "debt" (they received money)
        netAmounts[detail.toMemberId] =
            (netAmounts[detail.toMemberId] ?? 0) - detail.amountMinor;
      }
    }

    return memberIds.map((id) {
      final amount = netAmounts[id] ?? 0;
      return MemberBalance(
        memberId: id,
        memberName: memberNames[id] ?? 'Unknown',
        netAmountMinor: amount,
        isCreditor: amount > 0,
      );
    }).toList();
  }
}

/// Provider that computes and watches balances for a group.
final groupBalancesProvider = StreamProvider.autoDispose
    .family<List<MemberBalance>, String>((ref, groupId) {
      final transactionsAsync = ref.watch(transactionsByGroupProvider(groupId));
      final membersAsync = ref.watch(membersByGroupProvider(groupId));

      return transactionsAsync.when(
        data: (transactions) => membersAsync.when(
          data: (members) {
            final memberIds = members.map((m) => m.id).toList();
            final memberNames = {for (var m in members) m.id: m.displayName};

            return Stream.value(
              BalanceService.computeBalances(
                memberIds: memberIds,
                memberNames: memberNames,
                transactions: transactions,
              ),
            );
          },
          loading: () => const Stream.empty(),
          error: (e, s) => Stream.error(e, s),
        ),
        loading: () => const Stream.empty(),
        error: (e, s) => Stream.error(e, s),
      );
    });
