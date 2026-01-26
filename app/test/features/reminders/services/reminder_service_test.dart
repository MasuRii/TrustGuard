import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/group_repository.dart';
import 'package:trustguard/src/core/database/repositories/member_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/database/repositories/reminder_repository.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/reminder_settings.dart';
import 'package:trustguard/src/features/reminders/services/reminder_service.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class MockMemberRepository extends Mock implements MemberRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockReminderRepository extends Mock implements ReminderRepository {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late ReminderService reminderService;
  late MockGroupRepository mockGroupRepo;
  late MockMemberRepository mockMemberRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockReminderRepository mockReminderRepo;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    registerFallbackValue(ReminderSchedule.daily);
  });

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockMemberRepo = MockMemberRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockReminderRepo = MockReminderRepository();
    mockNotificationService = MockNotificationService();

    reminderService = ReminderService(
      reminderRepo: mockReminderRepo,
      groupRepo: mockGroupRepo,
      memberRepo: mockMemberRepo,
      transactionRepo: mockTransactionRepo,
      notificationService: mockNotificationService,
    );

    // Default mock behavior
    when(
      () => mockNotificationService.cancelReminder(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.scheduleReminder(
        groupId: any(named: 'groupId'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        schedule: any(named: 'schedule'),
      ),
    ).thenAnswer((_) async {});
  });

  group('ReminderService', () {
    const groupId = 'group1';
    final group = Group(
      id: groupId,
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime.now(),
    );
    final member1 = Member(
      id: 'm1',
      groupId: groupId,
      displayName: 'Alice',
      createdAt: DateTime.now(),
    );
    final member2 = Member(
      id: 'm2',
      groupId: groupId,
      displayName: 'Bob',
      createdAt: DateTime.now(),
    );

    test('refreshReminderForGroup cancels if reminders disabled', () async {
      when(() => mockReminderRepo.getReminderSettings(groupId)).thenAnswer(
        (_) async => const ReminderSettings(
          groupId: groupId,
          enabled: false,
          schedule: ReminderSchedule.daily,
        ),
      );

      await reminderService.refreshReminderForGroup(groupId);

      verify(() => mockNotificationService.cancelReminder(groupId)).called(1);
      verifyNever(
        () => mockNotificationService.scheduleReminder(
          groupId: any(named: 'groupId'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          schedule: any(named: 'schedule'),
        ),
      );
    });

    test('refreshReminderForGroup schedules if there are debts', () async {
      when(() => mockReminderRepo.getReminderSettings(groupId)).thenAnswer(
        (_) async => const ReminderSettings(
          groupId: groupId,
          enabled: true,
          schedule: ReminderSchedule.daily,
        ),
      );
      when(
        () => mockGroupRepo.getGroupById(groupId),
      ).thenAnswer((_) async => group);
      when(
        () => mockMemberRepo.getMembersByGroup(groupId),
      ).thenAnswer((_) async => [member1, member2]);

      // Member 1 paid $10, shared with Member 2
      final transaction = Transaction(
        id: 't1',
        groupId: groupId,
        type: TransactionType.expense,
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        note: 'Test expense',
        expenseDetail: const ExpenseDetail(
          payerMemberId: 'm1',
          totalAmountMinor: 1000,
          splitType: SplitType.equal,
          participants: [
            ExpenseParticipant(memberId: 'm1', owedAmountMinor: 500),
            ExpenseParticipant(memberId: 'm2', owedAmountMinor: 500),
          ],
        ),
      );

      when(
        () => mockTransactionRepo.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => [transaction]);

      await reminderService.refreshReminderForGroup(groupId);

      verify(
        () => mockNotificationService.scheduleReminder(
          groupId: groupId,
          title: any(named: 'title', that: contains('Test Group')),
          body: any(named: 'body', that: contains('1 member')),
          schedule: ReminderSchedule.daily,
        ),
      ).called(1);
    });

    test('refreshReminderForGroup cancels if no debts', () async {
      when(() => mockReminderRepo.getReminderSettings(groupId)).thenAnswer(
        (_) async => const ReminderSettings(
          groupId: groupId,
          enabled: true,
          schedule: ReminderSchedule.daily,
        ),
      );
      when(
        () => mockGroupRepo.getGroupById(groupId),
      ).thenAnswer((_) async => group);
      when(
        () => mockMemberRepo.getMembersByGroup(groupId),
      ).thenAnswer((_) async => [member1, member2]);
      when(
        () => mockTransactionRepo.getTransactionsByGroup(groupId),
      ).thenAnswer((_) async => []); // No transactions

      await reminderService.refreshReminderForGroup(groupId);

      verify(() => mockNotificationService.cancelReminder(groupId)).called(1);
    });
  });
}
