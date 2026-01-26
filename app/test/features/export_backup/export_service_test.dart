import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transfer.dart';
import 'package:trustguard/src/core/models/tag.dart';
import 'package:trustguard/src/features/export_backup/services/export_service.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

void main() {
  late ExportService exportService;
  late MockTransactionRepository mockTransactionRepository;
  late MockMemberRepository mockMemberRepository;

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockMemberRepository = MockMemberRepository();
    exportService = ExportService(
      transactionRepository: mockTransactionRepository,
      memberRepository: mockMemberRepository,
    );
  });

  group('ExportService', () {
    const groupId = 'group-1';

    test('generateCsv formats expenses and transfers correctly', () async {
      // Arrange
      final now = DateTime(2026, 1, 26, 12, 0);
      final members = [
        Member(
          id: 'm1',
          groupId: groupId,
          displayName: 'Alice',
          createdAt: now,
        ),
        Member(id: 'm2', groupId: groupId, displayName: 'Bob', createdAt: now),
      ];

      final transactions = [
        Transaction(
          id: 't1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now,
          note: 'Dinner',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 3000,
            splitType: SplitType.equal,
            participants: [
              ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1500),
              ExpenseParticipant(memberId: 'm2', owedAmountMinor: 1500),
            ],
          ),
          tags: [const Tag(id: 'tag1', groupId: groupId, name: 'Food')],
        ),
        Transaction(
          id: 't2',
          groupId: groupId,
          type: TransactionType.transfer,
          occurredAt: now.add(const Duration(hours: 1)),
          note: 'Payback',
          createdAt: now,
          updatedAt: now,
          transferDetail: const TransferDetail(
            fromMemberId: 'm2',
            toMemberId: 'm1',
            amountMinor: 1500,
          ),
        ),
      ];

      when(
        () => mockMemberRepository.getMembersByGroup(
          groupId,
          includeRemoved: true,
        ),
      ).thenAnswer((_) async => members);
      when(
        () => mockTransactionRepository.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => transactions);

      // Act
      final csv = await exportService.generateCsv(groupId);

      // Assert
      final lines = csv.split('\n');
      expect(lines.length, 3); // Header + 2 rows
      expect(lines[0], 'Date,Type,Amount,Payer/From,Participants/To,Note,Tags');

      // Expense row
      expect(
        lines[1],
        contains(
          '2026-01-26 12:00,expense,30.00,Alice,"Alice, Bob","Dinner","Food"',
        ),
      );

      // Transfer row
      expect(
        lines[2],
        contains('2026-01-26 13:00,transfer,15.00,Bob,Alice,"Payback",""'),
      );
    });

    test('generateTextSummary formats balances and suggestions correctly', () async {
      // This would require mocking BalanceService and SettlementService if they were instances,
      // but they are static. So we just verify the output based on the static logic.
      // Since they are pure functions, we can trust them if their own tests pass.

      // Arrange
      final now = DateTime(2026, 1, 26, 12, 0);
      final members = [
        Member(
          id: 'm1',
          groupId: groupId,
          displayName: 'Alice',
          createdAt: now,
        ),
        Member(id: 'm2', groupId: groupId, displayName: 'Bob', createdAt: now),
      ];
      final transactions = [
        Transaction(
          id: 't1',
          groupId: groupId,
          type: TransactionType.expense,
          occurredAt: now,
          note: 'Lunch',
          createdAt: now,
          updatedAt: now,
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 2000,
            splitType: SplitType.equal,
            participants: [
              ExpenseParticipant(memberId: 'm1', owedAmountMinor: 1000),
              ExpenseParticipant(memberId: 'm2', owedAmountMinor: 1000),
            ],
          ),
        ),
      ];

      when(
        () => mockMemberRepository.getMembersByGroup(
          groupId,
          includeRemoved: true,
        ),
      ).thenAnswer((_) async => members);
      when(
        () => mockTransactionRepository.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => transactions);

      // Act
      final summary = await exportService.generateTextSummary(
        groupId,
        'Test Group',
      );

      // Assert
      expect(summary, contains('TrustGuard Summary: Test Group'));
      expect(summary, contains('Alice: Owed 10.00'));
      expect(summary, contains('Bob: Owes 10.00'));
      expect(summary, contains('Bob -> Alice: 10.00'));
    });
  });
}
