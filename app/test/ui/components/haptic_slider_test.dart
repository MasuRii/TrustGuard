import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/components/haptic_slider.dart';

void main() {
  final List<String> hapticCalls = [];

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    hapticCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            hapticCalls.add(methodCall.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  testWidgets('HapticSlider renders with correct value', (tester) async {
    double value = 50.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HapticSlider(
            value: value,
            onChanged: (newValue) => value = newValue,
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);
    expect(sliderFinder, findsOneWidget);
    expect(tester.widget<Slider>(sliderFinder).value, 50.0);
  });

  testWidgets('HapticSlider calls onChanged and triggers haptics on drag', (
    tester,
  ) async {
    double value = 50.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return HapticSlider(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);

    // Drag from 50 to 80
    await tester.drag(sliderFinder, const Offset(100, 0));
    await tester.pump();

    expect(value, greaterThan(50.0));

    // Should have triggered at least lightImpact (start) and selectionClick (movement)
    // The arguments are like 'HapticFeedbackType.lightImpact'
    expect(hapticCalls, contains('HapticFeedbackType.lightImpact'));
    expect(hapticCalls, contains('HapticFeedbackType.selectionClick'));
  });

  testWidgets('HapticSlider with divisions reflects discrete steps', (
    tester,
  ) async {
    double value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return HapticSlider(
                value: value,
                min: 0.0,
                max: 100.0,
                divisions: 10,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      ),
    );

    final sliderFinder = find.byType(Slider);

    // Drag to roughly 25%
    await tester.drag(sliderFinder, const Offset(50, 0));
    await tester.pump();

    // Since divisions = 10, it should snap to 20 or 30
    expect(value % 10, 0.0);
    expect(hapticCalls, contains('HapticFeedbackType.selectionClick'));
  });
}
