import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/repositories/group_repository.dart';
import '../../../core/database/repositories/member_repository.dart';
import '../../../core/database/repositories/transaction_repository.dart';
import '../../../core/database/repositories/tag_repository.dart';
import '../../../core/database/repositories/reminder_repository.dart';
import '../../../core/models/backup.dart';

/// Service for generating and sharing app-wide JSON backups.
class BackupService {
  final GroupRepository _groupRepository;
  final MemberRepository _memberRepository;
  final TransactionRepository _transactionRepository;
  final TagRepository _tagRepository;
  final ReminderRepository _reminderRepository;

  BackupService({
    required GroupRepository groupRepository,
    required MemberRepository memberRepository,
    required TransactionRepository transactionRepository,
    required TagRepository tagRepository,
    required ReminderRepository reminderRepository,
  }) : _groupRepository = groupRepository,
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
  Future<void> shareBackup() async {
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
}
