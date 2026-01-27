import 'package:drift/drift.dart';
import 'groups.dart';

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get name => text()
      .withLength(min: 1, max: 50)
      .customConstraint('NOT NULL COLLATE NOCASE')();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {groupId, name},
  ];
}
