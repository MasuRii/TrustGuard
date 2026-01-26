import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/database/repositories/recurring_transaction_repository.dart';
import 'package:trustguard/src/core/database/repositories/transaction_repository.dart';
import 'package:trustguard/src/core/models/recurring_transaction.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/features/transactions/services/recurrence_service.dart';

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late RecurrenceService service;
  late MockRecurringTransactionRepository mockRecurringRepo;
  late MockTransactionRepository mockTransactionRepo;

  setUp(() {
    mockRecurringRepo = MockRecurringTransactionRepository();
    mockTransactionRepo = MockTransactionRepository();
    service = RecurrenceService(
      recurringRepo: mockRecurringRepo,
      transactionRepo: mockTransactionRepo,
    );

    registerFallbackValue(
      Transaction(
        id: '',
        groupId: '',
        type: TransactionType.expense,
        occurredAt: DateTime.now(),
        note: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('RecurrenceService', () {
    test('calculateNextOccurrence for each frequency', () {
      final now = DateTime(2024, 1, 1, 10, 0);

      expect(
        service.calculateNextOccurrence(now, RecurrenceFrequency.daily),
        DateTime(2024, 1, 2, 10, 0),
      );
      expect(
        service.calculateNextOccurrence(now, RecurrenceFrequency.weekly),
        DateTime(2024, 1, 8, 10, 0),
      );
      expect(
        service.calculateNextOccurrence(now, RecurrenceFrequency.biweekly),
        DateTime(2024, 1, 15, 10, 0),
      );
      expect(
        service.calculateNextOccurrence(now, RecurrenceFrequency.monthly),
        DateTime(2024, 2, 1, 10, 0),
      );
      expect(
        service.calculateNextOccurrence(now, RecurrenceFrequency.yearly),
        DateTime(2025, 1, 1, 10, 0),
      );
    });

    test('calculateNextOccurrence handles end of month normalization', () {
      // Jan 31 + 1 month -> Mar 2 (normalization)
      final jan31 = DateTime(2024, 1, 31);
      expect(
        service.calculateNextOccurrence(jan31, RecurrenceFrequency.monthly),
        DateTime(2024, 3, 2),
      );
    });

    test(
      'checkAndCreateDueTransactions creates new transactions and updates nextOccurrence',
      () async {
        final nextOcc = DateTime(2024, 1, 1, 10, 0);
        final recurring = RecurringTransaction(
          id: 'r1',
          groupId: 'g1',
          templateTransactionId: 't1',
          frequency: RecurrenceFrequency.weekly,
          nextOccurrence: nextOcc,
          createdAt: DateTime.now(),
        );

        final template = Transaction(
          id: 't1',
          groupId: 'g1',
          type: TransactionType.expense,
          occurredAt: nextOcc.subtract(const Duration(days: 7)),
          note: 'Template',
          expenseDetail: const ExpenseDetail(
            payerMemberId: 'm1',
            totalAmountMinor: 1000,
            splitType: SplitType.equal,
            participants: [],
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockRecurringRepo.getDueRecurrings(any()),
        ).thenAnswer((_) async => [recurring]);
        when(
          () => mockTransactionRepo.getTransactionById('t1'),
        ).thenAnswer((_) async => template);
        when(
          () => mockTransactionRepo.createTransaction(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRecurringRepo.updateNextOccurrence(any(), any()),
        ).thenAnswer((_) async => {});

        await service.checkAndCreateDueTransactions();

        verify(
          () => mockTransactionRepo.createTransaction(
            any(
              that: predicate<Transaction>(
                (tx) =>
                    tx.occurredAt == nextOcc &&
                    tx.note == 'Template' &&
                    tx.expenseDetail?.totalAmountMinor == 1000 &&
                    tx.id != 't1',
              ),
            ),
          ),
        ).called(1);

        verify(
          () => mockRecurringRepo.updateNextOccurrence(
            'r1',
            DateTime(2024, 1, 8, 10, 0),
          ),
        ).called(1);
      },
    );

    test(
      'checkAndCreateDueTransactions deactivates if endDate passed',
      () async {
        final nextOcc = DateTime(2024, 1, 1);
        final endDate = DateTime(2024, 1, 5);
        final recurring = RecurringTransaction(
          id: 'r1',
          groupId: 'g1',
          templateTransactionId: 't1',
          frequency: RecurrenceFrequency
              .weekly, // Next will be 2024-01-08, which is after 2024-01-05
          nextOccurrence: nextOcc,
          endDate: endDate,
          createdAt: DateTime.now(),
        );

        final template = Transaction(
          id: 't1',
          groupId: 'g1',
          type: TransactionType.expense,
          occurredAt: nextOcc,
          note: 'Template',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(
          () => mockRecurringRepo.getDueRecurrings(any()),
        ).thenAnswer((_) async => [recurring]);
        when(
          () => mockTransactionRepo.getTransactionById('t1'),
        ).thenAnswer((_) async => template);
        when(
          () => mockTransactionRepo.createTransaction(any()),
        ).thenAnswer((_) async => {});
        when(
          () => mockRecurringRepo.deactivateRecurring(any()),
        ).thenAnswer((_) async => {});

        await service.checkAndCreateDueTransactions();

        verify(() => mockRecurringRepo.deactivateRecurring('r1')).called(1);
        verifyNever(() => mockRecurringRepo.updateNextOccurrence(any(), any()));
      },
    );

    test(
      'checkAndCreateDueTransactions deactivates if template missing',
      () async {
        final recurring = RecurringTransaction(
          id: 'r1',
          groupId: 'g1',
          templateTransactionId: 'missing',
          frequency: RecurrenceFrequency.weekly,
          nextOccurrence: DateTime.now(),
          createdAt: DateTime.now(),
        );

        when(
          () => mockRecurringRepo.getDueRecurrings(any()),
        ).thenAnswer((_) async => [recurring]);
        when(
          () => mockTransactionRepo.getTransactionById('missing'),
        ).thenAnswer((_) async => null);
        when(
          () => mockRecurringRepo.deactivateRecurring(any()),
        ).thenAnswer((_) async => {});

        await service.checkAndCreateDueTransactions();

        verify(() => mockRecurringRepo.deactivateRecurring('r1')).called(1);
        verifyNever(() => mockTransactionRepo.createTransaction(any()));
      },
    );
  });
}
