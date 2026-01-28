import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:trustguard/src/core/models/expense.dart';
import 'package:trustguard/src/core/models/transaction.dart';
import 'package:trustguard/src/features/sharing/models/shareable_expense.dart';
import 'package:trustguard/src/features/sharing/presentation/share_expense_sheet.dart';
import 'package:trustguard/src/features/sharing/services/qr_generation_service.dart';

class MockQrGenerationService extends Mock implements QrGenerationService {}

void main() {
  late MockQrGenerationService mockService;

  setUp(() {
    mockService = MockQrGenerationService();
  });

  final testTransaction = Transaction(
    id: 'tx1',
    groupId: 'g1',
    type: TransactionType.expense,
    note: 'Dinner',
    occurredAt: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
    expenseDetail: const ExpenseDetail(
      payerMemberId: 'm1',
      totalAmountMinor: 1000,
      splitType: SplitType.equal,
      participants: [],
    ),
    tags: [],
  );

  final testShareableExpense = ShareableExpense(
    type: ShareableType.expense,
    description: 'Dinner',
    amountMinor: 1000,
    currencyCode: 'USD',
    date: DateTime(2023, 1, 1),
    payerName: 'Alice',
    participants: [],
    sourceId: 'tx1',
  );

  testWidgets('ShareExpenseSheet generates and displays QR code', (
    tester,
  ) async {
    when(
      () => mockService.generateForTransaction(testTransaction),
    ).thenAnswer((_) async => testShareableExpense);
    when(
      () => mockService.getQrData(testShareableExpense),
    ).thenReturn('TG:DATA');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [qrGenerationServiceProvider.overrideWithValue(mockService)],
        child: MaterialApp(
          home: Scaffold(body: ShareExpenseSheet(transaction: testTransaction)),
        ),
      ),
    );

    // Initial state: Loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for generation
    await tester.pumpAndSettle();

    // Verify QR code
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Share Expense'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget); // Summary description
    expect(find.text('Share Code as Text'), findsOneWidget);
  });

  testWidgets('ShareExpenseSheet shows error message on failure', (
    tester,
  ) async {
    when(
      () => mockService.generateForTransaction(testTransaction),
    ).thenThrow(Exception('Generation Failed'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [qrGenerationServiceProvider.overrideWithValue(mockService)],
        child: MaterialApp(
          home: Scaffold(body: ShareExpenseSheet(transaction: testTransaction)),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Failed to generate QR code: Exception: Generation Failed'),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsNothing);
  });
}
