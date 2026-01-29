import 'package:drift/drift.dart';
import 'groups.dart';

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get displayName => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get removedAt => dateTime().nullable()();
  TextColumn get avatarPath => text().nullable()();
  IntColumn get avatarColor => integer().nullable()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
