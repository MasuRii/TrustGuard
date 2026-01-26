import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/theme/app_theme.dart';
import '../features/settings/providers/lock_providers.dart';
import '../features/reminders/services/reminder_service.dart';
import 'providers.dart';
import 'router.dart';

class TrustGuardApp extends ConsumerStatefulWidget {
  const TrustGuardApp({super.key});

  @override
  ConsumerState<TrustGuardApp> createState() => _TrustGuardAppState();
}

class _TrustGuardAppState extends ConsumerState<TrustGuardApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize services after first frame
    Future.microtask(() async {
      final notificationService = ref.read(notificationServiceProvider);

      // Set up notification tap handler
      notificationService.onNotificationTap = (groupId) {
        if (groupId != null) {
          final router = ref.read(routerProvider);
          router.go('/group/$groupId');
        }
      };

      await notificationService.init();
      await ref.read(appLockStateProvider.notifier).init();

      // Refresh reminders on app start
      await ref.read(reminderServiceProvider).refreshAllReminders();

      // Check if app was launched from a notification
      final launchDetails = await notificationService.getAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null) {
          final router = ref.read(routerProvider);
          router.go('/group/$payload');
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final lockState = ref.read(appLockStateProvider);
      if (lockState.lockOnBackground) {
        ref.read(appLockStateProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TrustGuard',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
