import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app/app.dart';
import 'src/app/providers.dart';
import 'src/core/platform/local_log_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();

      final logService = LocalLogService();
      await logService.init();
      await logService.info('App started');

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
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
