import 'dart:io' show Platform;
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../app/app.dart';
import '../../../core/services/keyboard_shortcut_service.dart';
import '../../../core/models/member.dart';
import '../../../core/models/tag.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../core/utils/haptics.dart';
import '../../../ui/components/empty_state.dart';
import '../../../ui/animations/lottie_assets.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/animations/animation_config.dart';
import '../../../ui/components/skeletons/skeleton_list.dart';
import '../../groups/presentation/groups_providers.dart';
import 'transaction_detail_screen.dart';
import 'transaction_filter_sheet.dart';
import 'transactions_providers.dart';
import '../providers/paginated_transactions_provider.dart';
import '../models/paginated_transactions_state.dart';
import '../utils/transaction_grouper.dart';
import 'widgets/date_group_header.dart';
import '../../../ui/animations/staggered_list_animation.dart';
import '../../../core/services/undoable_action_service.dart';
import '../../../ui/components/undo_snackbar.dart';
import '../../../ui/components/speed_dial_fab.dart';
import 'quick_add_expense_sheet.dart';
import '../../../core/services/coachmark_service.dart';
import '../../../ui/components/coachmark_overlay.dart';
import '../../../ui/components/animated_filter_badge.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TransactionListScreen({super.key, required this.groupId});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;
  StaggeredListAnimationController? _animationController;
  int _lastAnimatedIndex = -1;
  final _firstTransactionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _animationController?.dispose();
    super.dispose();
  }

  void _handleData(PaginatedTransactionsState paginatedState) {
    final transactions = paginatedState.transactions;
    if (transactions.isEmpty) {
      if (mounted) {
        setState(() {
          _lastAnimatedIndex = -1;
          _animationController?.dispose();
          _animationController = null;
        });
      }
      return;
    }

    // Detect fresh load: either no controller yet, or list got shorter (e.g. filter change)
    if (_animationController == null ||
        transactions.length < (_lastAnimatedIndex + 1)) {
      if (mounted) {
        setState(() {
          _animationController?.dispose();
          _animationController = StaggeredListAnimationController(
            vsync: this,
            itemCount: transactions.length,
          );
          _lastAnimatedIndex = transactions.length - 1;
        });
        _animationController!.startAnimation();
      }
    } else if (transactions.length > (_lastAnimatedIndex + 1)) {
      // Pagination load: update index but don't restart stagger
      if (mounted) {
        setState(() {
          _lastAnimatedIndex = transactions.length - 1;
        });
      }
    }

    _showSwipeCoachmark();
  }

  void _showSwipeCoachmark() {
    // Disable coachmarks in tests to avoid blocking interaction in existing tests
    if (kDebugMode && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    final coachmarkService = ref.read(coachmarkServiceProvider);
    if (coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _firstTransactionKey.currentContext == null) return;
        CoachmarkOverlay.show(
          context: context,
          targetKey: _firstTransactionKey,
          message: context.l10n.swipeActionHint,
          onDismiss: () =>
              coachmarkService.markShown(CoachmarkKey.transactionSwipeHint),
        );
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(paginatedTransactionsProvider(widget.groupId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      paginatedTransactionsProvider(widget.groupId),
    );
    final membersAsync = ref.watch(membersByGroupProvider(widget.groupId));
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));
    final filter = ref.watch(transactionFilterProvider(widget.groupId));

    ref.listen(paginatedTransactionsProvider(widget.groupId), (previous, next) {
      next.whenData(_handleData);
    });

    // Initial load check
    transactionsAsync.whenData((paginatedState) {
      if (paginatedState.transactions.isNotEmpty &&
          _animationController == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleData(paginatedState);
        });
      }
    });

    return Actions(
      actions: {
        SearchIntent: CallbackAction<SearchIntent>(
          onInvoke: (intent) {
            _searchFocusNode.requestFocus();
            return null;
          },
        ),
        NewExpenseIntent: CallbackAction<NewExpenseIntent>(
          onInvoke: (intent) {
            context.push('/group/${widget.groupId}/transactions/add-expense');
            return null;
          },
        ),
        NewTransferIntent: CallbackAction<NewTransferIntent>(
          onInvoke: (intent) {
            context.push('/group/${widget.groupId}/transactions/add-transfer');
            return null;
          },
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.transactionsTitle),
          actions: [
            IconButton(
              icon: AnimatedFilterBadge(
                isActive: !filter.isEmpty,
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
                  focusNode: _searchFocusNode,
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
                        .read(
                          transactionFilterProvider(widget.groupId).notifier,
                        )
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
                            lottiePath: LottieAssets.emptyList,
                            svgPath: 'assets/illustrations/no_transactions.svg',
                            icon: Icons.receipt_long_outlined,
                            title: context.l10n.noTransactionsYet,
                            message: context.l10n.noTransactionsMessage,
                            actionLabel: context.l10n.addExpense,
                            onActionPressed: () => context.push(
                              '/group/${widget.groupId}/transactions/add-expense',
                            ),
                          )
                        : EmptyState(
                            svgPath: 'assets/illustrations/no_results.svg',
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
                          final grouped = groupTransactionsByDate(transactions);

                          // Pre-calculate global indices for staggered animation
                          final txToIndex = <String, int>{};
                          int currentGlobalIndex = 0;
                          for (final entry in grouped.entries) {
                            for (final tx in entry.value) {
                              txToIndex[tx.id] = currentGlobalIndex++;
                            }
                          }

                          return RefreshIndicator(
                            onRefresh: () => ref
                                .read(
                                  paginatedTransactionsProvider(
                                    widget.groupId,
                                  ).notifier,
                                )
                                .refresh(),
                            child: CustomScrollView(
                              controller: _scrollController,
                              key: const PageStorageKey('transaction_list'),
                              slivers: [
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: AppTheme.space8),
                                ),
                                for (final entry in grouped.entries) ...[
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _DateHeaderDelegate(
                                      date: entry.key,
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.space8,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final tx = entry.value[index];
                                        final globalIndex =
                                            txToIndex[tx.id] ?? 0;

                                        final item = Column(
                                          children: [
                                            _TransactionListItem(
                                              key: globalIndex == 0
                                                  ? _firstTransactionKey
                                                  : ValueKey(tx.id),
                                              transaction: tx,
                                              memberMap: memberMap,
                                              currencyCode: currencyCode,
                                            ),
                                            if (index < entry.value.length - 1)
                                              const Divider(),
                                          ],
                                        );

                                        // Only wrap in StaggeredListItem if it's within the animated range
                                        // and we have a controller.
                                        if (_animationController != null &&
                                            globalIndex <
                                                _animationController!
                                                    .itemCount) {
                                          return StaggeredListItem(
                                            animation: _animationController!
                                                .getAnimation(globalIndex),
                                            child: item,
                                          );
                                        }

                                        return item;
                                      }, childCount: entry.value.length),
                                    ),
                                  ),
                                ],
                                if (paginatedState.hasMore)
                                  const SliverToBoxAdapter(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(
                                          AppTheme.space16,
                                        ),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                  ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: AppTheme.space32),
                                ),
                              ],
                            ),
                          );
                        },
                        loading: () => const SkeletonList(),
                        error: (error, stack) =>
                            Center(child: Text('Error: $error')),
                      );
                    },
                    loading: () => const SkeletonList(),
                    error: (error, stack) =>
                        Center(child: Text('Error: $error')),
                  );
                },
                loading: () => const SkeletonList(),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
        floatingActionButton: SpeedDialFab(
          items: [
            SpeedDialItem(
              icon: Icons.bolt,
              label: context.l10n.quickAdd,
              onPressed: _showQuickAdd,
            ),
            SpeedDialItem(
              icon: Icons.add_shopping_cart,
              label: context.l10n.addExpense,
              onPressed: () => context.push(
                '/group/${widget.groupId}/transactions/add-expense',
              ),
            ),
            SpeedDialItem(
              icon: Icons.sync_alt,
              label: context.l10n.addTransfer,
              onPressed: () => context.push(
                '/group/${widget.groupId}/transactions/add-transfer',
              ),
            ),
            SpeedDialItem(
              icon: Icons.document_scanner_outlined,
              label: context.l10n.scanReceipt,
              onPressed: () => context.push(
                '/group/${widget.groupId}/transactions/add-expense?scan=true',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickAdd() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuickAddExpenseSheet(
        groupId: widget.groupId,
        onSuccess: () {
          ref
              .read(paginatedTransactionsProvider(widget.groupId).notifier)
              .refresh();
        },
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

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  final DateTime date;

  _DateHeaderDelegate({required this.date});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DateGroupHeader(date: date, isStuck: overlapsContent);
  }

  @override
  double get maxExtent => 48.0;

  @override
  double get minExtent => 48.0;

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return oldDelegate.date != date;
  }
}

class _TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  final Map<String, String> memberMap;
  final String currencyCode;

  const _TransactionListItem({
    super.key,
    required this.transaction,
    required this.memberMap,
    required this.currencyCode,
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

    return OpenContainer(
      closedElevation: 0,
      closedColor: Colors.transparent,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      transitionDuration: AnimationConfig.containerTransformDuration,
      transitionType: ContainerTransitionType.fadeThrough,
      closedShape: const RoundedRectangleBorder(),
      openBuilder: (context, action) {
        return TransactionDetailScreen(
          groupId: transaction.groupId,
          transactionId: transaction.id,
        );
      },
      closedBuilder: (context, action) {
        return Slidable(
          key: ValueKey(transaction.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  HapticsService.lightTap();
                  final route = isExpense
                      ? '/group/${transaction.groupId}/transactions/add-expense?txId=${transaction.id}'
                      : '/group/${transaction.groupId}/transactions/add-transfer?txId=${transaction.id}';
                  context.push(route);
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: context.l10n.swipeToEdit,
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            children: [
              SlidableAction(
                onPressed: (context) {
                  HapticsService.lightTap();
                  _scheduleTransactionDelete(context, ref);
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: context.l10n.swipeToDelete,
              ),
            ],
          ),
          child: ListTile(
            onTap: AnimationConfig.useReducedMotion(context)
                ? () => context.push(
                    '/group/${transaction.groupId}/transactions/${transaction.id}',
                  )
                : action,
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
                if (transaction.isRecurring) ...[
                  Icon(
                    Icons.repeat,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: AppTheme.space4),
                ],
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
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag.name,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleTransactionDelete(BuildContext context, WidgetRef ref) {
    final repository = ref.read(transactionRepositoryProvider);
    final undoService = ref.read(undoableActionProvider);
    final l10n = context.l10n;
    final paginatedNotifier = ref.read(
      paginatedTransactionsProvider(transaction.groupId).notifier,
    );

    // Optimistically remove from list
    paginatedNotifier.removeItem(transaction.id);

    final actionId = undoService.schedule(
      UndoableAction(
        id: 'delete_tx_${transaction.id}',
        description: l10n.transactionDeleted,
        executeAction: () async {
          await repository.softDeleteTransaction(transaction.id);
        },
        undoAction: () async {
          // Bring it back by refreshing the provider
          await paginatedNotifier.refresh();
        },
      ),
    );

    showUndoSnackBar(
      context: context,
      message: l10n.transactionDeleted,
      actionId: actionId,
      undoService: undoService,
    );
  }
}
