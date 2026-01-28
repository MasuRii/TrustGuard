import 'package:flutter/material.dart';
import '../animations/animation_config.dart';

/// A bidirectional progress bar that visualizes a balance amount relative to a maximum.
/// Positive amounts extend to the right (green), negative to the left (red).
class BalanceProgressBar extends StatelessWidget {
  final int amount;
  final int maxAmount;
  final String currencyCode;
  final String Function(int minorUnits, {String currencyCode, String? locale})
  formatMoney;
  final bool showLabel;
  final double height;

  const BalanceProgressBar({
    super.key,
    required this.amount,
    required this.maxAmount,
    required this.currencyCode,
    required this.formatMoney,
    this.showLabel = true,
    this.height = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = amount > 0;
    final isNegative = amount < 0;

    // Calculate width factor (0.0 to 1.0) relative to the half-width
    final absAmount = amount.abs();
    final effectiveMax = maxAmount == 0 ? 1 : maxAmount;
    final widthFactor = (absAmount / effectiveMax).clamp(0.0, 1.0);

    final color = isPositive
        ? Colors.green
        : isNegative
        ? Colors.red
        : theme.disabledColor;

    final formattedAmount = formatMoney(absAmount, currencyCode: currencyCode);
    final description = isPositive
        ? 'Credit: $formattedAmount'
        : isNegative
        ? 'Debt: $formattedAmount'
        : 'Settled';

    return Semantics(
      label: description,
      value: formattedAmount,
      readOnly: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLabel) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                formattedAmount,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: isPositive
                    ? TextAlign.right
                    : isNegative
                    ? TextAlign.left
                    : TextAlign.center,
              ),
            ),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final halfWidth = maxWidth / 2;
              final barWidth = halfWidth * widthFactor;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Background track
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                  // The progress bar (negative side)
                  Positioned(
                    right: halfWidth,
                    child: AnimatedContainer(
                      duration: AnimationConfig.defaultDuration,
                      curve: Curves.easeOutCubic,
                      width: isNegative ? barWidth : 0,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(height / 2),
                        ),
                      ),
                    ),
                  ),
                  // The progress bar (positive side)
                  Positioned(
                    left: halfWidth,
                    child: AnimatedContainer(
                      duration: AnimationConfig.defaultDuration,
                      curve: Curves.easeOutCubic,
                      width: isPositive ? barWidth : 0,
                      height: height,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(height / 2),
                        ),
                      ),
                    ),
                  ),
                  // Center line
                  Container(
                    width: 2,
                    height: height + 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
