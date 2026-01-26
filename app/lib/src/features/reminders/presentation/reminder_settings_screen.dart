import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/models/reminder_settings.dart';
import '../../../ui/theme/app_theme.dart';
import '../services/reminder_service.dart';

class ReminderSettingsScreen extends ConsumerWidget {
  final String groupId;

  const ReminderSettingsScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(reminderSettingsProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Settings')),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsList(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    ReminderSettings? settings,
  ) {
    final isEnabled = settings?.enabled ?? false;
    final schedule = settings?.schedule ?? ReminderSchedule.daily;

    return ListView(
      padding: const EdgeInsets.all(AppTheme.space16),
      children: [
        SwitchListTile(
          title: const Text('Enable Reminders'),
          subtitle: const Text(
            'Receive notifications for outstanding balances',
          ),
          value: isEnabled,
          onChanged: (value) => _updateSettings(ref, settings, enabled: value),
        ),
        if (isEnabled) ...[
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space8,
            ),
            child: Text(
              'Schedule',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<ReminderSchedule>(
            title: const Text('Daily'),
            value: ReminderSchedule.daily,
            // ignore: deprecated_member_use
            groupValue: schedule,
            // ignore: deprecated_member_use
            onChanged: (value) =>
                _updateSettings(ref, settings, schedule: value),
          ),
          RadioListTile<ReminderSchedule>(
            title: const Text('Weekly'),
            value: ReminderSchedule.weekly,
            // ignore: deprecated_member_use
            groupValue: schedule,
            // ignore: deprecated_member_use
            onChanged: (value) =>
                _updateSettings(ref, settings, schedule: value),
          ),
          RadioListTile<ReminderSchedule>(
            title: const Text('Monthly'),
            value: ReminderSchedule.monthly,
            // ignore: deprecated_member_use
            groupValue: schedule,
            // ignore: deprecated_member_use
            onChanged: (value) =>
                _updateSettings(ref, settings, schedule: value),
          ),
        ],
      ],
    );
  }

  Future<void> _updateSettings(
    WidgetRef ref,
    ReminderSettings? currentSettings, {
    bool? enabled,
    ReminderSchedule? schedule,
  }) async {
    final repository = ref.read(reminderRepositoryProvider);
    final settings = ReminderSettings(
      groupId: groupId,
      enabled: enabled ?? currentSettings?.enabled ?? false,
      schedule: schedule ?? currentSettings?.schedule ?? ReminderSchedule.daily,
      lastNotifiedAt: currentSettings?.lastNotifiedAt,
    );

    await repository.upsertReminderSettings(settings);

    if (enabled == true) {
      final notificationService = ref.read(notificationServiceProvider);
      final hasPermission = await notificationService.isPermissionGranted();
      if (!hasPermission) {
        await notificationService.requestPermissions();
      }
    }

    // Refresh scheduled notification
    final reminderService = ref.read(reminderServiceProvider);
    await reminderService.refreshReminderForGroup(groupId);
  }
}
