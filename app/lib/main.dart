import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app/app.dart';
import 'src/app/providers.dart';
import 'src/core/platform/local_log_service.dart';
import 'src/features/budget/services/budget_alert_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );

      final logService = LocalLogService();
      await logService.init();
      await logService.info('App started');

      // Initialize notifications
      await container.read(notificationServiceProvider).init();

      // Initialize recurrence check on startup
      await container
          .read(recurrenceServiceProvider)
          .checkAndCreateDueTransactions();

      // Check budget alerts on startup
      await container.read(budgetAlertServiceProvider).checkAllBudgets();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        logService.fatal(
          'Flutter error',
          error: details.exception,
          stackTrace: details.stack,
          context: {
            'library': details.library,
            'context': details.context?.toString(),
          },
        );
      };

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const TrustGuardApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      LocalLogService().error(
        'Uncaught zoned error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}
