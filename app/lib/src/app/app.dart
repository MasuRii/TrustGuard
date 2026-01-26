import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/theme/app_theme.dart';
import '../features/settings/providers/lock_providers.dart';
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
    // Initialize lock state after first frame
    Future.microtask(() => ref.read(appLockStateProvider.notifier).init());
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
