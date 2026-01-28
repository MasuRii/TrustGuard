import 'package:drift/drift.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/budget.dart';

extension BudgetMapper on Budget {
  BudgetsCompanion toCompanion() {
    return BudgetsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      limitMinor: Value(limitMinor),
      currencyCode: Value(currencyCode),
      period: Value(period.name),
      startDate: Value(startDate),
      endDate: Value(endDate),
      tagId: Value(tagId),
      alertThreshold: Value(alertThreshold),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }
}

extension BudgetEntityMapper on BudgetEntity {
  Budget toModel() {
    return Budget(
      id: id,
      groupId: groupId,
      name: name,
      limitMinor: limitMinor,
      currencyCode: currencyCode,
      period: BudgetPeriod.values.firstWhere(
        (e) => e.name == period,
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: startDate,
      endDate: endDate,
      tagId: tagId,
      alertThreshold: alertThreshold,
      isActive: isActive,
      createdAt: createdAt,
      currentAmount: 0, // Computed field, default to 0 from DB
    );
  }
}
