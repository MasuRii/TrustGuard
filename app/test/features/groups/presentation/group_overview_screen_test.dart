import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/groups/presentation/group_overview_screen.dart';
import 'package:trustguard/src/core/models/group.dart' as model;
import 'package:uuid/uuid.dart';
import '../../../helpers/localization_helper.dart';
import '../../../helpers/shared_prefs_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  testWidgets('GroupOverviewScreen shows group details', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final group = model.Group(
      id: groupId,
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime.now(),
    );

    // Seed the database
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: group.id,
            name: group.name,
            currencyCode: group.currencyCode,
            createdAt: group.createdAt,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(GroupOverviewScreen(groupId: groupId)),
      ),
    );

    // Initial pump to build the widget tree
    await tester.pump();
    // Pump again to let the StreamProvider emit data
    await tester.pump(Duration.zero);

    expect(find.text('Test Group'), findsWidgets);
    expect(find.text('Currency: USD'), findsOneWidget);
    expect(find.text('Members'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('GroupOverviewScreen shows error when group not found', (
    WidgetTester tester,
  ) async {
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(
          const GroupOverviewScreen(groupId: 'non-existent'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    expect(find.text('Group not found'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('GroupOverviewScreen switches to Budgets tab', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final group = model.Group(
      id: groupId,
      name: 'Test Group',
      currencyCode: 'USD',
      createdAt: DateTime.now(),
    );

    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: group.id,
            name: group.name,
            currencyCode: group.currencyCode,
            createdAt: group.createdAt,
          ),
        );

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(GroupOverviewScreen(groupId: groupId)),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Overview tab is active by default
    expect(find.text('Quick Actions'), findsOneWidget);

    // Switch to Budgets tab
    await tester.tap(find.text('Budgets'));
    await tester.pumpAndSettle();

    // Verify Budgets tab content (empty state)
    expect(find.text('No active budgets'), findsOneWidget);
    expect(find.text('Create Budget'), findsNWidgets(2));

    await db.close();
    await tester.pump(Duration.zero);
  });
}
