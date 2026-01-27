import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction_filter.dart';
import '../presentation/transactions_providers.dart';
import '../models/paginated_transactions_state.dart';

final paginatedTransactionsProvider =
    AsyncNotifierProvider.family<
      PaginatedTransactionsNotifier,
      PaginatedTransactionsState,
      String
    >(PaginatedTransactionsNotifier.new);

class PaginatedTransactionsNotifier
    extends FamilyAsyncNotifier<PaginatedTransactionsState, String> {
  static const int _pageSize = 20;

  @override
  FutureOr<PaginatedTransactionsState> build(String arg) async {
    // Listen to filter changes to reset pagination
    final filter = ref.watch(transactionFilterProvider(arg));
    return _fetchPage(0, filter);
  }

  Future<PaginatedTransactionsState> _fetchPage(
    int offset,
    TransactionFilter filter,
  ) async {
    final repository = ref.read(transactionRepositoryProvider);

    final transactions = await repository.getTransactionsByGroupPaginated(
      arg,
      limit: _pageSize,
      offset: offset,
      filter: filter,
    );

    final totalCount = await repository.getTransactionCountByGroup(
      arg,
      filter: filter,
    );

    return PaginatedTransactionsState(
      transactions: transactions,
      hasMore: (offset + transactions.length) < totalCount,
      totalCount: totalCount,
    );
  }

  Future<void> loadMore() async {
    // Only load more if not currently loading, has data, and has more to fetch
    if (state.isLoading || !state.hasValue || !state.value!.hasMore) return;

    final currentState = state.value!;
    final filter = ref.read(transactionFilterProvider(arg));
    final nextOffset = currentState.transactions.length;

    // Set loading state but preserve data for UI to show existing list
    state = const AsyncLoading<PaginatedTransactionsState>().copyWithPrevious(
      state,
    );

    state = await AsyncValue.guard(() async {
      final nextPage = await _fetchPage(nextOffset, filter);
      return currentState.copyWith(
        transactions: [...currentState.transactions, ...nextPage.transactions],
        hasMore: nextPage.hasMore,
        totalCount: nextPage.totalCount,
      );
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading<PaginatedTransactionsState>().copyWithPrevious(
      state,
    );
    final filter = ref.read(transactionFilterProvider(arg));
    state = await AsyncValue.guard(() => _fetchPage(0, filter));
  }

  /// Optimistically removes a transaction from the current state.
  void removeItem(String transactionId) {
    if (!state.hasValue) return;

    final currentState = state.value!;
    state = AsyncData(
      currentState.copyWith(
        transactions: currentState.transactions
            .where((t) => t.id != transactionId)
            .toList(),
        totalCount: currentState.totalCount - 1,
      ),
    );
  }
}
