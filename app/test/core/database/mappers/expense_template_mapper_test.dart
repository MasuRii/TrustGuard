import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/mappers/expense_template_mapper.dart';
import 'package:trustguard/src/core/models/expense_template.dart';

void main() {
  group('ExpenseTemplateMapper', () {
    final now = DateTime(2026, 1, 29, 12, 0);

    final expenseTemplateModel = ExpenseTemplate(
      id: 'template_1',
      groupId: 'group_1',
      name: 'Lunch',
      description: 'Team Lunch',
      amountMinor: 5000,
      currencyCode: 'USD',
      payerId: 'member_1',
      splitType: SplitType.custom,
      participantData: {'member_1': 2000, 'member_2': 3000},
      tagIds: ['tag_1', 'tag_2'],
      orderIndex: 0,
      createdAt: now,
      usageCount: 5,
    );

    final expenseTemplateEntity = ExpenseTemplateEntity(
      id: 'template_1',
      groupId: 'group_1',
      name: 'Lunch',
      description: 'Team Lunch',
      amountMinor: 5000,
      currencyCode: 'USD',
      payerId: 'member_1',
      splitType: 'custom',
      participantData: jsonEncode({'member_1': 2000, 'member_2': 3000}),
      tagIds: jsonEncode(['tag_1', 'tag_2']),
      orderIndex: 0,
      createdAt: now,
      usageCount: 5,
    );

    test('toModel should convert entity to model', () {
      final result = expenseTemplateEntity.toModel();
      expect(result, equals(expenseTemplateModel));
    });

    test('toCompanion should convert model to companion', () {
      final result = expenseTemplateModel.toCompanion();
      expect(result.id.value, equals(expenseTemplateModel.id));
      expect(result.name.value, equals(expenseTemplateModel.name));
      expect(result.splitType.value, equals('custom'));

      final decodedParticipants = jsonDecode(result.participantData.value!);
      expect(decodedParticipants, equals({'member_1': 2000, 'member_2': 3000}));

      final decodedTags = jsonDecode(result.tagIds.value!);
      expect(decodedTags, equals(['tag_1', 'tag_2']));
    });

    test('toModel should handle null JSON fields', () {
      final entity = ExpenseTemplateEntity(
        id: 't2',
        groupId: 'g1',
        name: 'Empty',
        description: null,
        amountMinor: null,
        currencyCode: 'USD',
        payerId: 'p1',
        splitType: 'equal',
        participantData: null,
        tagIds: null,
        orderIndex: 0,
        createdAt: now,
        usageCount: 0,
      );

      final model = entity.toModel();
      expect(model.participantData, isNull);
      expect(model.tagIds, isEmpty);
      expect(model.splitType, SplitType.equal);
    });
  });
}
