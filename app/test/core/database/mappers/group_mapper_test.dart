import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/mappers/group_mapper.dart';
import 'package:trustguard/src/core/models/group.dart' as model;

void main() {
  group('GroupMapper', () {
    final now = DateTime(2026, 1, 26, 12, 0);
    final groupData = Group(
      id: '1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: now,
      archivedAt: null,
    );

    final groupModel = model.Group(
      id: '1',
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: now,
      archivedAt: null,
    );

    test('toModel should convert GroupData to Group model', () {
      final result = GroupMapper.toModel(groupData);
      expect(result, equals(groupModel));
    });

    test('toCompanion should convert Group model to GroupsCompanion', () {
      final result = GroupMapper.toCompanion(groupModel);
      expect(result.id.value, equals(groupModel.id));
      expect(result.name.value, equals(groupModel.name));
      expect(result.currencyCode.value, equals(groupModel.currencyCode));
      expect(result.createdAt.value, equals(groupModel.createdAt));
      expect(result.archivedAt.value, equals(groupModel.archivedAt));
    });
  });
}
