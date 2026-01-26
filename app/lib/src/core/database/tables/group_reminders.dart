import 'package:drift/drift.dart';
import 'groups.dart';
import '../../models/reminder_settings.dart';

class GroupReminders extends Table {
  TextColumn get groupId => text().references(Groups, #id)();
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();
  TextColumn get schedule => textEnum<ReminderSchedule>()();
  DateTimeColumn get lastNotifiedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};
}
