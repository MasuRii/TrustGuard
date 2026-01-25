import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import 'tables/groups.dart';
import 'tables/members.dart';
import 'tables/transactions.dart';
import 'tables/expense_details.dart';
import 'tables/expense_participants.dart';
import 'tables/transfer_details.dart';
import 'tables/tags.dart';
import 'tables/transaction_tags.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Groups,
    Members,
    Transactions,
    ExpenseDetails,
    ExpenseParticipants,
    TransferDetails,
    Tags,
    TransactionTags,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'trustguard',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
