import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/repositories/budget_repository.dart';
import '../../../core/platform/notification_service.dart';
import 'budget_service.dart';
import '../../../core/models/budget.dart';
import '../../../app/providers.dart';
import 'package:intl/intl.dart';

class BudgetAlertService {
  final BudgetRepository _budgetRepository;
  final BudgetService _budgetService;
  final NotificationService _notificationService;

  // In-memory cache to prevent spamming notifications in the same session
  final Set<String> _notifiedBudgets = {};

  BudgetAlertService(
    this._budgetRepository,
    this._budgetService,
    this._notificationService,
  );

  /// Checks all active budgets across all groups and sends alerts if thresholds are exceeded.
  Future<void> checkAllBudgets() async {
    final budgets = await _budgetRepository.getAllActiveBudgets();
    await _processBudgets(budgets);
  }

  /// Checks active budgets for a specific group.
  Future<void> checkGroupBudgets(String groupId) async {
    final budgets = await _budgetRepository.getBudgetsByGroup(groupId);
    final activeBudgets = budgets.where((b) => b.isActive).toList();
    await _processBudgets(activeBudgets);
  }

  Future<void> _processBudgets(List<Budget> budgets) async {
    for (final budget in budgets) {
      // Skip if already notified in this session
      // Note: This resets on app restart, which is acceptable behavior
      // A more persistent approach would require storing 'lastNotifiedAt' in DB
      if (_notifiedBudgets.contains(budget.id)) continue;

      final progress = await _budgetService.getBudgetProgress(budget);
      final thresholdPercent = budget.alertThreshold / 100.0;

      if (progress.percentUsed >= thresholdPercent) {
        await _sendAlert(
          budget,
          progress.percentUsed,
          progress.spentMinor,
          budget.limitMinor,
        );
        _notifiedBudgets.add(budget.id);
      }
    }
  }

  Future<void> _sendAlert(
    Budget budget,
    double percent,
    int spent,
    int limit,
  ) async {
    final percentStr = (percent * 100).toInt();
    final formatter = NumberFormat.simpleCurrency(
      name: budget.currencyCode,
      decimalDigits: 0,
    );
    final spentStr = formatter.format(spent / 100);
    final limitStr = formatter.format(limit / 100);

    final title = 'Budget Alert: ${budget.name}';
    final body =
        'You\'ve used $percentStr% of your budget ($spentStr / $limitStr)';

    // Use budget.id hashCode for notification ID to avoid collisions
    // Payload is groupId to navigate to the group
    await _notificationService.showImmediateNotification(
      id: budget.id.hashCode,
      title: title,
      body: body,
      payload: budget.groupId,
    );
  }
}

final budgetAlertServiceProvider = Provider<BudgetAlertService>((ref) {
  return BudgetAlertService(
    ref.watch(budgetRepositoryProvider),
    ref.watch(budgetServiceProvider),
    ref.watch(notificationServiceProvider),
  );
});
