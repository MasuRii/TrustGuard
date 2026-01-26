import 'package:freezed_annotation/freezed_annotation.dart';
import 'expense.dart';
import 'transfer.dart';
import 'tag.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

enum TransactionType { expense, transfer }

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required String groupId,
    required TransactionType type,
    required DateTime occurredAt,
    required String note,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
    ExpenseDetail? expenseDetail,
    TransferDetail? transferDetail,
    @Default(false) bool isRecurring,
    @Default([]) List<Tag> tags,
  }) = _Transaction;

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
