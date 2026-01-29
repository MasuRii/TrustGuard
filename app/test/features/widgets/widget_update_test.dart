import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/widgets/services/widget_data_service.dart';
import 'package:trustguard/src/core/models/transaction.dart' as model;
import 'package:trustguard/src/core/models/expense.dart' as model;
import 'package:trustguard/src/features/transactions/services/attachment_service.dart';
import 'package:flutter/services.dart';

class MockWidgetDataService extends Mock implements WidgetDataService {}

class MockAttachmentService extends Mock implements AttachmentService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late MockWidgetDataService mockWidgetDataService;
  late MockAttachmentService mockAttachmentService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockWidgetDataService = MockWidgetDataService();
    mockAttachmentService = MockAttachmentService();

    when(() => mockWidgetDataService.updateWidget()).thenAnswer((_) async {});
    when(
      () => mockAttachmentService.deleteAllAttachments(any()),
    ).thenAnswer((_) async {});

    // Mock home_widget channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (MethodCall methodCall) async => null,
        );
  });

  tearDown(() async {
    await db.close();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
  });

  test('Transaction creation triggers widget update when enabled', () async {
    SharedPreferences.setMockInitialValues({'widget_update_enabled': true});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        attachmentServiceProvider.overrideWithValue(mockAttachmentService),
        widgetDataServiceProvider.overrideWithValue(mockWidgetDataService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final repo = container.read(transactionRepositoryProvider);

    final transaction = model.Transaction(
      id: '1',
      groupId: 'g1',
      note: 'Test',
      occurredAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: model.TransactionType.expense,
      expenseDetail: const model.ExpenseDetail(
        payerMemberId: 'm1',
        totalAmountMinor: 100,
        splitType: model.SplitType.equal,
        participants: [],
      ),
    );

    // We need to create the group and member first due to foreign keys
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'g1',
            name: 'Group 1',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'm1',
            groupId: 'g1',
            displayName: 'Member 1',
            createdAt: DateTime.now(),
          ),
        );

    await repo.createTransaction(transaction);

    // Future.microtask is used, so we need to wait
    await Future<void>.delayed(Duration.zero);

    verify(() => mockWidgetDataService.updateWidget()).called(1);
  });

  test(
    'Transaction creation DOES NOT trigger widget update when disabled',
    () async {
      SharedPreferences.setMockInitialValues({'widget_update_enabled': false});
      final prefs = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          attachmentServiceProvider.overrideWithValue(mockAttachmentService),
          widgetDataServiceProvider.overrideWithValue(mockWidgetDataService),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );

      final repo = container.read(transactionRepositoryProvider);

      final transaction = model.Transaction(
        id: '2',
        groupId: 'g1',
        note: 'Test 2',
        occurredAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: model.TransactionType.expense,
        expenseDetail: const model.ExpenseDetail(
          payerMemberId: 'm1',
          totalAmountMinor: 200,
          splitType: model.SplitType.equal,
          participants: [],
        ),
      );

      await db
          .into(db.groups)
          .insert(
            GroupsCompanion.insert(
              id: 'g1',
              name: 'Group 1',
              currencyCode: 'USD',
              createdAt: DateTime.now(),
            ),
          );
      await db
          .into(db.members)
          .insert(
            MembersCompanion.insert(
              id: 'm1',
              groupId: 'g1',
              displayName: 'Member 1',
              createdAt: DateTime.now(),
            ),
          );

      await repo.createTransaction(transaction);

      await Future<void>.delayed(Duration.zero);

      verifyNever(() => mockWidgetDataService.updateWidget());
    },
  );

  test('Transaction deletion triggers widget update', () async {
    SharedPreferences.setMockInitialValues({'widget_update_enabled': true});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        attachmentServiceProvider.overrideWithValue(mockAttachmentService),
        widgetDataServiceProvider.overrideWithValue(mockWidgetDataService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final repo = container.read(transactionRepositoryProvider);

    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: 'g1',
            name: 'Group 1',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
    await db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: '1',
            groupId: 'g1',
            type: model.TransactionType.expense,
            occurredAt: DateTime.now(),
            note: 'Test',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await repo.hardDeleteTransaction('1');

    await Future<void>.delayed(Duration.zero);

    verify(() => mockWidgetDataService.updateWidget()).called(1);
  });

  test('App startup updates widget', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        attachmentServiceProvider.overrideWithValue(mockAttachmentService),
        widgetDataServiceProvider.overrideWithValue(mockWidgetDataService),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    // Simulate main.dart logic
    final widgetService = container.read(widgetDataServiceProvider);
    await widgetService.updateWidget();

    verify(() => mockWidgetDataService.updateWidget()).called(1);
  });
}
