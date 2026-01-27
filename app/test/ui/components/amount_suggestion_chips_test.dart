import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/amount_suggestion_chips.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('AmountSuggestionChips', () {
    testWidgets('renders suggestions correctly', (tester) async {
      final suggestions = [1000, 2550, 5000];

      await tester.pumpWidget(
        wrap(
          AmountSuggestionChips(
            suggestions: suggestions,
            currencyCode: 'USD',
            onSelected: (_) {},
          ),
        ),
      );

      // Verify labels are formatted correctly
      // 1000 -> $10 (decimalDigits: 0)
      // 2550 -> $25.50 (decimalDigits: 2)
      // 5000 -> $50 (decimalDigits: 0)

      expect(find.text('\$10'), findsOneWidget);
      expect(find.text('\$25.50'), findsOneWidget);
      expect(find.text('\$50'), findsOneWidget);

      // Verify all suggestions are present as ActionChips
      expect(find.byType(ActionChip), findsNWidgets(3));
    });

    testWidgets('calls onSelected when chip is tapped', (tester) async {
      final suggestions = [1000, 2000];
      int? selectedAmount;

      await tester.pumpWidget(
        wrap(
          AmountSuggestionChips(
            suggestions: suggestions,
            currencyCode: 'USD',
            onSelected: (amount) => selectedAmount = amount,
          ),
        ),
      );

      await tester.tap(find.text('\$20'));
      await tester.pump();

      expect(selectedAmount, 2000);
    });

    testWidgets('renders nothing when suggestions are empty', (tester) async {
      await tester.pumpWidget(
        wrap(AmountSuggestionChips(suggestions: const [], onSelected: (_) {})),
      );

      expect(find.byType(ActionChip), findsNothing);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('applies compact layout and theme-consistent colors', (
      tester,
    ) async {
      final suggestions = [1000];

      await tester.pumpWidget(
        wrap(
          AmountSuggestionChips(suggestions: suggestions, onSelected: (_) {}),
        ),
      );

      final ActionChip chip = tester.widget(find.byType(ActionChip));
      expect(chip.visualDensity, VisualDensity.compact);
      expect(chip.side, BorderSide.none);
      expect(chip.shape, isA<RoundedRectangleBorder>());

      final RoundedRectangleBorder shape = chip.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(20));
    });
  });
}
