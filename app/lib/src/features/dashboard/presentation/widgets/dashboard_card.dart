import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../app/app.dart';
import '../../../../app/providers.dart';
import '../../../../ui/animations/animation_config.dart';
import '../../../../ui/components/balance_progress_bar.dart';
import '../../../../ui/components/rolling_number_text.dart';
import '../../../../ui/theme/app_theme.dart';
import '../../models/global_balance_summary.dart';
import '../../providers/dashboard_providers.dart';

/// A card that displays a summary of balances across all groups.
class DashboardCard extends ConsumerWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(globalBalanceSummaryProvider);

    return summaryAsync.when(
      data: (summary) => _DashboardCardContent(summary: summary),
      loading: () => const _DashboardCardSkeleton(),
      error: (error, stack) => _DashboardCardError(
        onRetry: () => ref.refresh(globalBalanceSummaryProvider),
      ),
    );
  }
}

class _DashboardCardContent extends ConsumerWidget {
  final GlobalBalanceSummary summary;

  const _DashboardCardContent({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final formatMoney = ref.watch(moneyFormatterProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxAmount = math.max(
      summary.totalOwedByMe.abs(),
      summary.totalOwedToMe.abs(),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.dashboardTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () => ref.refresh(globalBalanceSummaryProvider),
                  tooltip: l10n.retry,
                  constraints: const BoxConstraints(
                    minWidth: AppTheme.minTouchTarget,
                    minHeight: AppTheme.minTouchTarget,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space8),
            Row(
              children: [
                Expanded(
                  child: _BalanceItem(
                    label: l10n.youOwe,
                    amount: summary.totalOwedByMe,
                    maxAmount: maxAmount,
                    // Use negative amount for "You Owe" to show on left (red)
                    barAmount: -summary.totalOwedByMe,
                    color: summary.totalOwedByMe > 0
                        ? colorScheme.error
                        : Colors.green,
                    formatMoney: formatMoney,
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: _BalanceItem(
                    label: l10n.owedToYou,
                    amount: summary.totalOwedToMe,
                    maxAmount: maxAmount,
                    // Use positive amount for "Owed To You" to show on right (green)
                    barAmount: summary.totalOwedToMe,
                    color: summary.totalOwedToMe > 0
                        ? Colors.green
                        : theme.disabledColor,
                    formatMoney: formatMoney,
                  ),
                ),
              ],
            ),
            const Divider(height: AppTheme.space24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.netBalance, style: theme.textTheme.labelMedium),
                    RollingNumberText(
                      value: summary.netBalance,
                      formatFn: formatMoney,
                      duration: AnimationConfig.numberCountDuration,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: summary.netBalance > 0
                            ? Colors.green
                            : (summary.netBalance < 0
                                  ? colorScheme.error
                                  : null),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    l10n.groupsSummary(
                      summary.groupCount,
                      summary.unsettledGroupCount,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final int amount;
  final int maxAmount;
  final int barAmount;
  final Color color;
  final MoneyFormatter formatMoney;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.barAmount,
    required this.color,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: AppTheme.space4),
        RollingNumberText(
          value: amount,
          formatFn: formatMoney,
          duration: AnimationConfig.numberCountDuration,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: AppTheme.space4),
        BalanceProgressBar(
          amount: barAmount,
          maxAmount: maxAmount,
          currencyCode: 'USD',
          formatMoney: formatMoney,
          showLabel: false,
          height: 4,
        ),
      ],
    );
  }
}

class _DashboardCardSkeleton extends StatelessWidget {
  const _DashboardCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skeletonColor = theme.colorScheme.surfaceContainerHighest;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: skeletonColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Icon(Icons.refresh, size: 20, color: Colors.transparent),
              ],
            ),
            const SizedBox(height: AppTheme.space16),
            const Row(
              children: [
                Expanded(child: _SkeletonBox(height: 48)),
                SizedBox(width: AppTheme.space16),
                Expanded(child: _SkeletonBox(height: 48)),
              ],
            ),
            const Divider(height: AppTheme.space24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SkeletonBox(width: 100, height: 44),
                _SkeletonBox(width: 140, height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;

  const _SkeletonBox({this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _DashboardCardError extends StatelessWidget {
  final VoidCallback onRetry;

  const _DashboardCardError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 32),
            const SizedBox(height: AppTheme.space8),
            Text(
              l10n.errorLoadingGroups('Failed to load dashboard'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.space16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
