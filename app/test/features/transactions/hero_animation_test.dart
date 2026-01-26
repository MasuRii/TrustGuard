import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_list_screen.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_detail_screen.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    // db is closed inside tests
  });

  testWidgets('Hero tags are consistent between list and detail', (
    tester,
  ) async {
    final groupId = 'g1';
    final txId = 't1';

    // Seed data
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
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    // 1. Check Hero in List Screen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(TransactionListScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(
      const Duration(seconds: 1),
    ); // Wait for data to load and skeletons to fade

    final listHero = find.byElementPredicate((element) {
      if (element.widget is Hero) {
        return (element.widget as Hero).tag == 'transaction_icon_$txId';
      }
      return false;
    });
    expect(listHero, findsOneWidget);

    // 2. Check Hero in Detail Screen
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(
          TransactionDetailScreen(groupId: groupId, transactionId: txId),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1)); // Skip skeletons

    final detailHeroWithTag = find.byElementPredicate((element) {
      if (element.widget is Hero) {
        return (element.widget as Hero).tag == 'transaction_icon_$txId';
      }
      return false;
    });
    expect(detailHeroWithTag, findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('Navigation doesn\'t crash with Hero widgets', (tester) async {
    final groupId = 'g1';
    final txId = 't1';

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
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test Tx',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: MaterialApp(
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: TransactionListScreen(groupId: groupId),
          onGenerateRoute: (settings) {
            if (settings.name == '/detail') {
              return MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(
                  groupId: groupId,
                  transactionId: txId,
                ),
              );
            }
            return null;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Test Tx'), findsOneWidget);

    // Manually simulate navigation to avoid GoRouter dependency in TransactionListScreen onTap
    final context = tester.element(find.byType(TransactionListScreen));
    Navigator.of(context).pushNamed('/detail');

    // Verify transition doesn't crash
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(find.byType(TransactionDetailScreen), findsOneWidget);
    expect(find.text('Transaction Details'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
