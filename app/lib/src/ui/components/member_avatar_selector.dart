import 'package:flutter/material.dart';
import '../../core/utils/haptics.dart';
import '../../app/app.dart';
import '../../core/models/member.dart';
import '../theme/app_theme.dart';

class MemberAvatarSelector extends StatelessWidget {
  final List<Member> members;
  final Set<String> selectedIds;
  final void Function(Set<String>) onSelectionChanged;
  final bool allowMultiple;
  final String? label;

  const MemberAvatarSelector({
    super.key,
    required this.members,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.allowMultiple = false,
    this.label,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  void _handleTap(String memberId) {
    HapticsService.selection();
    if (allowMultiple) {
      final newSelection = Set<String>.from(selectedIds);
      if (newSelection.contains(memberId)) {
        newSelection.remove(memberId);
      } else {
        newSelection.add(memberId);
      }
      onSelectionChanged(newSelection);
    } else {
      onSelectionChanged({memberId});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Text(
              label!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space8),
        ],
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            scrollDirection: Axis.horizontal,
            itemCount: members.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppTheme.space12),
            itemBuilder: (context, index) {
              final member = members[index];
              final isSelected = selectedIds.contains(member.id);

              return Semantics(
                label: member.displayName,
                selected: isSelected,
                button: true,
                hint: isSelected
                    ? 'Double tap to deselect'
                    : 'Double tap to select',
                child: Tooltip(
                  message: member.displayName,
                  child: GestureDetector(
                    onTap: () => _handleTap(member.id),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isSelected)
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              child: Text(
                                _getInitials(member.displayName),
                                style: TextStyle(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (isSelected && allowMultiple)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.space4),
                        SizedBox(
                          width: 60,
                          child: Text(
                            member.displayName,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (allowMultiple) ...[
          const SizedBox(height: AppTheme.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
            child: Row(
              children: [
                TextButton(
                  onPressed: () =>
                      onSelectionChanged(members.map((m) => m.id).toSet()),
                  child: Text(context.l10n.selectAll),
                ),
                TextButton(
                  onPressed: () => onSelectionChanged({}),
                  child: Text(context.l10n.selectNone),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
