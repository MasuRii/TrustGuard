import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/models/member.dart';
import 'package:trustguard/src/ui/components/member_avatar_selector.dart';
import '../../helpers/localization_helper.dart';

void main() {
  final testMembers = [
    Member(
      id: 'm1',
      groupId: 'g1',
      displayName: 'Alice',
      createdAt: DateTime.now(),
    ),
    Member(
      id: 'm2',
      groupId: 'g1',
      displayName: 'Bob',
      createdAt: DateTime.now(),
    ),
    Member(
      id: 'm3',
      groupId: 'g1',
      displayName: 'Charlie',
      createdAt: DateTime.now(),
    ),
  ];

  testWidgets('MemberAvatarSelector displays all members', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: MemberAvatarSelector(
            members: testMembers,
            selectedIds: const {},
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Charlie'), findsOneWidget);
    expect(find.text('A'), findsOneWidget); // Alice initials
    expect(find.text('B'), findsOneWidget); // Bob initials
    expect(find.text('C'), findsOneWidget); // Charlie initials
  });

  testWidgets('Single-select mode calls onSelectionChanged with single ID', (
    WidgetTester tester,
  ) async {
    String? selectedId;
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: MemberAvatarSelector(
            members: testMembers,
            selectedIds: const {},
            onSelectionChanged: (ids) {
              selectedId = ids.first;
            },
            allowMultiple: false,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Alice'));
    expect(selectedId, 'm1');

    await tester.tap(find.text('Bob'));
    expect(selectedId, 'm2');
  });

  testWidgets('Multi-select mode toggles selections', (
    WidgetTester tester,
  ) async {
    Set<String> currentSelection = {};

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return wrapWithLocalization(
            Scaffold(
              body: MemberAvatarSelector(
                members: testMembers,
                selectedIds: currentSelection,
                onSelectionChanged: (ids) {
                  setState(() {
                    currentSelection = ids;
                  });
                },
                allowMultiple: true,
              ),
            ),
          );
        },
      ),
    );

    // Select Alice
    await tester.tap(find.text('Alice'));
    await tester.pump();
    expect(currentSelection, {'m1'});

    // Select Bob
    await tester.tap(find.text('Bob'));
    await tester.pump();
    expect(currentSelection, {'m1', 'm2'});

    // Deselect Alice
    await tester.tap(find.text('Alice'));
    await tester.pump();
    expect(currentSelection, {'m2'});
  });

  testWidgets('Select All and None buttons work in multi-select mode', (
    WidgetTester tester,
  ) async {
    Set<String> currentSelection = {};

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          return wrapWithLocalization(
            Scaffold(
              body: MemberAvatarSelector(
                members: testMembers,
                selectedIds: currentSelection,
                onSelectionChanged: (ids) {
                  setState(() {
                    currentSelection = ids;
                  });
                },
                allowMultiple: true,
              ),
            ),
          );
        },
      ),
    );

    // Tap Select All
    await tester.tap(find.text('Select All'));
    await tester.pump();
    expect(currentSelection, {'m1', 'm2', 'm3'});

    // Tap Select None
    await tester.tap(find.text('None'));
    await tester.pump();
    expect(currentSelection, <String>{});
  });

  testWidgets('Selected members show visual highlight', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrapWithLocalization(
        Scaffold(
          body: MemberAvatarSelector(
            members: testMembers,
            selectedIds: const {'m1'},
            onSelectionChanged: (_) {},
            allowMultiple: false,
          ),
        ),
      ),
    );

    // We can check if the CircleAvatar has the primaryContainer color
    final BuildContext context = tester.element(
      find.byType(MemberAvatarSelector),
    );
    final colorScheme = Theme.of(context).colorScheme;

    // Check Alice (selected)
    final aliceAvatar = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .firstWhere((avatar) => (avatar.child as Text).data == 'A');
    expect(aliceAvatar.backgroundColor, colorScheme.primaryContainer);

    // Check Bob (unselected)
    final bobAvatar = tester
        .widgetList<CircleAvatar>(find.byType(CircleAvatar))
        .firstWhere((avatar) => (avatar.child as Text).data == 'B');
    expect(bobAvatar.backgroundColor, colorScheme.surfaceContainerHighest);
  });
}
