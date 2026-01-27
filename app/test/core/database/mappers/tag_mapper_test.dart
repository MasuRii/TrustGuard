import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/mappers/tag_mapper.dart';
import 'package:trustguard/src/core/models/tag.dart' as model;

void main() {
  group('TagMapper', () {
    const tagData = Tag(id: 't1', groupId: 'g1', name: 'Food', orderIndex: 0);

    const tagModel = model.Tag(
      id: 't1',
      groupId: 'g1',
      name: 'Food',
      orderIndex: 0,
    );

    test('toModel should convert TagData to Tag model', () {
      final result = TagMapper.toModel(tagData);
      expect(result, equals(tagModel));
    });

    test('toCompanion should convert Tag model to TagsCompanion', () {
      final result = TagMapper.toCompanion(tagModel);
      expect(result.id.value, equals(tagModel.id));
      expect(result.groupId.value, equals(tagModel.groupId));
      expect(result.name.value, equals(tagModel.name));
    });
  });
}
