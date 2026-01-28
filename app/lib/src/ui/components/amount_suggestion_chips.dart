import 'package:flutter/material.dart';
import '../../core/utils/money.dart';
import '../../core/utils/haptics.dart';

/// A widget that displays horizontal scrolling chips for suggested amounts.
class AmountSuggestionChips extends StatelessWidget {
  /// The list of suggested amounts in minor units.
  final List<int> suggestions;

  /// The currency code to display (e.g., 'USD').
  final String currencyCode;

  /// Callback when a suggestion is selected.
  final ValueChanged<int> onSelected;

  const AmountSuggestionChips({
    super.key,
    required this.suggestions,
    this.currencyCode = 'USD',
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.0),
            Colors.white,
          ],
          stops: const [0.0, 0.05, 0.95, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: suggestions.map((amount) {
            final label = MoneyUtils.format(
              amount,
              currencyCode: currencyCode,
              decimalDigits: amount % 100 == 0 ? 0 : 2,
            );

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Semantics(
                button: true,
                label: 'Suggest amount $label',
                hint: 'Double tap to use this amount',
                child: ActionChip(
                  label: Text(label),
                  onPressed: () {
                    HapticsService.lightTap();
                    onSelected(amount);
                  },
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
