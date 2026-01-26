import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:drift/native.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/settings/providers/lock_providers.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';
import 'package:trustguard/src/core/database/database.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;

  setUp(() {
    mockService = MockAppLockService();
    when(() => mockService.isPinSet()).thenAnswer((_) async => true);
    when(() => mockService.verifyPin(any())).thenAnswer((_) async => false);
  });

  testWidgets('app locks when paused if lockOnBackground is enabled', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockServiceProvider.overrideWithValue(mockService),
          databaseProvider.overrideWithValue(db),
        ],
        child: const TrustGuardApp(),
      ),
    );

    // Wait for initialization and redirection
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter PIN'), findsOneWidget);

    // Unlock
    when(() => mockService.verifyPin('1234')).thenAnswer((_) async => true);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter PIN'), findsNothing);

    // Simulate background
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Simulate foreground
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter PIN'), findsOneWidget);

    await db.close();
    await tester.pump(Duration.zero);
  });

  testWidgets('app does not lock when paused if lockOnBackground is disabled', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appLockServiceProvider.overrideWithValue(mockService),
          databaseProvider.overrideWithValue(db),
        ],
        child: const TrustGuardApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Disable lock on background
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrustGuardApp)),
    );
    container.read(appLockStateProvider.notifier).setLockOnBackground(false);

    // Unlock
    when(() => mockService.verifyPin('1234')).thenAnswer((_) async => true);
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter PIN'), findsNothing);

    // Simulate background
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Simulate foreground
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Enter PIN'), findsNothing);

    // Simulate background
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // Simulate foreground
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Enter PIN'), findsNothing);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
