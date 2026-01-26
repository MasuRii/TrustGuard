import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../core/models/member.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/theme/app_theme.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transaction_filter_sheet.dart';
import 'transactions_providers.dart';
import '../providers/paginated_transactions_provider.dart';
import '../utils/transaction_grouper.dart';
import 'widgets/date_group_header.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TransactionListScreen({super.key, required this.groupId});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(paginatedTransactionsProvider(widget.groupId).notifier)
          .loadMore();
    }
  }

  List<dynamic> _flattenTransactions(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];

    final Map<DateTime, List<Transaction>> grouped = groupTransactionsByDate(
      transactions,
    );
    final List<dynamic> items = [];

    grouped.forEach((date, txs) {
      items.add(date);
      items.addAll(txs);
    });

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      paginatedTransactionsProvider(widget.groupId),
    );
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final filter = ref.watch(transactionFilterProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.transactionsTitle),
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
                builder: (context) =>
                    TransactionFilterSheet(groupId: widget.groupId),
              );
            },
            tooltip: context.l10n.filterTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.space8),
            child: Semantics(
              label: 'Search transactions by note',
              child: TextField(
                decoration: InputDecoration(
                  hintText: context.l10n.searchNote,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filter.searchQuery?.isNotEmpty ?? false
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ref
                                .read(
                                  transactionFilterProvider(
                                    widget.groupId,
                                  ).notifier,
                                )
                                .state = filter.copyWith(
                              searchQuery: '',
                            );
                          },
                          tooltip: context.l10n.clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  ref
                      .read(transactionFilterProvider(widget.groupId).notifier)
                      .state = filter.copyWith(
                    searchQuery: value,
                  );
                },
              ),
            ),
          ),

          if (!filter.isEmpty) _ActiveFilterChips(groupId: widget.groupId),
          Expanded(
            child: transactionsAsync.when(
              data: (paginatedState) {
                final transactions = paginatedState.transactions;
                if (transactions.isEmpty) {
                  return filter.isEmpty
                      ? EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: context.l10n.noTransactionsYet,
                          message: context.l10n.noTransactionsMessage,
                          actionLabel: context.l10n.addExpense,
                          onActionPressed: () => context.push(
                            '/group/${widget.groupId}/transactions/add-expense',
                          ),
                        )
                      : EmptyState(
                          icon: Icons.search_off,
                          title: context.l10n.noResultsFound,
                          message: context.l10n.tryAdjustingFilters,
                          actionLabel: context.l10n.clearAllFilters,
                          onActionPressed: () {
                            ref
                                    .read(
                                      transactionFilterProvider(
                                        widget.groupId,
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
                        final listItems = _flattenTransactions(transactions);

                        return RefreshIndicator(
                          onRefresh: () => ref
                              .read(
                                paginatedTransactionsProvider(
                                  widget.groupId,
                                ).notifier,
                              )
                              .refresh(),
                          child: ListView.separated(
                            controller: _scrollController,
                            key: const PageStorageKey('transaction_list'),
                            padding: const EdgeInsets.all(AppTheme.space8),
                            itemCount:
                                listItems.length +
                                (paginatedState.hasMore ? 1 : 0),
                            separatorBuilder: (context, index) {
                              if (index >= listItems.length) {
                                return const SizedBox.shrink();
                              }
                              final currentItem = listItems[index];
                              if (currentItem is DateTime) {
                                return const SizedBox.shrink();
                              }
                              if (index + 1 < listItems.length) {
                                final nextItem = listItems[index + 1];
                                if (nextItem is DateTime) {
                                  return const SizedBox.shrink();
                                }
                              }
                              return const Divider();
                            },
                            itemBuilder: (context, index) {
                              if (index == listItems.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(AppTheme.space16),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final item = listItems[index];
                              if (item is DateTime) {
                                return DateGroupHeader(date: item);
                              }

                              final tx = item as Transaction;
                              return _TransactionListItem(
                                key: ValueKey(tx.id),
                                transaction: tx,
                                memberMap: memberMap,
                                currencyCode: currencyCode,
                                onTap: () => context.push(
                                  '/group/${widget.groupId}/transactions/${tx.id}',
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
              title: Text(context.l10n.addExpense),
              onTap: () {
                context.pop();
                context.push(
                  '/group/${widget.groupId}/transactions/add-expense',
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt, color: Colors.blue),
              title: Text(context.l10n.addTransfer),
              onTap: () {
                context.pop();
                context.push(
                  '/group/${widget.groupId}/transactions/add-transfer',
                );
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
                        label: Text(context.l10n.tagFilter(tag.name)),
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
                        label: Text(
                          context.l10n.memberFilter(member.displayName),
                        ),
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
                  context.l10n.afterFilter(
                    filter.startDate!.toString().split(' ')[0],
                  ),
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
                  context.l10n.beforeFilter(
                    filter.endDate!.toString().split(' ')[0],
                  ),
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

class _TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final Map<String, String> memberMap;
  final String currencyCode;
  final VoidCallback onTap;

  const _TransactionListItem({
    super.key,
    required this.transaction,
    required this.memberMap,
    required this.currencyCode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatMoney = ref.watch(moneyFormatterProvider);
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
      subTitle = context.l10n.paidByFor(payerName, participantsCount);
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
              transaction.note.isNotEmpty
                  ? transaction.note
                  : context.l10n.noNote,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            formatMoney(amount, currencyCode: currencyCode),
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
