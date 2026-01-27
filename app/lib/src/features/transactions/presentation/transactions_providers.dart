import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/transaction_filter.dart';
import '../../../core/models/attachment.dart';
import '../../../core/models/recurring_transaction.dart';

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

/// Provider for transaction attachments.
final attachmentsProvider = FutureProvider.autoDispose
    .family<List<Attachment>, String>((ref, txId) {
      final repo = ref.watch(attachmentRepositoryProvider);
      return repo.getAttachmentsByTransaction(txId);
    });

/// Provider for smart amount suggestions.
final amountSuggestionsProvider = FutureProvider.autoDispose
    .family<List<int>, String>((ref, groupId) {
      final service = ref.watch(amountSuggestionServiceProvider);
      return service.getSuggestions(groupId);
    });

/// Provider for recurring transaction by template ID.
final recurringByTemplateProvider = FutureProvider.autoDispose
    .family<RecurringTransaction?, String>((ref, templateId) {
      final repo = ref.watch(recurringTransactionRepositoryProvider);
      return repo.getRecurringByTemplateId(templateId);
    });
