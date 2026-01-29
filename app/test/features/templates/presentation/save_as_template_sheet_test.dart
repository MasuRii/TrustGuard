import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/repositories/template_repository.dart';
import 'package:trustguard/src/core/models/expense_template.dart'
    as template_model;
import 'package:trustguard/src/core/models/expense.dart' as expense_model;
import 'package:trustguard/src/features/templates/presentation/save_as_template_sheet.dart';
import 'package:trustguard/src/features/transactions/models/expense_form_data.dart';
import 'package:trustguard/src/ui/theme/app_theme.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late MockTemplateRepository mockRepository;

  setUp(() {
    mockRepository = MockTemplateRepository();
    registerFallbackValue(
      template_model.ExpenseTemplate(
        id: 'fallback',
        groupId: 'fallback',
        name: 'fallback',
        currencyCode: 'USD',
        payerId: 'fallback',
        splitType: template_model.SplitType.equal,
        tagIds: [],
        orderIndex: 0,
        createdAt: DateTime.now(),
        usageCount: 0,
      ),
    );
  });

  // Helper to pump the sheet
  Future<void> pumpSheet(WidgetTester tester, ExpenseFormData formData) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          templateRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => SaveAsTemplateSheet(
                      groupId: 'group1',
                      initialData: formData,
                    ),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();
  }

  const formData = ExpenseFormData(
    groupId: 'group1',
    payerId: 'user1',
    description: 'Grocery Run',
    amount: 50.0,
    currencyCode: 'USD',
    splitType: expense_model.SplitType.equal,
    customSplitMode: CustomSplitMode.amount,
    participantIds: ['user1', 'user2'],
    tagIds: ['tag1'],
    customAmounts: null,
    customPercentages: null,
  );

  testWidgets('renders correctly with initial data', (tester) async {
    when(
      () => mockRepository.getTemplatesByGroup('group1'),
    ).thenAnswer((_) async => []);

    await pumpSheet(tester, formData);

    expect(find.text('Save as Template'), findsOneWidget);
    expect(
      find.text('Grocery Run'),
      findsOneWidget,
    ); // Pre-filled description as name
    expect(find.text('Save Amount'), findsOneWidget);
    expect(find.text('USD 50.00'), findsOneWidget); // Preview
  });

  testWidgets('validates empty name', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(
      () => mockRepository.getTemplatesByGroup('group1'),
    ).thenAnswer((_) async => []);

    await pumpSheet(tester, formData);

    // Clear name
    await tester.enterText(find.byType(TextFormField).first, '');
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Template');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name'), findsOneWidget);
  });

  testWidgets('saves template successfully', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(
      () => mockRepository.getTemplatesByGroup('group1'),
    ).thenAnswer((_) async => []);
    when(
      () => mockRepository.createTemplate(any()),
    ).thenAnswer((_) async => {});

    await pumpSheet(tester, formData);

    await tester.enterText(find.byType(TextFormField).first, 'My Template');
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Template');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(() => mockRepository.createTemplate(any())).called(1);
    expect(find.byType(SaveAsTemplateSheet), findsNothing); // Should pop
  });

  testWidgets('shows error on duplicate name', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    when(() => mockRepository.getTemplatesByGroup('group1')).thenAnswer(
      (_) async => [
        template_model.ExpenseTemplate(
          id: 'existing',
          groupId: 'group1',
          name: 'My Template',
          currencyCode: 'USD',
          payerId: 'user1',
          splitType: template_model.SplitType.equal,
          tagIds: [],
          orderIndex: 0,
          createdAt: DateTime.now(),
          usageCount: 0,
        ),
      ],
    );

    await pumpSheet(tester, formData);

    await tester.enterText(find.byType(TextFormField).first, 'My Template');
    final saveButton = find.widgetWithText(ElevatedButton, 'Save Template');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      find.text('A template with this name already exists'),
      findsOneWidget,
    );
    verifyNever(() => mockRepository.createTemplate(any()));
  });
}
