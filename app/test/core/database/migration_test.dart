import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/database/database.dart';

void main() {
  group('Database Migration', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial schema version is 5', () async {
      expect(db.schemaVersion, 5);
    });

    test('Can create and open database with all tables', () async {
      // Accessing any table will trigger onCreate
      final groups = await db.select(db.groups).get();
      expect(groups, isEmpty);

      // Verify foreign keys are enabled (beforeOpen logic)
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.read<int>('foreign_keys'), 1);
    });

    /*
    Pattern for future migration tests:

    test('migration from v1 to v2', () async {
      final schema = await SchemaVerifier.v1(db); // Requires drift_dev schema generator

      // 1. Create a v1 database
      // 2. Add some data
      // 3. Run migration to v2
      // 4. Verify data is still there and schema is updated
    });
    */
  });
}
