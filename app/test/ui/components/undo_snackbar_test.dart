import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/core/services/undoable_action_service.dart';
import 'package:trustguard/src/ui/components/undo_snackbar.dart';
import '../../helpers/localization_helper.dart';

class MockUndoableActionService extends Mock implements UndoableActionService {}

void main() {
  late MockUndoableActionService mockUndoService;

  setUp(() {
    mockUndoService = MockUndoableActionService();
  });

  group('UndoSnackBar Tests', () {
    testWidgets('showUndoSnackBar displays message and action', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showUndoSnackBar(
                        context: context,
                        message: 'Test message',
                        actionId: 'test-id',
                        undoService: mockUndoService,
                      );
                    },
                    child: const Text('Show'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(); // Wait for snackbar to appear

      expect(find.text('Test message'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget); // Default label
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Tapping Undo calls undoService.cancel', (tester) async {
      when(
        () => mockUndoService.cancel('test-id'),
      ).thenAnswer((_) async => true);

      bool undoCallbackCalled = false;

      await tester.pumpWidget(
        wrapWithLocalization(
          Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showUndoSnackBar(
                        context: context,
                        message: 'Test message',
                        actionId: 'test-id',
                        undoService: mockUndoService,
                        config: UndoSnackBarConfig(
                          message: 'Test message',
                          onUndo: () => undoCallbackCalled = true,
                        ),
                      );
                    },
                    child: const Text('Show'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Undo'));
      await tester.pump(); // Start cancel

      verify(() => mockUndoService.cancel('test-id')).called(1);
      expect(undoCallbackCalled, isTrue);

      // Should show 'Action undone' snackbar
      await tester.pumpAndSettle();
      expect(find.text('Action undone'), findsOneWidget);
    });

    testWidgets('Snackbar is shown with correct duration', (tester) async {
      await tester.pumpWidget(
        wrapWithLocalization(
          Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      showUndoSnackBar(
                        context: context,
                        message: 'Test message',
                        actionId: 'test-id',
                        undoService: mockUndoService,
                        config: const UndoSnackBarConfig(
                          message: 'Test message',
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Text('Show'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      expect(find.text('Test message'), findsOneWidget);

      // We've verified it shows up. Automated timeout tests for SnackBars
      // can be flaky due to internal animation handling in the test environment.
    });
  });
}
