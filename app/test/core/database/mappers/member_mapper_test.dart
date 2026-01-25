import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/mappers/member_mapper.dart';
import 'package:trustguard/src/core/models/member.dart' as model;

void main() {
  group('MemberMapper', () {
    final now = DateTime(2026, 1, 26, 12, 0);
    final memberData = Member(
      id: 'm1',
      groupId: 'g1',
      displayName: 'Member 1',
      createdAt: now,
      removedAt: null,
    );

    final memberModel = model.Member(
      id: 'm1',
      groupId: 'g1',
      displayName: 'Member 1',
      createdAt: now,
      removedAt: null,
    );

    test('toModel should convert MemberData to Member model', () {
      final result = MemberMapper.toModel(memberData);
      expect(result, equals(memberModel));
    });

    test('toCompanion should convert Member model to MembersCompanion', () {
      final result = MemberMapper.toCompanion(memberModel);
      expect(result.id.value, equals(memberModel.id));
      expect(result.groupId.value, equals(memberModel.groupId));
      expect(result.displayName.value, equals(memberModel.displayName));
      expect(result.createdAt.value, equals(memberModel.createdAt));
      expect(result.removedAt.value, equals(memberModel.removedAt));
    });
  });
}
