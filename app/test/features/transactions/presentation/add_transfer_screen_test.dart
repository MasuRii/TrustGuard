import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/transactions/presentation/add_transfer_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setupData(String groupId) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: groupId,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm1',
            groupId: groupId,
            displayName: 'Alice',
            createdAt: DateTime.now(),
          ),
        );

    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm2',
            groupId: groupId,
            displayName: 'Bob',
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('AddTransferScreen adds a new transfer successfully', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupData(groupId);

    final prefsOverrides = await getSharedPrefsOverride(
      customKeypadEnabled: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(AddTransferScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Fill in form
    await tester.enterText(find.byType(TextFormField).first, '25.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'Settlement');

    // Tap Save
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify transaction created
    final transactions = await db.select(db.transactions).get();
    expect(transactions.length, 1);
    expect(transactions.first.note, 'Settlement');

    final details = await db.select(db.transferDetails).get();
    expect(details.length, 1);
    expect(details.first.amountMinor, 2500);
    expect(details.first.fromMemberId, 'm1');
    expect(details.first.toMemberId, 'm2');

    await db.close();
    await tester.pump(Duration.zero);
  });
}
