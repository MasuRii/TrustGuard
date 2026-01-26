import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app/app.dart';

class DateGroupHeader extends StatelessWidget {
  final DateTime date;

  const DateGroupHeader({super.key, required this.date});

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
