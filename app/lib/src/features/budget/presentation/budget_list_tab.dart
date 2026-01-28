import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/budget.dart';
import '../../../ui/theme/app_theme.dart';
import 'widgets/budget_progress_card.dart';

class BudgetListTab extends ConsumerWidget {
  final String groupId;

  const BudgetListTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(activeBudgetsProvider(groupId));

    return budgetsAsync.when(
      data: (budgets) {
        if (budgets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.savings_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'No active budgets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                FilledButton.icon(
                  onPressed: () =>
                      context.push('/group/$groupId/budget-settings'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Budget'),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppTheme.space16),
          itemCount: budgets.length + 1, // +1 for extra space at bottom for FAB
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppTheme.space16),
          itemBuilder: (context, index) {
            if (index == budgets.length) {
              return const SizedBox(height: 80); // Space for FAB
            }
            final budget = budgets[index];
            return _BudgetListItem(budget: budget);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _BudgetListItem extends ConsumerWidget {
  final Budget budget;

  const _BudgetListItem({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(budgetProgressProvider(budget));

    return progressAsync.when(
      data: (progress) {
        return BudgetProgressCard(
          progress: progress,
          onTap: () => context.push(
            '/group/${budget.groupId}/budget-settings',
            extra: budget,
          ),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => SizedBox(
        height: 100,
        child: Center(child: Text('Error loading budget: $error')),
      ),
    );
  }
}
