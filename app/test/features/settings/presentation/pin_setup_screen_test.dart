import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/features/settings/presentation/pin_setup_screen.dart';
import 'package:trustguard/src/core/platform/app_lock_service.dart';

class MockAppLockService extends Mock implements AppLockService {}

void main() {
  late MockAppLockService mockService;

  setUp(() {
    mockService = MockAppLockService();
    when(() => mockService.setPin(any())).thenAnswer((_) async {});
    when(() => mockService.isPinSet()).thenAnswer((_) async => false);
    when(() => mockService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(
      () => mockService.isRequireUnlockToExportEnabled(),
    ).thenAnswer((_) async => false);
  });

  Widget createTestWidget(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PinSetupScreen(),
                  ),
                ),
                child: const Text('Push'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('renders pin setup screen correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(find.text('Set PIN'), findsOneWidget);
    expect(find.text('Enter a new 4-digit PIN'), findsOneWidget);
  });

  testWidgets('completing pin setup saves pin', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    // Enter first PIN
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm PIN'), findsOneWidget);
    expect(find.text('Re-enter your PIN'), findsOneWidget);

    // Enter matching second PIN
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    verify(() => mockService.setPin('1234')).called(1);
    expect(find.text('PIN set successfully'), findsOneWidget);
    expect(find.text('Push'), findsOneWidget); // Verified we popped back
  });

  testWidgets('mismatching pins show error and reset', (tester) async {
    final container = ProviderContainer(
      overrides: [appLockServiceProvider.overrideWithValue(mockService)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(createTestWidget(container));
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    // Enter first PIN
    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    // Enter mismatching second PIN
    await tester.tap(find.text('4'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('PINs do not match. Try again.'), findsOneWidget);
    expect(find.text('Set PIN'), findsOneWidget);
  });
}
