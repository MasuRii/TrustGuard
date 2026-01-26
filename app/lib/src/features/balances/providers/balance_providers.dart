import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/providers.dart';
import '../../../core/models/settlement_suggestion.dart';
import '../services/balance_service.dart';
import '../services/settlement_service.dart';

/// Provider for the self-member ID in a specific group.
/// Persisted in SharedPreferences.
final groupSelfMemberProvider =
    StateNotifierProvider.family<GroupSelfMemberNotifier, String?, String>((
      ref,
      groupId,
    ) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return GroupSelfMemberNotifier(prefs, groupId);
    });

class GroupSelfMemberNotifier extends StateNotifier<String?> {
  final SharedPreferences _prefs;
  final String _groupId;
  static const _keyPrefix = 'self_member_';

  GroupSelfMemberNotifier(this._prefs, this._groupId)
    : super(_prefs.getString('$_keyPrefix$_groupId'));

  Future<void> setSelfMember(String? memberId) async {
    state = memberId;
    if (memberId == null) {
      await _prefs.remove('$_keyPrefix$_groupId');
    } else {
      await _prefs.setString('$_keyPrefix$_groupId', memberId);
    }
  }
}

/// Provider that computes settlement suggestions for a group.
final settlementSuggestionsProvider = Provider.autoDispose
    .family<List<SettlementSuggestion>, String>((ref, groupId) {
      final balancesAsync = ref.watch(groupBalancesProvider(groupId));
      return balancesAsync.maybeWhen(
        data: (balances) =>
            SettlementService.computeSettlementSuggestions(balances),
        orElse: () => [],
      );
    });
