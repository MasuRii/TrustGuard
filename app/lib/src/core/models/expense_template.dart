import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_template.freezed.dart';
part 'expense_template.g.dart';

enum SplitType {
  equal,
  custom,
  percentage;

  String get label {
    switch (this) {
      case SplitType.equal:
        return 'Equal';
      case SplitType.custom:
        return 'Custom';
      case SplitType.percentage:
        return 'Percentage';
    }
  }
}

@freezed
abstract class ExpenseTemplate with _$ExpenseTemplate {
  const ExpenseTemplate._();

  const factory ExpenseTemplate({
    required String id,
    required String groupId,
    required String name,
    String? description,
    int? amountMinor,
    required String currencyCode,
    required String payerId,
    required SplitType splitType,
    Map<String, int>? participantData,
    @Default([]) List<String> tagIds,
    required int orderIndex,
    required DateTime createdAt,
    @Default(0) int usageCount,
  }) = _ExpenseTemplate;

  factory ExpenseTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExpenseTemplateFromJson(json);

  bool get hasFixedAmount => amountMinor != null;
}
