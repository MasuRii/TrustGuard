import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../core/database/database.dart';
import '../core/database/repositories/group_repository.dart';
import '../core/database/repositories/member_repository.dart';
import '../core/database/repositories/transaction_repository.dart';
import '../core/database/repositories/tag_repository.dart';
import '../core/database/repositories/reminder_repository.dart';
import '../core/platform/app_lock_service.dart';
import '../core/platform/notification_service.dart';
import '../core/models/tag_with_usage.dart';
import '../core/models/reminder_settings.dart';
import '../core/models/tag.dart' as model;

/// Provider for the [AppDatabase] singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for [FlutterSecureStorage].
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for [AppLockService].
final appLockServiceProvider = Provider<AppLockService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final auth = LocalAuthentication();
  return AppLockService(storage, auth);
});

/// Provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notifications = FlutterLocalNotificationsPlugin();
  final storage = ref.watch(secureStorageProvider);
  return NotificationService(notifications, storage);
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

/// Provider for [ReminderRepository].
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftReminderRepository(db);
});

/// Provider for watching reminder settings for a group.
final reminderSettingsProvider =
    StreamProvider.family<ReminderSettings?, String>((ref, groupId) {
      final repo = ref.watch(reminderRepositoryProvider);
      return repo.watchReminderSettings(groupId);
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
