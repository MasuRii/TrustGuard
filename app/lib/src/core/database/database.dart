import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import '../models/transaction.dart';
import '../models/expense.dart';
import '../models/reminder_settings.dart';
import '../models/recurring_transaction.dart';
import 'tables/groups.dart';
import 'tables/members.dart';
import 'tables/transactions.dart';
import 'tables/expense_details.dart';
import 'tables/expense_participants.dart';
import 'tables/transfer_details.dart';
import 'tables/tags.dart';
import 'tables/transaction_tags.dart';
import 'tables/group_reminders.dart';
import 'tables/recurring_transactions.dart';

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
    RecurringTransactions,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

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
        if (from < 3) {
          await m.createTable(recurringTransactions);
        }
        if (from < 4) {
          await m.addColumn(transactions, transactions.isRecurring);
        }
        if (from < 5) {
          await m.addColumn(members, members.orderIndex);
          await m.addColumn(tags, tags.orderIndex);
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
