import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/platform/notification_service.dart';

/// Notifier for notification permission status.
class NotificationPermissionNotifier extends StateNotifier<bool> {
  final NotificationService _service;

  NotificationPermissionNotifier(this._service) : super(false);

  /// Checks and updates the current permission status.
  Future<void> checkPermission() async {
    state = await _service.isPermissionGranted();
  }

  /// Requests notification permission and updates the state.
  Future<bool> requestPermission() async {
    final granted = await _service.requestPermissions();
    state = granted;
    return granted;
  }
}

/// Provider for notification permission status.
final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool>((ref) {
      final service = ref.watch(notificationServiceProvider);
      final notifier = NotificationPermissionNotifier(service);
      // Check permission on initialization
      notifier.checkPermission();
      return notifier;
    });
