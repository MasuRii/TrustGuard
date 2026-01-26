import 'package:drift/drift.dart';
import '../database.dart';
import '../mappers/tag_mapper.dart';
import '../../models/tag.dart' as model;
import '../../models/tag_with_usage.dart';

abstract class TagRepository {
  Future<List<model.Tag>> getAllTags();
  Future<List<model.Tag>> getTagsByGroup(String groupId);
  Stream<List<model.Tag>> watchTagsByGroup(String groupId);
  Stream<List<TagWithUsage>> watchTagsWithUsageByGroup(String groupId);
  Future<void> createTag(model.Tag tag);
  Future<void> updateTag(model.Tag tag);
  Future<void> deleteTag(String tagId);
  Future<void> assignTagsToTransaction(String txId, List<String> tagIds);
  Future<List<model.Tag>> getTagsByTransaction(String txId);
}

class DriftTagRepository implements TagRepository {
  final AppDatabase _db;

  DriftTagRepository(this._db);

  @override
  Future<List<model.Tag>> getAllTags() async {
    final rows = await _db.select(_db.tags).get();
    return rows.map(TagMapper.toModel).toList();
  }

  @override
  Future<List<model.Tag>> getTagsByGroup(String groupId) async {
    final query = _db.select(_db.tags)..where((t) => t.groupId.equals(groupId));
    final rows = await query.get();
    return rows.map(TagMapper.toModel).toList();
  }

  @override
  Stream<List<model.Tag>> watchTagsByGroup(String groupId) {
    final query = _db.select(_db.tags)..where((t) => t.groupId.equals(groupId));
    return query.watch().map((rows) => rows.map(TagMapper.toModel).toList());
  }

  @override
  Stream<List<TagWithUsage>> watchTagsWithUsageByGroup(String groupId) {
    final countExp = _db.transactionTags.txId.count();
    final query = _db.select(_db.tags).join([
      leftOuterJoin(
        _db.transactionTags,
        _db.transactionTags.tagId.equalsExp(_db.tags.id),
      ),
    ]);

    query.addColumns([countExp]);
    query
      ..where(_db.tags.groupId.equals(groupId))
      ..groupBy([_db.tags.id]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final tag = TagMapper.toModel(row.readTable(_db.tags));
        final count = row.read(countExp) ?? 0;
        return TagWithUsage(tag: tag, usageCount: count);
      }).toList();
    });
  }

  @override
  Future<void> createTag(model.Tag tag) async {
    // Check for case-insensitive duplicate
    final existing =
        await (_db.select(_db.tags)
              ..where((t) => t.groupId.equals(tag.groupId))
              ..where((t) => t.name.equals(tag.name)))
            .getSingleOrNull();

    if (existing != null) {
      throw Exception(
        'Tag with name "${tag.name}" already exists in this group',
      );
    }

    await _db.into(_db.tags).insert(TagMapper.toCompanion(tag));
  }

  @override
  Future<void> updateTag(model.Tag tag) async {
    // Check for case-insensitive duplicate (excluding self)
    final existing =
        await (_db.select(_db.tags)
              ..where((t) => t.groupId.equals(tag.groupId))
              ..where((t) => t.name.equals(tag.name))
              ..where((t) => t.id.equals(tag.id).not()))
            .getSingleOrNull();

    if (existing != null) {
      throw Exception(
        'Tag with name "${tag.name}" already exists in this group',
      );
    }

    await (_db.update(
      _db.tags,
    )..where((t) => t.id.equals(tag.id))).write(TagMapper.toCompanion(tag));
  }

  @override
  Future<void> deleteTag(String tagId) async {
    // Also delete associations in transaction_tags
    await _db.transaction(() async {
      await (_db.delete(
        _db.transactionTags,
      )..where((t) => t.tagId.equals(tagId))).go();
      await (_db.delete(_db.tags)..where((t) => t.id.equals(tagId))).go();
    });
  }

  @override
  Future<void> assignTagsToTransaction(String txId, List<String> tagIds) async {
    await _db.transaction(() async {
      // Remove old associations
      await (_db.delete(
        _db.transactionTags,
      )..where((t) => t.txId.equals(txId))).go();

      // Add new associations
      for (final tagId in tagIds) {
        await _db
            .into(_db.transactionTags)
            .insert(TransactionTagsCompanion.insert(txId: txId, tagId: tagId));
      }
    });
  }

  @override
  Future<List<model.Tag>> getTagsByTransaction(String txId) async {
    final query = _db.select(_db.tags).join([
      innerJoin(
        _db.transactionTags,
        _db.transactionTags.tagId.equalsExp(_db.tags.id),
      ),
    ])..where(_db.transactionTags.txId.equals(txId));

    final rows = await query.get();
    return rows
        .map((row) => TagMapper.toModel(row.readTable(_db.tags)))
        .toList();
  }
}
