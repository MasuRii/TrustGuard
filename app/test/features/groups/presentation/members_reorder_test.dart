import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/features/groups/presentation/members_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;
import '../../../helpers/localization_helper.dart';
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

  Future<void> createMember(
    String id,
    String groupId,
    String name,
    int orderIndex,
  ) async {
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: id,
            groupId: groupId,
            displayName: name,
            createdAt: DateTime.now(),
            orderIndex: Value(orderIndex),
          ),
        );
  }

  testWidgets('MembersScreen supports reordering members', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    final aliceId = const Uuid().v4();
    final bobId = const Uuid().v4();

    await createMember(aliceId, groupId, 'Alice', 0);
    await createMember(bobId, groupId, 'Bob', 1);

    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db), ...prefsOverrides],
        child: wrapWithLocalization(MembersScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);

    // Find drag handles
    final handles = find.byIcon(Icons.drag_handle);
    expect(handles, findsNWidgets(2));

    // Verify initial order in UI
    final alicePos = tester.getCenter(find.byKey(ValueKey(aliceId)));
    final bobPos = tester.getCenter(find.byKey(ValueKey(bobId)));
    expect(alicePos.dy < bobPos.dy, isTrue);

    // Drag Alice below Bob
    final firstHandle = tester.getCenter(handles.first);
    final gesture = await tester.startGesture(firstHandle);
    await tester.pump(kPressTimeout);
    await gesture.moveBy(
      const Offset(0, 150),
    ); // Large enough offset to move past Bob
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify order in UI changed
    final alicePosNew = tester.getCenter(find.byKey(ValueKey(aliceId)));
    final bobPosNew = tester.getCenter(find.byKey(ValueKey(bobId)));
    expect(alicePosNew.dy > bobPosNew.dy, isTrue);

    // Verify order in DB
    final members = await db.select(db.members).get();
    final alice = members.firstWhere((m) => m.id == aliceId);
    final bob = members.firstWhere((m) => m.id == bobId);

    // Alice should now have orderIndex 1, Bob 0
    expect(alice.orderIndex, 1);
    expect(bob.orderIndex, 0);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets(
    'MembersScreen disables reordering when showing removed members',
    (WidgetTester tester) async {
      final groupId = const Uuid().v4();
      await setupGroup(groupId);

      await createMember(const Uuid().v4(), groupId, 'Alice', 0);
      await createMember(const Uuid().v4(), groupId, 'Bob', 1);

      final prefsOverrides = await getSharedPrefsOverride();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ...prefsOverrides,
          ],
          child: wrapWithLocalization(MembersScreen(groupId: groupId)),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);
      await tester.pumpAndSettle();

      // Initially reorderable
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(2));

      // Toggle show removed
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();
      await tester.pumpAndSettle();

      // Drag handles should be gone (reordering disabled)
      expect(find.byIcon(Icons.drag_handle), findsNothing);

      await db.close();
      await tester.pump(Duration.zero);
    },
  );
}
