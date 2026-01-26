import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trustguard/src/ui/components/empty_state.dart';

void main() {
  group('EmptyState Tests', () {
    testWidgets('EmptyState renders icon when provided', (tester) async {
      const icon = Icons.receipt_long_outlined;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: icon,
              title: 'No Data',
              message: 'Check back later',
            ),
          ),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Check back later'), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('EmptyState renders SVG when provided', (tester) async {
      const svgPath = 'assets/illustrations/no_transactions.svg';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              svgPath: svgPath,
              title: 'No Transactions',
              message: 'Start by adding an expense',
            ),
          ),
        ),
      );

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('No Transactions'), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
    });

    testWidgets('EmptyState shows action button and handles tap', (
      tester,
    ) async {
      bool pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.add,
              title: 'Empty',
              message: 'Try adding something',
              actionLabel: 'Add Item',
              onActionPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textFinder = find.text('Add Item');
      expect(textFinder, findsOneWidget);

      await tester.tap(textFinder);
      expect(pressed, isTrue);
    });

    testWidgets(
      'EmptyState throws error if neither icon nor svgPath provided',
      (tester) async {
        expect(
          () => EmptyState(title: 'T', message: 'M'),
          throwsA(isA<AssertionError>()),
        );
      },
    );
  });
}
