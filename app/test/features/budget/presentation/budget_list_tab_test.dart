import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/budget/presentation/budget_list_tab.dart';
import 'package:trustguard/src/features/budget/presentation/widgets/budget_progress_card.dart';
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;
  late String groupId;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    groupId = const Uuid().v4();
  });

  // Removed tearDown to handle closing manually in tests to fix pending timer issue

  Future<void> seedGroup() async {
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
  }

  testWidgets('BudgetListTab shows empty state when no budgets', (
    tester,
  ) async {
    await seedGroup();
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(BudgetListTab(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No active budgets'), findsOneWidget);
    expect(find.text('Create Budget'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('BudgetListTab shows list of budgets', (tester) async {
    await seedGroup();
    final prefsOverrides = await getSharedPrefsOverride();

    // Seed a budget
    final budgetId = const Uuid().v4();
    await db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: budgetId,
            groupId: groupId,
            name: 'Groceries',
            limitMinor: 50000, // $500.00
            currencyCode: 'USD',
            period: 'monthly',
            startDate: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(BudgetListTab(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(BudgetProgressCard), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
