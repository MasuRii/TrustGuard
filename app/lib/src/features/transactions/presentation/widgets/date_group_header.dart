import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/app.dart';

class DateGroupHeader extends StatelessWidget {
  final DateTime date;
  final bool isStuck;

  const DateGroupHeader({super.key, required this.date, this.isStuck = false});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    String label;
    if (itemDate == today) {
      label = context.l10n.today;
    } else if (itemDate == yesterday) {
      label = context.l10n.yesterday;
    } else if (today.difference(itemDate).inDays < 7 &&
        today.isAfter(itemDate)) {
      label = DateFormat('EEEE, MMM d').format(date);
    } else {
      label = DateFormat('MMMM d, yyyy').format(date);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!isStuck) {
      return Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: isDark
            ? theme.cardColor.withValues(alpha: 0.7)
            : theme.cardColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
