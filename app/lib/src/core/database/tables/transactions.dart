import 'package:drift/drift.dart';
import '../../models/transaction.dart';
import 'groups.dart';

@TableIndex(
  name: 'transactions_group_occurred',
  columns: {#groupId, #occurredAt},
)
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get type => textEnum<TransactionType>()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
