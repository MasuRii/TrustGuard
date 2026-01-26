import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trustguard/src/features/transactions/presentation/widgets/split_preview_bar.dart';
import '../../helpers/localization_helper.dart';
import '../../helpers/shared_prefs_helper.dart';

void main() {
  testWidgets('SplitPreviewBar shows correct status when splits match', (
    WidgetTester tester,
  ) async {
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...prefsOverrides],
        child: wrapWithLocalization(
          const Scaffold(
            body: SplitPreviewBar(
              totalAmount: 10000,
              splits: {'m1': 6000, 'm2': 4000},
              memberNames: {'m1': 'Alice', 'm2': 'Bob'},
              currencyCode: 'USD',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total matches!'), findsOneWidget);
    expect(find.text('\$100.00'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
    'SplitPreviewBar shows mismatch status when splits do not match',
    (WidgetTester tester) async {
      final prefsOverrides = await getSharedPrefsOverride();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [...prefsOverrides],
          child: wrapWithLocalization(
            const Scaffold(
              body: SplitPreviewBar(
                totalAmount: 10000,
                splits: {'m1': 6000, 'm2': 3000},
                memberNames: {'m1': 'Alice', 'm2': 'Bob'},
                currencyCode: 'USD',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total mismatch'), findsOneWidget);
      expect(find.text('Remaining: \$10.00'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    },
  );

  testWidgets('SplitPreviewBar segments are proportional', (
    WidgetTester tester,
  ) async {
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...prefsOverrides],
        child: wrapWithLocalization(
          const Scaffold(
            body: SplitPreviewBar(
              totalAmount: 100,
              splits: {'m1': 70, 'm2': 30},
              memberNames: {'m1': 'Alice', 'm2': 'Bob'},
              currencyCode: 'USD',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Expanded widgets have correct flex values
    final expandedWidgets = tester.widgetList<Expanded>(find.byType(Expanded));
    expect(expandedWidgets.length, 2);
    expect(expandedWidgets.first.flex, 700); // 0.7 * 1000
    expect(expandedWidgets.last.flex, 300); // 0.3 * 1000
  });

  testWidgets('SplitPreviewBar assigns different colors to different members', (
    WidgetTester tester,
  ) async {
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...prefsOverrides],
        child: wrapWithLocalization(
          const Scaffold(
            body: SplitPreviewBar(
              totalAmount: 100,
              splits: {'m1': 50, 'm2': 50},
              memberNames: {'m1': 'Alice', 'm2': 'Bob'},
              currencyCode: 'USD',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final containers = tester.widgetList<Container>(
      find.descendant(of: find.byType(Row), matching: find.byType(Container)),
    );

    // We expect 2 containers (one for each member)
    expect(containers.length, 2);
    expect(containers.first.color, isNot(equals(containers.last.color)));
  });

  testWidgets('SplitPreviewBar handles empty state', (
    WidgetTester tester,
  ) async {
    final prefsOverrides = await getSharedPrefsOverride();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [...prefsOverrides],
        child: wrapWithLocalization(
          const Scaffold(
            body: SplitPreviewBar(
              totalAmount: 0,
              splits: {},
              memberNames: {},
              currencyCode: 'USD',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Total matches!'), findsOneWidget);
    expect(find.text('\$0.00'), findsOneWidget);
    // Bar should be empty (no segments)
    expect(find.byType(Expanded), findsNothing);
  });
}
