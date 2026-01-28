import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

enum BudgetPeriod {
  weekly,
  monthly,
  yearly,
  custom;

  String get label {
    switch (this) {
      case BudgetPeriod.weekly:
        return 'Weekly';
      case BudgetPeriod.monthly:
        return 'Monthly';
      case BudgetPeriod.yearly:
        return 'Yearly';
      case BudgetPeriod.custom:
        return 'Custom';
    }
  }
}

@freezed
abstract class Budget with _$Budget {
  const Budget._();

  const factory Budget({
    required String id,
    required String groupId,
    required String name,
    required int limitMinor,
    required String currencyCode,
    required BudgetPeriod period,
    required DateTime startDate,
    DateTime? endDate,
    String? tagId,
    @Default(80) int alertThreshold,
    @Default(true) bool isActive,
    // Transient field - not persisted in this table directly
    @Default(0) int currentAmount,
    required DateTime createdAt,
  }) = _Budget;

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  double get percentUsed {
    if (limitMinor == 0) return 0.0;
    return currentAmount / limitMinor;
  }

  int get remainingAmount => limitMinor - currentAmount;
}
