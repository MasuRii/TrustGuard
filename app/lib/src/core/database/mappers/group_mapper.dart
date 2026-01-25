import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/group.dart' as model;

class GroupMapper {
  static model.Group toModel(Group data) {
    return model.Group(
      id: data.id,
      name: data.name,
      currencyCode: data.currencyCode,
      createdAt: data.createdAt,
      archivedAt: data.archivedAt,
    );
  }

  static GroupsCompanion toCompanion(model.Group domain) {
    return GroupsCompanion(
      id: Value(domain.id),
      name: Value(domain.name),
      currencyCode: Value(domain.currencyCode),
      createdAt: Value(domain.createdAt),
      archivedAt: Value(domain.archivedAt),
    );
  }
}
