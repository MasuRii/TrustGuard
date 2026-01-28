import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app.dart';
import '../../../ui/theme/app_theme.dart';
import '../providers/lock_providers.dart';
import '../providers/notification_providers.dart';
import '../providers/theme_providers.dart';
import '../services/theme_service.dart';
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
    final themeState = ref.watch(themeStateProvider);
    final notificationsEnabled = ref.watch(notificationPermissionProvider);
    final rounding = ref.watch(roundingProvider);
    final useCustomKeypad = ref.watch(customKeypadProvider);
    final logsAsync = ref.watch(debugLogsProvider);
    final hasLogs = logsAsync.valueOrNull?.isNotEmpty ?? false;
    final storageUsageAsync = ref.watch(attachmentStorageUsageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        children: [
          _buildSectionHeader(context, context.l10n.display),
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(context.l10n.rounding),
            subtitle: Text(context.l10n.decimalPlaces(rounding)),
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
          SwitchListTile(
            secondary: const Icon(Icons.apps_outlined),
            title: Text(context.l10n.useCustomKeypad),
            subtitle: Text(context.l10n.useCustomKeypadDesc),
            value: useCustomKeypad,
            onChanged: (value) =>
                ref.read(customKeypadProvider.notifier).setEnabled(value),
          ),
          const Divider(),
          _buildSectionHeader(context, context.l10n.appearanceSection),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(context.l10n.themeTitle),
            subtitle: Text(_getThemeModeName(context, themeState.currentMode)),
            trailing: SegmentedButton<ThemeModePreference>(
              segments: [
                ButtonSegment(
                  value: ThemeModePreference.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  tooltip: context.l10n.themeSystem,
                ),
                ButtonSegment(
                  value: ThemeModePreference.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  tooltip: context.l10n.themeLight,
                ),
                ButtonSegment(
                  value: ThemeModePreference.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  tooltip: context.l10n.themeDark,
                ),
              ],
              selected: {themeState.currentMode},
              onSelectionChanged: (Set<ThemeModePreference> newSelection) {
                ref
                    .read(themeStateProvider.notifier)
                    .setThemeMode(newSelection.first);
              },
              showSelectedIcon: false,
            ),
          ),
          const Divider(),
          _buildSectionHeader(context, context.l10n.security),
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(
              lockState.hasPin ? context.l10n.changePin : context.l10n.setPin,
            ),
            subtitle: Text(
              lockState.hasPin
                  ? context.l10n.pinActive
                  : context.l10n.pinNotSet,
            ),
            onTap: () => context.push('/settings/pin-setup'),
          ),
          if (lockState.hasPin) ...[
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(context.l10n.biometricUnlock),
              subtitle: Text(context.l10n.biometricUnlockDesc),
              value: lockState.isBiometricEnabled,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setBiometricEnabled(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.timer_outlined),
              title: Text(context.l10n.lockOnBackground),
              subtitle: Text(context.l10n.lockOnBackgroundDesc),
              value: lockState.lockOnBackground,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setLockOnBackground(value),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.shield_outlined),
              title: Text(context.l10n.exportProtection),
              subtitle: Text(context.l10n.exportProtectionDesc),
              value: lockState.requireUnlockToExport,
              onChanged: (value) => ref
                  .read(appLockStateProvider.notifier)
                  .setRequireUnlockToExport(value),
            ),
            ListTile(
              leading: const Icon(Icons.no_encryption_gmailerrorred_outlined),
              title: Text(context.l10n.removePin),
              textColor: Theme.of(context).colorScheme.error,
              iconColor: Theme.of(context).colorScheme.error,
              onTap: () => _showRemovePinDialog(context, ref),
            ),
          ],
          const Divider(),
          _buildSectionHeader(context, context.l10n.notifications),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: Text(context.l10n.enableReminders),
            subtitle: Text(context.l10n.remindersDesc),
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
          _buildSectionHeader(context, context.l10n.data),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(context.l10n.attachmentStorage),
            subtitle: storageUsageAsync.when(
              data: (size) => Text(
                context.l10n.mbUsed((size / 1024 / 1024).toStringAsFixed(2)),
              ),
              loading: () => Text(context.l10n.calculating),
              error: (_, s) => const Text('Error calculating usage'),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.cleaning_services_outlined),
              onPressed: () =>
                  _showClearOrphanedAttachmentsDialog(context, ref),
              tooltip: context.l10n.clearOrphaned,
              constraints: const BoxConstraints(
                minWidth: AppTheme.minTouchTarget,
                minHeight: AppTheme.minTouchTarget,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.import_export),
            title: Text(context.l10n.backupRestore),
            onTap: () => context.push('/settings/backup'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(context.l10n.helpPrivacy),
            subtitle: Text(context.l10n.helpPrivacyDesc),
            onTap: () => context.push('/settings/help'),
          ),
          const Divider(),
          _buildSectionHeader(context, context.l10n.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('TrustGuard'),
            subtitle: Text(context.l10n.version('1.0.0')),
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
            _buildSectionHeader(context, context.l10n.developer),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(context.l10n.debugLogs),
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

  String _getThemeModeName(BuildContext context, ThemeModePreference mode) {
    switch (mode) {
      case ThemeModePreference.system:
        return context.l10n.themeSystem;
      case ThemeModePreference.light:
        return context.l10n.themeLight;
      case ThemeModePreference.dark:
        return context.l10n.themeDark;
    }
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
