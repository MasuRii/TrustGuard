import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../core/utils/money.dart';
import '../features/export_backup/services/export_service.dart';
import '../features/export_backup/services/backup_service.dart';
import '../features/settings/services/settings_service.dart';
import '../features/onboarding/services/onboarding_service.dart';
import '../features/onboarding/models/onboarding_state.dart';
import '../core/platform/local_log_service.dart';

/// Provider for the [AppDatabase] singleton.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Provider for [SharedPreferences].
/// MUST be overridden in ProviderScope during initialization.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Provider for [SettingsService].
final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

/// Provider for rounding settings.
class RoundingNotifier extends Notifier<int> {
  @override
  int build() {
    final service = ref.watch(settingsServiceProvider);
    return service.getRoundingDecimalPlaces();
  }

  Future<void> setRounding(int value) async {
    final service = ref.read(settingsServiceProvider);
    await service.setRoundingDecimalPlaces(value);
    state = value;
  }
}

final roundingProvider = NotifierProvider<RoundingNotifier, int>(
  () => RoundingNotifier(),
);

/// Provider for formatting money based on rounding settings.
typedef MoneyFormatter =
    String Function(int minorUnits, {String currencyCode, String? locale});

final moneyFormatterProvider = Provider<MoneyFormatter>((ref) {
  final decimalDigits = ref.watch(roundingProvider);
  return (int minorUnits, {String currencyCode = 'USD', String? locale}) {
    return MoneyUtils.format(
      minorUnits,
      currencyCode: currencyCode,
      locale: locale,
      decimalDigits: decimalDigits,
    );
  };
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

/// Provider for [ExportService].
final exportServiceProvider = Provider<ExportService>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final memberRepository = ref.watch(memberRepositoryProvider);
  final settingsService = ref.watch(settingsServiceProvider);
  return ExportService(
    transactionRepository: transactionRepository,
    memberRepository: memberRepository,
    settingsService: settingsService,
  );
});

/// Provider for [BackupService].
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    database: ref.watch(databaseProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    memberRepository: ref.watch(memberRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    reminderRepository: ref.watch(reminderRepositoryProvider),
  );
});

/// Provider for [OnboardingService].
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingService(prefs);
});

/// Provider for [OnboardingState].
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    final service = ref.watch(onboardingServiceProvider);
    return service.getOnboardingState();
  }

  Future<void> completeOnboarding() async {
    final service = ref.read(onboardingServiceProvider);
    await service.markOnboardingComplete();
    state = service.getOnboardingState();
  }
}

final onboardingStateProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
      OnboardingNotifier.new,
    );

/// Provider for [LocalLogService].
final localLogServiceProvider = Provider<LocalLogService>((ref) {
  return LocalLogService();
});
