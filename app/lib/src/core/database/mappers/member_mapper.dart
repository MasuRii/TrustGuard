import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/member.dart' as model;

class MemberMapper {
  static model.Member toModel(Member data) {
    return model.Member(
      id: data.id,
      groupId: data.groupId,
      displayName: data.displayName,
      createdAt: data.createdAt,
      removedAt: data.removedAt,
      avatarPath: data.avatarPath,
      avatarColor: data.avatarColor,
      orderIndex: data.orderIndex,
    );
  }

  static MembersCompanion toCompanion(model.Member domain) {
    return MembersCompanion(
      id: Value(domain.id),
      groupId: Value(domain.groupId),
      displayName: Value(domain.displayName),
      createdAt: Value(domain.createdAt),
      removedAt: Value(domain.removedAt),
      avatarPath: Value(domain.avatarPath),
      avatarColor: Value(domain.avatarColor),
      orderIndex: Value(domain.orderIndex),
    );
  }
}
