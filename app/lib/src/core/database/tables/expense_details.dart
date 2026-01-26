import 'package:drift/drift.dart';
import '../../models/expense.dart';
import 'transactions.dart';
import 'members.dart';

class ExpenseDetails extends Table {
  TextColumn get txId => text().references(Transactions, #id)();
  TextColumn get payerMemberId => text().references(Members, #id)();
  IntColumn get totalAmountMinor => integer()();
  TextColumn get splitType => textEnum<SplitType>()();
  TextColumn get splitMetaJson => text().nullable()();
  RealColumn get exchangeRate => real().nullable()();
  TextColumn get originalCurrencyCode => text().nullable()();
  IntColumn get originalAmountMinor => integer().nullable()();

  @override
  Set<Column> get primaryKey => {txId};
}
