import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';

/// Provider for the transaction filter of a group.
final transactionFilterProvider = StateProvider.autoDispose
    .family<TransactionFilter, String>((ref, groupId) {
      return const TransactionFilter();
    });

/// Provider for the list of transactions in a group.
final transactionsByGroupProvider = StreamProvider.autoDispose
    .family<List<Transaction>, String>((ref, groupId) {
      final repository = ref.watch(transactionRepositoryProvider);
      final filter = ref.watch(transactionFilterProvider(groupId));
      return repository.watchTransactionsByGroup(groupId, filter: filter);
    });

/// Provider for a single transaction by its ID.
final transactionProvider = FutureProvider.autoDispose
    .family<Transaction?, String>((ref, id) {
      final repository = ref.watch(transactionRepositoryProvider);
      return repository.getTransactionById(id);
    });
