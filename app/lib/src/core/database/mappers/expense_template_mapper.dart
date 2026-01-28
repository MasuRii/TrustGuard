import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense_template.dart';

extension ExpenseTemplateMapper on ExpenseTemplate {
  ExpenseTemplatesCompanion toCompanion() {
    return ExpenseTemplatesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      name: Value(name),
      description: Value(description),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      payerId: Value(payerId),
      splitType: Value(splitType.name),
      participantData: Value(
        participantData != null ? jsonEncode(participantData) : null,
      ),
      tagIds: Value(jsonEncode(tagIds)),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
      usageCount: Value(usageCount),
    );
  }
}

extension ExpenseTemplateEntityMapper on ExpenseTemplateEntity {
  ExpenseTemplate toModel() {
    return ExpenseTemplate(
      id: id,
      groupId: groupId,
      name: name,
      description: description,
      amountMinor: amountMinor,
      currencyCode: currencyCode,
      payerId: payerId,
      splitType: SplitType.values.firstWhere(
        (e) => e.name == splitType,
        orElse: () => SplitType.equal,
      ),
      participantData: participantData != null
          ? Map<String, int>.from(
              jsonDecode(participantData!) as Map<String, dynamic>,
            )
          : null,
      tagIds: tagIds != null
          ? List<String>.from(jsonDecode(tagIds!) as List<dynamic>)
          : [],
      orderIndex: orderIndex,
      createdAt: createdAt,
      usageCount: usageCount,
    );
  }
}
