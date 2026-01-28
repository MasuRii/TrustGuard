import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/sharing/models/shareable_expense.dart';
import 'package:trustguard/src/features/sharing/services/qr_generation_service.dart';

class MockMemberRepository extends Mock implements MemberRepository {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late QrGenerationService service;
  late MockMemberRepository mockMemberRepository;
  late MockGroupRepository mockGroupRepository;

  setUp(() {
    mockMemberRepository = MockMemberRepository();
    mockGroupRepository = MockGroupRepository();
    service = QrGenerationService(
      memberRepository: mockMemberRepository,
      groupRepository: mockGroupRepository,
    );
  });

  group('QrGenerationService', () {
    final testGroup = Group(
      id: 'g1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime(2023, 1, 1),
    );

    final testMembers = [
      Member(
        id: 'm1',
        groupId: 'g1',
        displayName: 'Alice',
        createdAt: DateTime(2023, 1, 1),
      ),
      Member(
        id: 'm2',
        groupId: 'g1',
        displayName: 'Bob',
        createdAt: DateTime(2023, 1, 1),
      ),
    ];

    final testTransaction = Transaction(
      id: 'tx1',
      groupId: 'g1',
      type: TransactionType.expense,
      note: 'Dinner',
      occurredAt: DateTime(2023, 1, 1),
      createdAt: DateTime(2023, 1, 1),
      updatedAt: DateTime(2023, 1, 1),
      expenseDetail: const ExpenseDetail(
        payerMemberId: 'm1',
        totalAmountMinor: 1000,
        splitType: SplitType.equal,
        participants: [
          ExpenseParticipant(memberId: 'm1', owedAmountMinor: 500),
          ExpenseParticipant(memberId: 'm2', owedAmountMinor: 500),
        ],
      ),
      tags: [],
    );

    test('generateForTransaction creates valid ShareableExpense', () async {
      when(
        () => mockGroupRepository.getGroupById('g1'),
      ).thenAnswer((_) async => testGroup);
      when(
        () => mockMemberRepository.getMembersByGroup('g1'),
      ).thenAnswer((_) async => testMembers);

      final result = await service.generateForTransaction(testTransaction);

      expect(result.description, 'Dinner');
      expect(result.amountMinor, 1000);
      expect(result.payerName, 'Alice');
      expect(result.participants, hasLength(2));
      expect(result.participants[0].name, 'Alice');
      expect(result.participants[1].name, 'Bob');
      expect(result.sourceId, 'tx1');
    });

    test('generateForBatch creates valid ShareableBatch', () async {
      when(
        () => mockGroupRepository.getGroupById('g1'),
      ).thenAnswer((_) async => testGroup);
      when(
        () => mockMemberRepository.getMembersByGroup('g1'),
      ).thenAnswer((_) async => testMembers);

      final result = await service.generateForBatch('Trip', [testTransaction]);

      expect(result.groupName, 'Trip');
      expect(result.expenses, hasLength(1));
      expect(result.expenses[0].description, 'Dinner');
    });

    test('getQrData returns correct format', () {
      final expense = ShareableExpense(
        type: ShareableType.expense,
        description: 'Test',
        amountMinor: 100,
        currencyCode: 'USD',
        date: DateTime(2023, 1, 1),
        payerName: 'Alice',
        participants: [],
        sourceId: 'tx1',
      );

      final result = service.getQrData(expense);
      expect(result, startsWith('TG:'));
    });
  });
}
