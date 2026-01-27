import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/transactions/presentation/transaction_detail_screen.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart' as l10n;
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  Future<void> setupGroup(String id) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: id,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> setupMember(String id, String groupId, String name) async {
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: id,
            groupId: groupId,
            displayName: name,
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('TransactionDetailScreen shows expense details', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final txId = const Uuid().v4();

    await setupGroup(groupId);
    await setupMember(memberId, groupId, 'Alice');

    // Insert an expense
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime(2026, 1, 26, 12, 0),
            note: 'Lunch',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.expenseDetails)
        .insert(
          ExpenseDetailsCompanion.insert(
            txId: txId,
            payerMemberId: memberId,
            totalAmountMinor: 1500,
            splitType: SplitType.equal,
          ),
        );
    await db
        .into(db.expenseParticipants)
        .insert(
          ExpenseParticipantsCompanion.insert(
            txId: txId,
            memberId: memberId,
            owedAmountMinor: 1500,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: MaterialApp.router(
          localizationsDelegates: l10n.localizationsDelegates,
          supportedLocales: l10n.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/detail',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(body: Text('Home')),
              ),
              GoRoute(
                path: '/detail',
                builder: (context, state) => TransactionDetailScreen(
                  groupId: groupId,
                  transactionId: txId,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Lunch'), findsOneWidget);
    expect(find.text(r'$15.00'), findsNWidgets(2)); // Header and split list
    expect(find.text('Paid by'), findsOneWidget);
    expect(
      find.text('Alice'),
      findsNWidgets(2),
    ); // Paid by Alice and Split details list Alice
    expect(find.text('Expense'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('TransactionDetailScreen shows transfer details', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final aliceId = const Uuid().v4();
    final bobId = const Uuid().v4();
    final txId = const Uuid().v4();

    await setupGroup(groupId);
    await setupMember(aliceId, groupId, 'Alice');
    await setupMember(bobId, groupId, 'Bob');

    // Insert a transfer
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.transfer,
            occurredAt: DateTime(2026, 1, 26, 12, 0),
            note: 'Settlement',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await db
        .into(db.transferDetails)
        .insert(
          TransferDetailsCompanion.insert(
            txId: txId,
            fromMemberId: aliceId,
            toMemberId: bobId,
            amountMinor: 1000,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: MaterialApp.router(
          localizationsDelegates: l10n.localizationsDelegates,
          supportedLocales: l10n.supportedLocales,
          routerConfig: GoRouter(
            initialLocation: '/detail',
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(body: Text('Home')),
              ),
              GoRoute(
                path: '/detail',
                builder: (context, state) => TransactionDetailScreen(
                  groupId: groupId,
                  transactionId: txId,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Settlement'), findsOneWidget);
    expect(find.text(r'$10.00'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('To'), findsOneWidget);
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Transfer'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('TransactionDetailScreen can delete transaction', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();
    final txId = const Uuid().v4();

    await setupGroup(groupId);
    await setupMember(memberId, groupId, 'Alice');

    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: txId,
            groupId: groupId,
            type: TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Lunch',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/detail',
          builder: (context, state) =>
              TransactionDetailScreen(groupId: groupId, transactionId: txId),
        ),
      ],
    );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: MaterialApp.router(
          localizationsDelegates: l10n.localizationsDelegates,
          supportedLocales: l10n.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    router.push('/detail');
    await tester.pumpAndSettle();

    // Tap delete icon
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Confirm delete in dialog
    await tester.tap(find.text('Delete'));
    // Use pump instead of pumpAndSettle to avoid flushing the 5s timer
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify snackbar is shown
    expect(find.text('Transaction deleted'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Verify transaction is NOT yet soft-deleted (due to delay)
    final txPending = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(txId))).getSingle();
    expect(txPending.deletedAt, isNull);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Verify transaction is still not deleted
    final txRestored = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals(txId))).getSingle();
    expect(txRestored.deletedAt, isNull);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
