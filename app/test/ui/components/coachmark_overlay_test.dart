import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/coachmark_overlay.dart';

void main() {
  group('CoachmarkOverlay Tests', () {
    testWidgets('CoachmarkOverlay renders message and "Got it" button', (
      tester,
    ) async {
      final targetKey = GlobalKey();
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: 100,
                  child: Container(
                    key: targetKey,
                    width: 50,
                    height: 50,
                    color: Colors.blue,
                  ),
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        CoachmarkOverlay.show(
                          context: context,
                          targetKey: targetKey,
                          message: 'Test coachmark message',
                          onDismiss: () => dismissed = true,
                        );
                      },
                      child: const Text('Show'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump(); // Show overlay

      expect(find.text('Test coachmark message'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pump(); // Remove overlay

      expect(find.text('Test coachmark message'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('Tapping backdrop dismisses overlay', (tester) async {
      final targetKey = GlobalKey();
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 100,
                  left: 100,
                  child: SizedBox(key: targetKey, width: 50, height: 50),
                ),
                Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        CoachmarkOverlay.show(
                          context: context,
                          targetKey: targetKey,
                          message: 'Test message',
                          onDismiss: () => dismissed = true,
                        );
                      },
                      child: const Text('Show'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      // Tap on the backdrop (should be the ColorFiltered widget)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();

      expect(find.text('Test message'), findsNothing);
      expect(dismissed, isTrue);
    });

    testWidgets('CoachmarkOverlay handles missing target gracefully', (
      tester,
    ) async {
      final targetKey = GlobalKey(); // Not attached to any widget
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CoachmarkOverlay.show(
                      context: context,
                      targetKey: targetKey,
                      message: 'Test message',
                      onDismiss: () => dismissed = true,
                    );
                  },
                  child: const Text('Show'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester
          .pump(); // It should show then immediately call onDismiss in post frame

      // We need to pump another frame to let the postFrameCallback execute
      await tester.pump(Duration.zero);

      expect(dismissed, isTrue);
    });

    testWidgets(
      'CoachmarkOverlay positions tooltip at bottom when target is at top',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final targetKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 50,
                    left: 100,
                    child: SizedBox(key: targetKey, width: 50, height: 50),
                  ),
                  Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          CoachmarkOverlay.show(
                            context: context,
                            targetKey: targetKey,
                            message: 'Message',
                            onDismiss: () {},
                          );
                        },
                        child: const Text('Show'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final positionedTooltip = tester.widget<Positioned>(
          find
              .ancestor(
                of: find.text('Message'),
                matching: find.byType(Positioned),
              )
              .first,
        );
        expect(
          positionedTooltip.top,
          isNotNull,
          reason: 'Tooltip should be below target (top set)',
        );
        expect(positionedTooltip.bottom, isNull);
        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'CoachmarkOverlay positions tooltip correctly when position is explicit',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final targetKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(
                    child: SizedBox(key: targetKey, width: 50, height: 50),
                  ),
                  Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          CoachmarkOverlay.show(
                            context: context,
                            targetKey: targetKey,
                            message: 'Message Explicit',
                            position: CoachmarkPosition.top,
                            onDismiss: () {},
                          );
                        },
                        child: const Text('Show'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final positionedTooltip = tester.widget<Positioned>(
          find
              .ancestor(
                of: find.text('Message Explicit'),
                matching: find.byType(Positioned),
              )
              .first,
        );

        expect(
          positionedTooltip.bottom,
          isNotNull,
          reason: 'Explicit top position should set bottom property',
        );
        expect(positionedTooltip.top, isNull);

        await tester.binding.setSurfaceSize(null);
      },
    );

    testWidgets(
      'CoachmarkOverlay positions tooltip at top when target is at bottom',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 600));
        final targetKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 500, // Target at bottom area
                    left: 100,
                    child: SizedBox(key: targetKey, width: 50, height: 50),
                  ),
                  Builder(
                    builder: (context) {
                      return ElevatedButton(
                        onPressed: () {
                          CoachmarkOverlay.show(
                            context: context,
                            targetKey: targetKey,
                            message: 'Message Top',
                            onDismiss: () {},
                          );
                        },
                        child: const Text('Show'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pump();

        final positionedTooltip = tester.widget<Positioned>(
          find
              .ancestor(
                of: find.text('Message Top'),
                matching: find.byType(Positioned),
              )
              .first,
        );

        expect(
          positionedTooltip.bottom,
          isNotNull,
          reason: 'Tooltip should have bottom set (placed above target)',
        );
        expect(positionedTooltip.top, isNull);

        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
