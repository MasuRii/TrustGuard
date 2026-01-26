import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/settings/presentation/lock_screen.dart';
import 'package:trustguard/src/features/settings/providers/lock_providers.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;

  setUp(() {
    mockService = MockAppLockService();
    when(() => mockService.isPinSet()).thenAnswer((_) async => true);
    when(() => mockService.verifyPin(any())).thenAnswer((_) async => false);
  });

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LockScreen()),
    );
  }

  testWidgets('renders lock screen correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    expect(find.text('Enter PIN'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    for (var i = 0; i <= 9; i++) {
      expect(find.text(i.toString()), findsOneWidget);
    }
  });

  testWidgets('entering correct PIN unlocks', (tester) async {
    when(() => mockService.verifyPin('1234')).thenAnswer((_) async => true);

    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));

    // Initialize lock state
    await container.read(appLockStateProvider.notifier).init();
    await tester.pump();

    expect(container.read(appLockStateProvider).isLocked, true);

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    verify(() => mockService.verifyPin('1234')).called(1);
    expect(container.read(appLockStateProvider).isLocked, false);
  });

  testWidgets('entering incorrect PIN shows error and counts attempts', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));

    await container.read(appLockStateProvider.notifier).init();
    await tester.pump();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Incorrect PIN'), findsOneWidget);
    expect(container.read(appLockStateProvider).failedAttempts, 1);
  });

  testWidgets('blocks after 5 failed attempts', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));

    await container.read(appLockStateProvider.notifier).init();
    await tester.pump();

    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('1'));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('1'));
      await tester.tap(find.text('1'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('Too many attempts'), findsOneWidget);
    expect(container.read(appLockStateProvider).isBlocked, true);
    expect(find.text('Blocked'), findsOneWidget);
  });
}
