import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../generated/app_localizations.dart';
import '../../../app/providers.dart';
import '../../../core/models/group.dart';
import '../../../core/models/reminder_settings.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/components/speed_dial_fab.dart';
import '../../templates/presentation/template_picker_sheet.dart';
import '../../transactions/presentation/quick_add_expense_sheet.dart';
import '../../budget/presentation/budget_list_tab.dart';
import 'groups_providers.dart';

class GroupOverviewScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupOverviewScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupOverviewScreen> createState() =>
      _GroupOverviewScreenState();
}

class _GroupOverviewScreenState extends ConsumerState<GroupOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showQuickAdd(BuildContext context, Group group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => QuickAddExpenseSheet(
        groupId: group.id,
        onSuccess: () {
          // Providers will refresh automatically due to StreamProvider
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupStreamProvider(widget.groupId));

    return groupAsync.when(
      data: (group) {
        if (group == null) {
          return const Scaffold(body: Center(child: Text('Group not found')));
        }

        final l10n = AppLocalizations.of(context)!;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: () => context.push('/group/${group.id}/scan'),
                tooltip: 'Scan QR Code',
                constraints: const BoxConstraints(
                  minWidth: AppTheme.minTouchTarget,
                  minHeight: AppTheme.minTouchTarget,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/group/${group.id}/edit'),
                tooltip: 'Edit Group',
                constraints: const BoxConstraints(
                  minWidth: AppTheme.minTouchTarget,
                  minHeight: AppTheme.minTouchTarget,
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Budgets'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(group: group),
              BudgetListTab(groupId: group.id),
            ],
          ),
          floatingActionButton: _buildFab(context, group, l10n),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: $error'))),
    );
  }

  Widget _buildFab(BuildContext context, Group group, AppLocalizations l10n) {
    if (_tabController.index == 1) {
      return FloatingActionButton.extended(
        onPressed: () => context.push('/group/${group.id}/budget-settings'),
        icon: const Icon(Icons.add),
        label: const Text('Create Budget'),
      );
    }

    return SpeedDialFab(
      items: [
        SpeedDialItem(
          icon: Icons.bolt,
          label: l10n.quickAdd,
          onPressed: () => _showQuickAdd(context, group),
        ),
        SpeedDialItem(
          icon: Icons.file_copy_outlined,
          label: 'From Template',
          onPressed: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (context) => TemplatePickerSheet(
                groupId: group.id,
                onSelected: (template) {
                  context.push(
                    '/group/${group.id}/transactions/add-expense',
                    extra: template,
                  );
                },
              ),
            );
          },
        ),
        SpeedDialItem(
          icon: Icons.receipt_long_outlined,
          label: l10n.addExpense,
          onPressed: () =>
              context.push('/group/${group.id}/transactions/add-expense'),
        ),
        SpeedDialItem(
          icon: Icons.swap_horiz,
          label: l10n.addTransfer,
          onPressed: () =>
              context.push('/group/${group.id}/transactions/add-transfer'),
        ),
        SpeedDialItem(
          icon: Icons.qr_code_scanner,
          label: 'Scan QR Code',
          onPressed: () => context.push('/group/${group.id}/scan'),
        ),
        SpeedDialItem(
          icon: Icons.document_scanner_outlined,
          label: l10n.scanReceipt,
          onPressed: () => context.push(
            '/group/${group.id}/transactions/add-expense?scan=true',
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  final Group group;

  const _OverviewTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
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
            onActionPressed: () => context.push('/group/${group.id}/members'),
          ),
          const SizedBox(height: AppTheme.space8),
          _buildMembersPlaceholder(context),
          const SizedBox(height: AppTheme.space24),
          _buildSectionHeader(
            context,
            title: 'Reminders',
            actionLabel: 'Settings',
            onActionPressed: () => context.push('/group/${group.id}/reminders'),
          ),
          const SizedBox(height: AppTheme.space8),
          _buildReminderStatus(context, ref),
          const SizedBox(height: AppTheme.space24),
          _buildSectionHeader(context, title: 'Quick Actions'),
          const SizedBox(height: AppTheme.space16),
          _buildQuickActions(context, group),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Group group) {
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
              onPressed: () => context.push('/group/${group.id}/members'),
              child: const Text('Add Members'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderStatus(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(reminderSettingsProvider(group.id));

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
            onTap: () => context.push('/group/${group.id}/reminders'),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildQuickActions(BuildContext context, Group group) {
    final l10n = AppLocalizations.of(context)!;

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
          label: l10n.addExpense,
          onTap: () =>
              context.push('/group/${group.id}/transactions/add-expense'),
          color: Colors.orange,
        ),
        _buildActionCard(
          context,
          icon: Icons.sync_alt,
          label: l10n.addTransfer,
          onTap: () =>
              context.push('/group/${group.id}/transactions/add-transfer'),
          color: Colors.blue,
        ),
        _buildActionCard(
          context,
          icon: Icons.analytics_outlined,
          label: l10n.analyticsTitle,
          onTap: () => context.push('/group/${group.id}/analytics'),
          color: Colors.indigo,
        ),
        _buildActionCard(
          context,
          icon: Icons.list_alt,
          label: l10n.transactionsTitle,
          onTap: () => context.push('/group/${group.id}/transactions'),
          color: Colors.purple,
        ),
        _buildActionCard(
          context,
          icon: Icons.account_balance_wallet_outlined,
          label: l10n.balance,
          onTap: () => context.push('/group/${group.id}/balances'),
          color: Colors.teal,
        ),
        _buildActionCard(
          context,
          icon: Icons.label_outline,
          label: 'Tags',
          onTap: () => context.push('/group/${group.id}/tags'),
          color: Colors.pink,
        ),
        _buildActionCard(
          context,
          icon: Icons.file_download_outlined,
          label: l10n.importData,
          onTap: () => context.push('/group/${group.id}/import'),
          color: Colors.brown,
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
    return Semantics(
      label: 'Quick action: $label',
      button: true,
      child: InkWell(
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
      ),
    );
  }
}
