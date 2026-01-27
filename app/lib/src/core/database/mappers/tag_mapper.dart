import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/tag.dart' as model;

class TagMapper {
  static model.Tag toModel(Tag data) {
    return model.Tag(
      id: data.id,
      groupId: data.groupId,
      name: data.name,
      orderIndex: data.orderIndex,
    );
  }

  static TagsCompanion toCompanion(model.Tag domain) {
    return TagsCompanion(
      id: Value(domain.id),
      groupId: Value(domain.groupId),
      name: Value(domain.name),
      orderIndex: Value(domain.orderIndex),
    );
  }
}
