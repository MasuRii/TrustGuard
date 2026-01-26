import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/reminder_settings.dart';
import 'tables/groups.dart';
import 'tables/members.dart';
import 'tables/transactions.dart';
import 'tables/expense_details.dart';
import 'tables/expense_participants.dart';
import 'tables/transfer_details.dart';
import 'tables/tags.dart';
import 'tables/transaction_tags.dart';
import 'tables/group_reminders.dart';

import 'tables/attachments.dart';

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
    Attachments,
    GroupReminders,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(expenseDetails, expenseDetails.exchangeRate);
          await m.addColumn(
            expenseDetails,
            expenseDetails.originalCurrencyCode,
          );
          await m.addColumn(expenseDetails, expenseDetails.originalAmountMinor);
        }
      },
      beforeOpen: (details) async {
        if (details.wasCreated) {
          // Initial data if needed
        }
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'trustguard',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
