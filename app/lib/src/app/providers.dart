import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../core/database/repositories/group_repository.dart';
import '../core/database/repositories/member_repository.dart';
import '../core/database/repositories/transaction_repository.dart';
import '../core/database/repositories/tag_repository.dart';
import '../core/models/tag_with_usage.dart';
import '../core/models/tag.dart' as model;

/// Provider for the [AppDatabase] singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for [GroupRepository].
final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftGroupRepository(db);
});

/// Provider for [MemberRepository].
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftMemberRepository(db);
});

/// Provider for [TransactionRepository].
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftTransactionRepository(db);
});

/// Provider for [TagRepository].
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftTagRepository(db);
});

/// Provider for watching tags with usage count for a group.
final tagsWithUsageProvider = StreamProvider.family<List<TagWithUsage>, String>(
  (ref, groupId) {
    final repo = ref.watch(tagRepositoryProvider);
    return repo.watchTagsWithUsageByGroup(groupId);
  },
);

/// Provider for watching all tags in a group.
final tagsProvider = StreamProvider.family<List<model.Tag>, String>((
  ref,
  groupId,
) {
  final repo = ref.watch(tagRepositoryProvider);
  return repo.watchTagsByGroup(groupId);
});
