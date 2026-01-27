import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/core/services/undoable_action_service.dart';

void main() {
  late UndoableActionService undoService;

  setUp(() {
    undoService = UndoableActionService();
  });

  tearDown(() {
    undoService.dispose();
  });

  group('UndoableActionService', () {
    test(
      'schedule() creates pending action and executes after delay',
      () async {
        bool executed = false;
        final action = UndoableAction(
          id: 'test-1',
          description: 'Test action',
          executeAction: () async {
            executed = true;
          },
          delay: const Duration(milliseconds: 100),
        );

        undoService.schedule(action);
        expect(executed, false);

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(executed, true);
      },
    );

    test('cancel() prevents action execution and runs undoAction', () async {
      bool executed = false;
      bool undone = false;
      final action = UndoableAction(
        id: 'test-2',
        description: 'Test action',
        executeAction: () async {
          executed = true;
        },
        undoAction: () async {
          undone = true;
        },
        delay: const Duration(milliseconds: 100),
      );

      undoService.schedule(action);
      final success = await undoService.cancel('test-2');

      expect(success, true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executed, false);
      expect(undone, true);
    });

    test('executeNow() runs action immediately and cancels timer', () async {
      int executeCount = 0;
      final action = UndoableAction(
        id: 'test-3',
        description: 'Test action',
        executeAction: () async {
          executeCount++;
        },
        delay: const Duration(milliseconds: 500),
      );

      undoService.schedule(action);
      await undoService.executeNow('test-3');

      expect(executeCount, 1);

      // Wait for original delay to ensure it doesn't execute again
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(executeCount, 1);
    });

    test(
      'scheduling action with same ID executes existing one first',
      () async {
        int executeCount = 0;
        final action1 = UndoableAction(
          id: 'same-id',
          description: 'First action',
          executeAction: () async {
            executeCount++;
          },
          delay: const Duration(seconds: 1),
        );

        final action2 = UndoableAction(
          id: 'same-id',
          description: 'Second action',
          executeAction: () async {
            executeCount += 10;
          },
          delay: const Duration(milliseconds: 100),
        );

        undoService.schedule(action1);
        expect(executeCount, 0);

        undoService.schedule(action2);
        // action1 should have been executed immediately by schedule(action2)
        expect(executeCount, 1);

        await Future<void>.delayed(const Duration(milliseconds: 150));
        expect(executeCount, 11);
      },
    );

    test('dispose() cancels all pending actions', () async {
      bool executed = false;
      final action = UndoableAction(
        id: 'test-dispose',
        description: 'Test action',
        executeAction: () async {
          executed = true;
        },
        delay: const Duration(milliseconds: 100),
      );

      undoService.schedule(action);
      undoService.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(executed, false);
    });
  });
}
