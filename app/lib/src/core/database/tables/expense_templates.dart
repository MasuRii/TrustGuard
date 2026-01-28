import 'package:drift/drift.dart';
import 'package:trustguard/src/core/database/tables/groups.dart';
import 'package:trustguard/src/core/database/tables/members.dart';

@DataClassName('ExpenseTemplateEntity')
class ExpenseTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get amountMinor => integer().nullable()(); // null = ask each time
  TextColumn get currencyCode => text()();
  TextColumn get payerId => text().references(Members, #id)();
  TextColumn get splitType => text()(); // equal, custom, percentage
  TextColumn get participantData =>
      text().nullable()(); // JSON map of memberId -> amount/weight
  TextColumn get tagIds => text().nullable()(); // JSON list of tag IDs
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get usageCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
