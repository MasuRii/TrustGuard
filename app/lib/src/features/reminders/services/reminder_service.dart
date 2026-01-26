import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/group_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/reminder_repository.dart';
import '../../../core/platform/notification_service.dart';
import '../../../core/utils/money.dart';
import '../../balances/services/balance_service.dart';
import '../../../app/providers.dart';

/// Service to coordinate reminder settings and scheduled notifications.
class ReminderService {
  final ReminderRepository _reminderRepo;
  final GroupRepository _groupRepo;
  final MemberRepository _memberRepo;
  final TransactionRepository _transactionRepo;
  final NotificationService _notificationService;

  ReminderService({
    required ReminderRepository reminderRepo,
    required GroupRepository groupRepo,
    required MemberRepository memberRepo,
    required TransactionRepository transactionRepo,
    required NotificationService notificationService,
  }) : _reminderRepo = reminderRepo,
       _groupRepo = groupRepo,
       _memberRepo = memberRepo,
       _transactionRepo = transactionRepo,
       _notificationService = notificationService;

  /// Refreshes reminders for all groups.
  Future<void> refreshAllReminders() async {
    final allSettings = await _reminderRepo.getAllReminderSettings();
    for (final settings in allSettings) {
      await refreshReminderForGroup(settings.groupId);
    }
  }

  /// Refreshes the scheduled reminder for a specific group based on current balances.
  Future<void> refreshReminderForGroup(String groupId) async {
    final settings = await _reminderRepo.getReminderSettings(groupId);
    if (settings == null || !settings.enabled) {
      await _notificationService.cancelReminder(groupId);
      return;
    }

    final group = await _groupRepo.getGroupById(groupId);
    if (group == null) return;

    final members = await _memberRepo.getMembersByGroup(groupId);
    final transactions = await _transactionRepo.getTransactionsByGroup(groupId);

    final memberIds = members.map((m) => m.id).toList();
    final memberNames = {for (var m in members) m.id: m.displayName};

    final balances = BalanceService.computeBalances(
      memberIds: memberIds,
      memberNames: memberNames,
      transactions: transactions,
    );

    final netDebts = balances.where((b) => b.netAmountMinor < 0).toList();

    if (netDebts.isEmpty) {
      await _notificationService.cancelReminder(groupId);
      return;
    }

    final totalDebt = netDebts.fold<int>(
      0,
      (sum, b) => sum + b.netAmountMinor.abs(),
    );
    final summary =
        'Total outstanding: ${MoneyUtils.format(totalDebt, currencyCode: group.currencyCode)} across ${netDebts.length} members.';

    await _notificationService.scheduleReminder(
      groupId: groupId,
      title: 'Reminders for ${group.name}',
      body: summary,
      schedule: settings.schedule,
    );
  }
}

/// Provider for ReminderService.
final reminderServiceProvider = Provider((ref) {
  return ReminderService(
    reminderRepo: ref.watch(reminderRepositoryProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    memberRepo: ref.watch(memberRepositoryProvider),
    transactionRepo: ref.watch(transactionRepositoryProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});
