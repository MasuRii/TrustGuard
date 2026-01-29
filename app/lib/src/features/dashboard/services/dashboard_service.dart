import '../../../core/database/repositories/group_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../balances/services/balance_service.dart';
import '../models/global_balance_summary.dart';

class DashboardService {
  final GroupRepository _groupRepository;
  final MemberRepository _memberRepository;
  final TransactionRepository _transactionRepository;

  DashboardService({
    required GroupRepository groupRepository,
    required MemberRepository memberRepository,
    required TransactionRepository transactionRepository,
  }) : _groupRepository = groupRepository,
       _memberRepository = memberRepository,
       _transactionRepository = transactionRepository;

  Future<GlobalBalanceSummary> getGlobalSummary(String? selfMemberId) async {
    final groups = await _groupRepository.getAllGroups(includeArchived: false);

    int totalOwedByMe = 0;
    int totalOwedToMe = 0;
    int unsettledGroupCount = 0;

    for (final group in groups) {
      final members = await _memberRepository.getMembersByGroup(group.id);
      final transactions = await _transactionRepository.getTransactionsByGroup(
        group.id,
      );

      final balances = BalanceService.computeBalances(
        members: members,
        transactions: transactions,
      );

      bool groupIsUnsettled = false;
      for (final balance in balances) {
        if (balance.netAmountMinor != 0) {
          groupIsUnsettled = true;

          if (selfMemberId != null) {
            if (balance.memberId == selfMemberId) {
              if (balance.netAmountMinor < 0) {
                totalOwedByMe += balance.netAmountMinor.abs();
              } else {
                totalOwedToMe += balance.netAmountMinor;
              }
            }
          } else {
            // For MVP: aggregate all member balances across groups (not user-specific)
            // If no selfMemberId, we sum up all positive balances as "Owed to someone"
            // and all negative balances as "Owed by someone"
            if (balance.netAmountMinor < 0) {
              totalOwedByMe += balance.netAmountMinor.abs();
            } else {
              totalOwedToMe += balance.netAmountMinor;
            }
          }
        }
      }

      if (groupIsUnsettled) {
        unsettledGroupCount++;
      }
    }

    return GlobalBalanceSummary(
      totalOwedByMe: totalOwedByMe,
      totalOwedToMe: totalOwedToMe,
      groupCount: groups.length,
      unsettledGroupCount: unsettledGroupCount,
    );
  }

  Future<List<({String id, String name, int balance})>> getTopGroupBalances(
    String? selfMemberId, {
    int limit = 5,
  }) async {
    final groups = await _groupRepository.getAllGroups(includeArchived: false);
    final results = <({String id, String name, int balance})>[];

    for (final group in groups) {
      final members = await _memberRepository.getMembersByGroup(group.id);
      final transactions = await _transactionRepository.getTransactionsByGroup(
        group.id,
      );

      final balances = BalanceService.computeBalances(
        members: members,
        transactions: transactions,
      );

      int groupBalance = 0;
      for (final balance in balances) {
        if (selfMemberId != null) {
          if (balance.memberId == selfMemberId) {
            groupBalance = balance.netAmountMinor;
            break;
          }
        } else {
          // If no selfMemberId, use the absolute sum of all balances in group
          // as a measure of "activity" or just use total net if it's a 2-person group
          // For simplicity, let's just use the first member's balance if it's a personal app
          // Actually, let's sum all positive balances.
          if (balance.netAmountMinor > 0) {
            groupBalance += balance.netAmountMinor;
          }
        }
      }

      if (groupBalance != 0) {
        results.add((id: group.id, name: group.name, balance: groupBalance));
      }
    }

    results.sort((a, b) => b.balance.abs().compareTo(a.balance.abs()));
    return results.take(limit).toList();
  }
}
