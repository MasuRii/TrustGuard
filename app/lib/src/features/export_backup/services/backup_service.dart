import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database.dart';
import '../../../core/database/mappers/group_mapper.dart';
import '../../../core/database/mappers/member_mapper.dart';
import '../../../core/database/mappers/reminder_mapper.dart';
import '../../../core/database/mappers/tag_mapper.dart';
import '../../../core/database/mappers/transaction_mapper.dart';
import '../../../core/database/repositories/group_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/tag_repository.dart';
import '../../../core/database/repositories/reminder_repository.dart';
import '../../../core/models/backup.dart';
import '../../../core/utils/platform_utils.dart';

/// Service for generating and sharing app-wide JSON backups.
class BackupService {
  final AppDatabase _database;
  final GroupRepository _groupRepository;
  final MemberRepository _memberRepository;
  final TransactionRepository _transactionRepository;
  final TagRepository _tagRepository;
  final ReminderRepository _reminderRepository;

  BackupService({
    required AppDatabase database,
    required GroupRepository groupRepository,
    required MemberRepository memberRepository,
    required TransactionRepository transactionRepository,
    required TagRepository tagRepository,
    required ReminderRepository reminderRepository,
  }) : _database = database,
       _groupRepository = groupRepository,
       _memberRepository = memberRepository,
       _transactionRepository = transactionRepository,
       _tagRepository = tagRepository,
       _reminderRepository = reminderRepository;

  /// Creates a complete backup of all app data.
  Future<Backup> createBackup() async {
    final groups = await _groupRepository.getAllGroups(includeArchived: true);
    final members = await _memberRepository.getAllMembers();
    final transactions = await _transactionRepository.getAllTransactions();
    final tags = await _tagRepository.getAllTags();
    final reminderSettings = await _reminderRepository.getAllReminderSettings();

    return Backup(
      schemaVersion: 1, // Current schema version
      createdAt: DateTime.now(),
      groups: groups,
      members: members,
      transactions: transactions,
      tags: tags,
      reminderSettings: reminderSettings,
    );
  }

  /// Exports and shares the complete app backup as a JSON file.
  ///
  /// Note: Sharing is only available on platforms that support file sharing.
  /// On web, this operation will throw an exception.
  Future<void> shareBackup() async {
    if (!PlatformUtils.supportsFileSystem) {
      throw UnsupportedError('File sharing is not available on this platform');
    }

    final backup = await createBackup();
    final jsonString = jsonEncode(backup.toJson());

    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${directory.path}/TrustGuard_Backup_$timestamp.json');

    await file.writeAsString(jsonString, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'TrustGuard Backup - ${DateTime.now().toLocal()}',
      ),
    );
  }

  /// Restores app data from a JSON backup file.
  ///
  /// Implements conflict resolution by generating new UUIDs for all entities
  /// and maintaining their relationships. This ensures that restoring a backup
  /// does not overwrite existing data if IDs happen to collide.
  Future<void> restoreFromBackup(File file) async {
    final jsonString = await file.readAsString();
    final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
    final backup = Backup.fromJson(jsonMap);

    // Schema version check
    if (backup.schemaVersion > 1) {
      throw Exception('Incompatible backup version: ${backup.schemaVersion}');
    }

    await _database.transaction(() async {
      const uuid = Uuid();
      final groupMap = <String, String>{};
      final memberMap = <String, String>{};
      final tagMap = <String, String>{};

      // 1. Restore Groups
      for (final group in backup.groups) {
        final newId = uuid.v4();
        groupMap[group.id] = newId;
        final restoredGroup = group.copyWith(id: newId);
        await _database
            .into(_database.groups)
            .insert(GroupMapper.toCompanion(restoredGroup));
      }

      // 2. Restore Members
      for (final member in backup.members) {
        final newId = uuid.v4();
        memberMap[member.id] = newId;
        final newGroupId = groupMap[member.groupId];
        if (newGroupId == null) continue;

        final restoredMember = member.copyWith(id: newId, groupId: newGroupId);
        await _database
            .into(_database.members)
            .insert(MemberMapper.toCompanion(restoredMember));
      }

      // 3. Restore Tags
      for (final tag in backup.tags) {
        final newId = uuid.v4();
        tagMap[tag.id] = newId;
        final newGroupId = groupMap[tag.groupId];
        if (newGroupId == null) continue;

        final restoredTag = tag.copyWith(id: newId, groupId: newGroupId);
        await _database
            .into(_database.tags)
            .insert(TagMapper.toCompanion(restoredTag));
      }

      // 4. Restore Transactions
      for (final tx in backup.transactions) {
        final newTxId = uuid.v4();
        final newGroupId = groupMap[tx.groupId];
        if (newGroupId == null) continue;

        // Map detail member IDs
        var restoredTx = tx.copyWith(id: newTxId, groupId: newGroupId);

        if (restoredTx.expenseDetail != null) {
          final detail = restoredTx.expenseDetail!;
          final newPayerId = memberMap[detail.payerMemberId];
          if (newPayerId != null) {
            final newParticipants = detail.participants.map((p) {
              return p.copyWith(memberId: memberMap[p.memberId] ?? p.memberId);
            }).toList();
            restoredTx = restoredTx.copyWith(
              expenseDetail: detail.copyWith(
                payerMemberId: newPayerId,
                participants: newParticipants,
              ),
            );
          }
        }

        if (restoredTx.transferDetail != null) {
          final detail = restoredTx.transferDetail!;
          restoredTx = restoredTx.copyWith(
            transferDetail: detail.copyWith(
              fromMemberId:
                  memberMap[detail.fromMemberId] ?? detail.fromMemberId,
              toMemberId: memberMap[detail.toMemberId] ?? detail.toMemberId,
            ),
          );
        }

        // Map tags
        final newTags = restoredTx.tags.map((t) {
          final newTagId = tagMap[t.id];
          return t.copyWith(id: newTagId ?? t.id, groupId: newGroupId);
        }).toList();
        restoredTx = restoredTx.copyWith(tags: newTags);

        // Insert Transaction
        await _database
            .into(_database.transactions)
            .insert(TransactionMapper.toTransactionCompanion(restoredTx));

        // Insert Details
        if (restoredTx.expenseDetail != null) {
          await _database
              .into(_database.expenseDetails)
              .insert(TransactionMapper.toExpenseDetailCompanion(restoredTx)!);
          final participants =
              TransactionMapper.toExpenseParticipantsCompanions(restoredTx);
          if (participants.isNotEmpty) {
            await _database.batch((batch) {
              batch.insertAll(_database.expenseParticipants, participants);
            });
          }
        }

        if (restoredTx.transferDetail != null) {
          await _database
              .into(_database.transferDetails)
              .insert(TransactionMapper.toTransferDetailCompanion(restoredTx)!);
        }

        // Insert Tags
        final tags = TransactionMapper.toTransactionTagsCompanions(restoredTx);
        if (tags.isNotEmpty) {
          await _database.batch((batch) {
            batch.insertAll(_database.transactionTags, tags);
          });
        }
      }

      // 5. Restore Reminder Settings
      for (final settings in backup.reminderSettings) {
        final newGroupId = groupMap[settings.groupId];
        if (newGroupId == null) continue;

        final restoredSettings = settings.copyWith(groupId: newGroupId);
        await _database
            .into(_database.groupReminders)
            .insert(ReminderMapper.toCompanion(restoredSettings));
      }
    });
  }
}
