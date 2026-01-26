import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/reminder_settings.dart';

class ReminderMapper {
  static ReminderSettings toModel(GroupReminder row) {
    return ReminderSettings(
      groupId: row.groupId,
      enabled: row.enabled,
      schedule: row.schedule,
      lastNotifiedAt: row.lastNotifiedAt,
    );
  }

  static GroupRemindersCompanion toCompanion(ReminderSettings model) {
    return GroupRemindersCompanion(
      groupId: Value(model.groupId),
      enabled: Value(model.enabled),
      schedule: Value(model.schedule),
      lastNotifiedAt: Value(model.lastNotifiedAt),
    );
  }
}
