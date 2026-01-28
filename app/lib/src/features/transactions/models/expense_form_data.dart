import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/models/expense.dart';

part 'expense_form_data.freezed.dart';

enum CustomSplitMode { amount, percentage }

@freezed
abstract class ExpenseFormData with _$ExpenseFormData {
  const factory ExpenseFormData({
    required String groupId,
    required String? payerId,
    required String description,
    required double amount,
    required String currencyCode,
    required SplitType splitType,
    required CustomSplitMode customSplitMode,
    required List<String> participantIds,
    required List<String> tagIds,
    required Map<String, double>? customAmounts, // memberId -> amount
    required Map<String, double>? customPercentages, // memberId -> percentage
  }) = _ExpenseFormData;
}
