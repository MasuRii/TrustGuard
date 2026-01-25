import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/groups/presentation/members_screen.dart';
import 'package:uuid/uuid.dart';

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

  testWidgets('MembersScreen lists members and allows adding new one', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: MembersScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    expect(find.text('No members found'), findsOneWidget);

    // Tap Add button
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    // Enter name
    await tester.enterText(find.byType(TextFormField), 'Alice');
    await tester.tap(find.byIcon(Icons.check));
    // Multiple pumps to allow database transaction and stream update
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('No members found'), findsNothing);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('MembersScreen allows removing and restoring members', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    final memberId = const Uuid().v4();

    await setupGroup(groupId);
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: memberId,
            groupId: groupId,
            displayName: 'Bob',
            createdAt: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(home: MembersScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    expect(find.text('Bob'), findsOneWidget);

    // Remove Bob
    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Bob should be gone by default (since showRemoved is false)
    expect(find.text('Bob'), findsNothing);
    expect(find.text('No members found'), findsOneWidget);

    // Toggle show removed
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Bob'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsOneWidget);

    // Restore Bob
    await tester.tap(find.byIcon(Icons.restore));
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
