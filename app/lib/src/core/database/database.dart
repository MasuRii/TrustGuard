import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/groups.dart';
import 'tables/members.dart';
import 'tables/transactions.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Groups, Members, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'trustguard',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }
}
