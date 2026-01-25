import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/group_mapper.dart';
import '../../models/group.dart' as model;

abstract class GroupRepository {
  Future<List<model.Group>> getAllGroups({bool includeArchived = false});
  Stream<List<model.Group>> watchGroups({bool includeArchived = false});
  Future<model.Group?> getGroupById(String id);
  Future<void> createGroup(model.Group group);
  Future<void> updateGroup(model.Group group);
  Future<void> archiveGroup(String id);
  Future<void> unarchiveGroup(String id);
}

class DriftGroupRepository implements GroupRepository {
  final AppDatabase _db;

  DriftGroupRepository(this._db);

  @override
  Future<List<model.Group>> getAllGroups({bool includeArchived = false}) async {
    final query = _db.select(_db.groups);
    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }
    final rows = await query.get();
    return rows.map(GroupMapper.toModel).toList();
  }

  @override
  Stream<List<model.Group>> watchGroups({bool includeArchived = false}) {
    final query = _db.select(_db.groups);
    if (!includeArchived) {
      query.where((t) => t.archivedAt.isNull());
    }
    return query.watch().map((rows) => rows.map(GroupMapper.toModel).toList());
  }

  @override
  Future<model.Group?> getGroupById(String id) async {
    final query = _db.select(_db.groups)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? GroupMapper.toModel(row) : null;
  }

  @override
  Future<void> createGroup(model.Group group) async {
    await _db.into(_db.groups).insert(GroupMapper.toCompanion(group));
  }

  @override
  Future<void> updateGroup(model.Group group) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(group.id))).write(
      GroupMapper.toCompanion(group),
    );
  }

  @override
  Future<void> archiveGroup(String id) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(id))).write(
      GroupsCompanion(archivedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> unarchiveGroup(String id) async {
    await (_db.update(_db.groups)..where((t) => t.id.equals(id))).write(
      const GroupsCompanion(archivedAt: Value(null)),
    );
  }
}
