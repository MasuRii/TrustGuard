import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers.dart';
import '../../../core/models/reminder_settings.dart';
import '../../../ui/theme/app_theme.dart';
import 'groups_providers.dart';

class GroupOverviewScreen extends ConsumerWidget {
  final String groupId;

  const GroupOverviewScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupStreamProvider(groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: Center(child: Text('Group not found')));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/group/${group.id}/edit'),
                tooltip: 'Edit Group',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(context, group),
                const SizedBox(height: AppTheme.space24),
                _buildSectionHeader(
                  context,
                  title: 'Members',
                  actionLabel: 'Manage',
                  onActionPressed: () =>
                      context.push('/group/${group.id}/members'),
                ),
                const SizedBox(height: AppTheme.space8),
                _buildMembersPlaceholder(context),
                const SizedBox(height: AppTheme.space24),
                _buildSectionHeader(
                  context,
                  title: 'Reminders',
                  actionLabel: 'Settings',
                  onActionPressed: () =>
                      context.push('/group/${group.id}/reminders'),
                ),
                const SizedBox(height: AppTheme.space8),
                _buildReminderStatus(context, ref),
                const SizedBox(height: AppTheme.space24),
                _buildSectionHeader(context, title: 'Quick Actions'),
                const SizedBox(height: AppTheme.space16),
                _buildQuickActions(context, group),
              ],
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildSummaryCard(BuildContext context, dynamic group) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.group,
                size: 30,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Group Balance',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    'Settled',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    'Currency: ${group.currencyCode}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (actionLabel != null && onActionPressed != null)
          TextButton(onPressed: onActionPressed, child: Text(actionLabel)),
      ],
    );
  }

  Widget _buildMembersPlaceholder(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: [
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: AppTheme.space8),
            const Text('Member balances will appear here'),
            TextButton(
              onPressed: () => context.push('/group/$groupId/members'),
              child: const Text('Add Members'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderStatus(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(reminderSettingsProvider(groupId));

    return settingsAsync.when(
      data: (settings) {
        final isEnabled = settings?.enabled ?? false;
        final schedule = settings?.schedule ?? ReminderSchedule.daily;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ListTile(
            leading: Icon(
              isEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            title: Text(isEnabled ? 'Reminders Enabled' : 'Reminders Disabled'),
            subtitle: isEnabled
                ? Text(
                    'Schedule: ${schedule.name[0].toUpperCase()}${schedule.name.substring(1)}',
                  )
                : const Text('Turn on to receive notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/group/$groupId/reminders'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic group) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.space16,
      crossAxisSpacing: AppTheme.space16,
      childAspectRatio: 2.5,
      children: [
        _buildActionCard(
          context,
          icon: Icons.add_shopping_cart,
          label: 'Add Expense',
          onTap: () =>
              context.push('/group/${group.id}/transactions/add-expense'),
          color: Colors.orange,
        ),
        _buildActionCard(
          context,
          icon: Icons.sync_alt,
          label: 'Add Transfer',
          onTap: () =>
              context.push('/group/${group.id}/transactions/add-transfer'),
          color: Colors.blue,
        ),
        _buildActionCard(
          context,
          icon: Icons.list_alt,
          label: 'Transactions',
          onTap: () => context.push('/group/${group.id}/transactions'),
          color: Colors.purple,
        ),
        _buildActionCard(
          context,
          icon: Icons.account_balance_wallet_outlined,
          label: 'Balances',
          onTap: () => context.push('/group/${group.id}/balances'),
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.space12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppTheme.space12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
