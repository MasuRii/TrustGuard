import 'package:freezed_annotation/freezed_annotation.dart';
import 'group.dart';
import 'member.dart';
import 'transaction.dart';
import 'tag.dart';
import 'reminder_settings.dart';

part 'backup.freezed.dart';
part 'backup.g.dart';

@freezed
class Backup with _$Backup {
  const factory Backup({
    required int schemaVersion,
    required DateTime createdAt,
    required List<Group> groups,
    required List<Member> members,
    required List<Transaction> transactions,
    required List<Tag> tags,
    required List<ReminderSettings> reminderSettings,
  }) = _Backup;

  factory Backup.fromJson(Map<String, dynamic> json) => _$BackupFromJson(json);
}
