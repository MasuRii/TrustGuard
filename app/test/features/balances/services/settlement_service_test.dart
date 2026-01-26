import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/balance.dart';
import 'package:trustguard/src/features/balances/services/settlement_service.dart';

void main() {
  group('SettlementService', () {
    test('computes simple settlement correctly', () {
      final balances = [
        const MemberBalance(
          memberId: 'm1',
          memberName: 'Alice',
          netAmountMinor: 1000,
          isCreditor: true,
        ),
        const MemberBalance(
          memberId: 'm2',
          memberName: 'Bob',
          netAmountMinor: -1000,
          isCreditor: false,
        ),
      ];

      final suggestions = SettlementService.computeSettlementSuggestions(
        balances,
      );

      expect(suggestions.length, 1);
      expect(suggestions[0].fromMemberId, 'm2');
      expect(suggestions[0].toMemberId, 'm1');
      expect(suggestions[0].amountMinor, 1000);
    });

    test('computes complex settlement correctly (greedy)', () {
      final balances = [
        const MemberBalance(
          memberId: 'm1',
          memberName: 'Alice',
          netAmountMinor: 2000,
          isCreditor: true,
        ),
        const MemberBalance(
          memberId: 'm2',
          memberName: 'Bob',
          netAmountMinor: -1500,
          isCreditor: false,
        ),
        const MemberBalance(
          memberId: 'm3',
          memberName: 'Charlie',
          netAmountMinor: -500,
          isCreditor: false,
        ),
      ];

      final suggestions = SettlementService.computeSettlementSuggestions(
        balances,
      );

      // Largest debtor (Bob, 1500) pays largest creditor (Alice, 2000)
      // Then Charlie (500) pays Alice (remaining 500)
      expect(suggestions.length, 2);

      expect(suggestions[0].fromMemberId, 'm2');
      expect(suggestions[0].toMemberId, 'm1');
      expect(suggestions[0].amountMinor, 1500);

      expect(suggestions[1].fromMemberId, 'm3');
      expect(suggestions[1].toMemberId, 'm1');
      expect(suggestions[1].amountMinor, 500);
    });

    test('handles multiple creditors and debtors', () {
      final balances = [
        const MemberBalance(
          memberId: 'm1',
          memberName: 'Alice',
          netAmountMinor: 1000,
          isCreditor: true,
        ),
        const MemberBalance(
          memberId: 'm2',
          memberName: 'Bob',
          netAmountMinor: 500,
          isCreditor: true,
        ),
        const MemberBalance(
          memberId: 'm3',
          memberName: 'Charlie',
          netAmountMinor: -800,
          isCreditor: false,
        ),
        const MemberBalance(
          memberId: 'm4',
          memberName: 'David',
          netAmountMinor: -700,
          isCreditor: false,
        ),
      ];

      final suggestions = SettlementService.computeSettlementSuggestions(
        balances,
      );

      // Total credit: 1500, Total debt: 1500
      final totalSettled = suggestions.fold(0, (sum, s) => sum + s.amountMinor);
      expect(totalSettled, 1500);
      expect(suggestions.isNotEmpty, true);
    });
  });
}
