import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/transaction.dart';

part 'paginated_transactions_state.freezed.dart';
part 'paginated_transactions_state.g.dart';

@freezed
abstract class PaginatedTransactionsState with _$PaginatedTransactionsState {
  const factory PaginatedTransactionsState({
    @Default([]) List<Transaction> transactions,
    @Default(true) bool hasMore,
    @Default(0) int totalCount,
  }) = _PaginatedTransactionsState;

  factory PaginatedTransactionsState.fromJson(Map<String, dynamic> json) =>
      _$PaginatedTransactionsStateFromJson(json);
}
