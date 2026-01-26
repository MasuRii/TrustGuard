import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/providers.dart';
import '../../../../app/app.dart';
import '../../../../core/models/transaction.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../providers/dashboard_providers.dart';
import '../../../groups/presentation/groups_providers.dart';

class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentActivityAsync = ref.watch(recentActivityProvider);
    final activeGroupsAsync = ref.watch(activeGroupsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.recentActivity,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              activeGroupsAsync.maybeWhen(
                data: (groups) {
                  if (groups.isEmpty) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () {
                      // Navigate to the first group's transactions as a fallback
                      // In a real app, this might go to an "All Activity" screen
                      context.push('/group/${groups.first.id}/transactions');
                    },
                    child: Text(context.l10n.seeAll),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        recentActivityAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Center(
                  child: Text(
                    context.l10n.noRecentActivity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _RecentActivityItem(transaction: tx);
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space16),
              child: Text('Error: $error'),
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityItem extends ConsumerWidget {
  final Transaction transaction;

  const _RecentActivityItem({required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(moneyFormatterProvider);
    // Fetch group to get currency code
    final groupAsync = ref.watch(groupStreamProvider(transaction.groupId));

    return groupAsync.maybeWhen(
      data: (group) {
        final currencyCode = group?.currencyCode ?? 'USD';
        final isExpense = transaction.type == TransactionType.expense;
        final amount = isExpense
            ? transaction.expenseDetail?.totalAmountMinor ?? 0
            : transaction.transferDetail?.amountMinor ?? 0;

        return ListTile(
          onTap: () => context.push(
            '/group/${transaction.groupId}/transactions/${transaction.id}',
          ),
          leading: CircleAvatar(
            backgroundColor: isExpense
                ? Colors.orange.withValues(alpha: 0.1)
                : Colors.blue.withValues(alpha: 0.1),
            child: Icon(
              isExpense ? Icons.add_shopping_cart : Icons.sync_alt,
              color: isExpense ? Colors.orange : Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            transaction.note.isNotEmpty
                ? transaction.note
                : context.l10n.noNote,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_formatRelativeTime(transaction.occurredAt, context)),
          trailing: Text(
            formatMoney(amount, currencyCode: currencyCode),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red[700] : Colors.blue[700],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  String _formatRelativeTime(DateTime dateTime, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays >= 365) {
      return context.l10n.timeAgo('${(difference.inDays / 365).floor()}y');
    } else if (difference.inDays >= 30) {
      return context.l10n.timeAgo('${(difference.inDays / 30).floor()}mo');
    } else if (difference.inDays >= 1) {
      return context.l10n.timeAgo('${difference.inDays}d');
    } else if (difference.inHours >= 1) {
      return context.l10n.timeAgo('${difference.inHours}h');
    } else if (difference.inMinutes >= 1) {
      return context.l10n.timeAgo('${difference.inMinutes}m');
    } else {
      return context.l10n.timeAgo('now');
    }
  }
}
