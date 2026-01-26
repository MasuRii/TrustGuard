import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder_settings.freezed.dart';
part 'reminder_settings.g.dart';

enum ReminderSchedule { daily, weekly, monthly }

@freezed
class ReminderSettings with _$ReminderSettings {
  const factory ReminderSettings({
    required String groupId,
    required bool enabled,
    required ReminderSchedule schedule,
    DateTime? lastNotifiedAt,
  }) = _ReminderSettings;

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      _$ReminderSettingsFromJson(json);
}
