import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/models/member.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../core/utils/money.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transaction_filter_sheet.dart';
import 'transactions_providers.dart';

class TransactionListScreen extends ConsumerWidget {
  final String groupId;

  const TransactionListScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsByGroupProvider(groupId));
    final membersAsync = ref.watch(membersByGroupProvider(groupId));
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final filter = ref.watch(transactionFilterProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: !filter.isEmpty,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) => TransactionFilterSheet(groupId: groupId),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search note...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.searchQuery?.isNotEmpty ?? false
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(transactionFilterProvider(groupId).notifier)
                              .state = filter.copyWith(
                            searchQuery: '',
                          );
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                ref.read(transactionFilterProvider(groupId).notifier).state =
                    filter.copyWith(searchQuery: value);
              },
            ),
          ),
          if (!filter.isEmpty) _ActiveFilterChips(groupId: groupId),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return filter.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No transactions yet',
                          message:
                              'Add your first expense or transfer to get started.',
                          actionLabel: 'Add Expense',
                          onActionPressed: () => context.push(
                            '/group/$groupId/transactions/add-expense',
                          ),
                        )
                      : EmptyState(
                          icon: Icons.search_off,
                          title: 'No results found',
                          message: 'Try adjusting your filters.',
                          actionLabel: 'Clear All Filters',
                          onActionPressed: () {
                            ref
                                    .read(
                                      transactionFilterProvider(
                                        groupId,
                                      ).notifier,
                                    )
                                    .state =
                                const TransactionFilter();
                          },
                        );
                }

                return membersAsync.when(
                  data: (members) {
                    final memberMap = {
                      for (var m in members) m.id: m.displayName,
                    };

                    return groupAsync.when(
                      data: (group) {
                        final currencyCode = group?.currencyCode ?? 'USD';

                        return RefreshIndicator(
                          onRefresh: () => ref.refresh(
                            transactionsByGroupProvider(groupId).future,
                          ),
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppTheme.space8),
                            itemCount: transactions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              return _TransactionListItem(
                                transaction: tx,
                                memberMap: memberMap,
                                currencyCode: currencyCode,
                                onTap: () => context.push(
                                  '/group/$groupId/transactions/${tx.id}',
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Error: $error')),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddMenu(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_shopping_cart,
                color: Colors.orange,
              ),
              title: const Text('Add Expense'),
              onTap: () {
                context.pop();
                context.push('/group/$groupId/transactions/add-expense');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt, color: Colors.blue),
              title: const Text('Add Transfer'),
              onTap: () {
                context.pop();
                context.push('/group/$groupId/transactions/add-transfer');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveFilterChips extends ConsumerWidget {
  final String groupId;

  const _ActiveFilterChips({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(transactionFilterProvider(groupId));
    final membersAsync = ref.watch(membersByGroupProvider(groupId));
    final tagsAsync = ref.watch(tagsProvider(groupId));

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
        children: [
          if (filter.tagIds?.isNotEmpty ?? false)
            tagsAsync.maybeWhen(
              data: (List<Tag> tags) {
                return Wrap(
                  children: filter.tagIds!.map((id) {
                    final tag = tags.firstWhere(
                      (t) => t.id == id,
                      orElse: () => Tag(id: id, groupId: groupId, name: id),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Tag: ${tag.name}'),
                        onDeleted: () {
                          final newTagIds = Set<String>.from(filter.tagIds!)
                            ..remove(id);
                          ref
                              .read(transactionFilterProvider(groupId).notifier)
                              .state = filter.copyWith(
                            tagIds: newTagIds,
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          if (filter.memberIds?.isNotEmpty ?? false)
            membersAsync.maybeWhen(
              data: (List<Member> members) {
                return Wrap(
                  children: filter.memberIds!.map((id) {
                    final member = members.firstWhere(
                      (m) => m.id == id,
                      orElse: () => Member(
                        id: id,
                        groupId: groupId,
                        displayName: id,
                        createdAt: DateTime.now(),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Member: ${member.displayName}'),
                        onDeleted: () {
                          final newMemberIds = Set<String>.from(
                            filter.memberIds!,
                          )..remove(id);
                          ref
                              .read(transactionFilterProvider(groupId).notifier)
                              .state = filter.copyWith(
                            memberIds: newMemberIds,
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          if (filter.startDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'After: ${filter.startDate!.toString().split(' ')[0]}',
                ),
                onDeleted: () {
                  ref.read(transactionFilterProvider(groupId).notifier).state =
                      filter.copyWith(startDate: null);
                },
              ),
            ),
          if (filter.endDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'Before: ${filter.endDate!.toString().split(' ')[0]}',
                ),
                onDeleted: () {
                  ref.read(transactionFilterProvider(groupId).notifier).state =
                      filter.copyWith(endDate: null);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final Map<String, String> memberMap;
  final String currencyCode;
  final VoidCallback onTap;

  const _TransactionListItem({
    required this.transaction,
    required this.memberMap,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == TransactionType.expense;
    final amount = isExpense
        ? transaction.expenseDetail?.totalAmountMinor ?? 0
        : transaction.transferDetail?.amountMinor ?? 0;

    final dateStr = DateFormat.yMMMd().format(transaction.occurredAt);

    String subTitle = '';
    if (isExpense) {
      final payerName =
          memberMap[transaction.expenseDetail?.payerMemberId] ?? 'Unknown';
      final participantsCount =
          transaction.expenseDetail?.participants.length ?? 0;
      subTitle = 'Paid by $payerName for $participantsCount members';
    } else {
      final fromName =
          memberMap[transaction.transferDetail?.fromMemberId] ?? 'Unknown';
      final toName =
          memberMap[transaction.transferDetail?.toMemberId] ?? 'Unknown';
      subTitle = '$fromName → $toName';
    }

    return ListTile(
      onTap: onTap,
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              transaction.note.isNotEmpty ? transaction.note : 'No note',
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            MoneyUtils.format(amount, currencyCode: currencyCode),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red[700] : Colors.blue[700],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subTitle),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
          if (transaction.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space4),
            Wrap(
              spacing: AppTheme.space4,
              children: transaction.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag.name,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
