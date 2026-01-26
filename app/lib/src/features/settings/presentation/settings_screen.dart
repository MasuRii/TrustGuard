import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/lock_providers.dart';
import '../providers/notification_providers.dart';
import 'debug_logs_screen.dart';
import '../../../app/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _developerTapCount = 0;
  bool _developerMode = false;

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockStateProvider);
    final notificationsEnabled = ref.watch(notificationPermissionProvider);
    final rounding = ref.watch(roundingProvider);
    final logsAsync = ref.watch(debugLogsProvider);
    final hasLogs = logsAsync.valueOrNull?.isNotEmpty ?? false;
    final storageUsageAsync = ref.watch(attachmentStorageUsageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Display'),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: const Text('Rounding'),
            subtitle: Text('$rounding decimal places'),
            trailing: DropdownButton<int>(
              value: rounding,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('0')),
                DropdownMenuItem(value: 1, child: Text('1')),
                DropdownMenuItem(value: 2, child: Text('2')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(roundingProvider.notifier).setRounding(value);
                }
              },
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, 'Security'),
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(lockState.hasPin ? 'Change PIN' : 'Set PIN'),
            subtitle: Text(
              lockState.hasPin ? 'PIN is active' : 'PIN is not set',
            ),
            onTap: () => context.push('/settings/pin-setup'),
          ),
          if (lockState.hasPin) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Use fingerprint or face ID'),
              value: lockState.isBiometricEnabled,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setBiometricEnabled(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: const Text('Lock on Background'),
              subtitle: const Text('Lock app when minimized'),
              value: lockState.lockOnBackground,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setLockOnBackground(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              title: const Text('Export Protection'),
              subtitle: const Text('Require unlock to export data'),
              value: lockState.requireUnlockToExport,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setRequireUnlockToExport(value),
            ),
            ListTile(
              leading: const Icon(Icons.no_encryption_gmailerrorred_outlined),
              title: const Text('Remove PIN'),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () => _showRemovePinDialog(context, ref),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Enable Reminders'),
            subtitle: const Text('Get notified about unsettled balances'),
            value: notificationsEnabled,
            onChanged: (value) async {
              if (value) {
                final granted = await ref
                    .read(notificationPermissionProvider.notifier)
                    .requestPermission();
                if (!granted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Notification permission denied. Please enable in settings.',
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Notifications can only be disabled in system settings.',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(),
          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Attachment Storage'),
            subtitle: storageUsageAsync.when(
              data: (size) =>
                  Text('${(size / 1024 / 1024).toStringAsFixed(2)} MB used'),
              loading: () => const Text('Calculating...'),
              error: (_, s) => const Text('Error calculating usage'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: () =>
                  _showClearOrphanedAttachmentsDialog(context, ref),
              tooltip: 'Clear Orphaned',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('Backup & Restore'),
            onTap: () => context.push('/settings/backup'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Privacy'),
            subtitle: const Text('User guide and privacy policy'),
            onTap: () => context.push('/settings/help'),
          ),
          const Divider(),
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('TrustGuard'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              if (!_developerMode) {
                setState(() {
                  _developerTapCount++;
                  if (_developerTapCount >= 5) {
                    _developerMode = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Developer mode enabled')),
                    );
                  }
                });
              }
            },
          ),
          if (_developerMode || hasLogs) ...[
            const Divider(),
            _buildSectionHeader(context, 'Developer'),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Debug Logs'),
              onTap: () => context.push('/settings/debug-logs'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showRemovePinDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'This will disable app lock. Your data will no longer be protected by a PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(appLockServiceProvider).removePin();
      await ref.read(appLockStateProvider.notifier).init();
    }
  }

  Future<void> _showClearOrphanedAttachmentsDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Orphaned Attachments?'),
        content: const Text(
          'This will delete photos linked to transactions that no longer exist or were permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final transactions = await ref
          .read(transactionRepositoryProvider)
          .getAllTransactions();
      final activeTxIds = transactions.map((t) => t.id).toList();
      await ref
          .read(attachmentServiceProvider)
          .clearOrphanedAttachments(activeTxIds);
      ref.invalidate(attachmentStorageUsageProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orphaned attachments cleared')),
        );
      }
    }
  }
}
