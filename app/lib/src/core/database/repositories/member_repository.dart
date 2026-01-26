import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/member_mapper.dart';
import '../../models/member.dart' as model;

abstract class MemberRepository {
  Future<List<model.Member>> getAllMembers();
  Future<List<model.Member>> getMembersByGroup(
    String groupId, {
    bool includeRemoved = false,
  });
  Stream<List<model.Member>> watchMembersByGroup(
    String groupId, {
    bool includeRemoved = false,
  });
  Future<model.Member?> getMemberById(String id);
  Future<void> createMember(model.Member member);
  Future<void> updateMember(model.Member member);
  Future<void> softDeleteMember(String id);
  Future<void> undoSoftDeleteMember(String id);
}

class DriftMemberRepository implements MemberRepository {
  final AppDatabase _db;

  DriftMemberRepository(this._db);

  @override
  Future<List<model.Member>> getAllMembers() async {
    final rows = await _db.select(_db.members).get();
    return rows.map(MemberMapper.toModel).toList();
  }

  @override
  Future<List<model.Member>> getMembersByGroup(
    String groupId, {
    bool includeRemoved = false,
  }) async {
    final query = _db.select(_db.members)
      ..where((t) => t.groupId.equals(groupId));
    if (!includeRemoved) {
      query.where((t) => t.removedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.displayName)]);
    final rows = await query.get();
    return rows.map(MemberMapper.toModel).toList();
  }

  @override
  Stream<List<model.Member>> watchMembersByGroup(
    String groupId, {
    bool includeRemoved = false,
  }) {
    final query = _db.select(_db.members)
      ..where((t) => t.groupId.equals(groupId));
    if (!includeRemoved) {
      query.where((t) => t.removedAt.isNull());
    }
    query.orderBy([(t) => OrderingTerm.asc(t.displayName)]);
    return query.watch().map((rows) => rows.map(MemberMapper.toModel).toList());
  }

  @override
  Future<model.Member?> getMemberById(String id) async {
    final query = _db.select(_db.members)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? MemberMapper.toModel(row) : null;
  }

  @override
  Future<void> createMember(model.Member member) async {
    await _db.into(_db.members).insert(MemberMapper.toCompanion(member));
  }

  @override
  Future<void> updateMember(model.Member member) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(member.id))).write(
      MemberMapper.toCompanion(member),
    );
  }

  @override
  Future<void> softDeleteMember(String id) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(id))).write(
      MembersCompanion(removedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> undoSoftDeleteMember(String id) async {
    await (_db.update(_db.members)..where((t) => t.id.equals(id))).write(
      const MembersCompanion(removedAt: Value(null)),
    );
  }
}
