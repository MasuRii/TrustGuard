import 'package:flutter_test/flutter_test.dart';
import 'package:trustguard/src/ui/animations/lottie_assets.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LottieAssets Tests', () {
    test('LottieAssets constants are defined correctly', () {
      expect(
        LottieAssets.onboarding1,
        'assets/animations/onboarding_offline.json',
      );
      expect(
        LottieAssets.onboarding2,
        'assets/animations/onboarding_privacy.json',
      );
      expect(
        LottieAssets.onboarding3,
        'assets/animations/onboarding_split.json',
      );
      expect(LottieAssets.emptyList, 'assets/animations/empty_list.json');
      expect(LottieAssets.emptyGroups, 'assets/animations/empty_groups.json');
      expect(LottieAssets.success, 'assets/animations/success.json');
    });

    test('LottieAssets.exists returns true for defined paths', () {
      expect(LottieAssets.exists(LottieAssets.onboarding1), isTrue);
      expect(LottieAssets.exists(LottieAssets.emptyList), isTrue);
      expect(LottieAssets.exists('assets/animations/invalid.json'), isFalse);
    });

    test('Lottie asset files exist and are valid JSON', () {
      final assets = [
        LottieAssets.onboarding1,
        LottieAssets.onboarding2,
        LottieAssets.onboarding3,
        LottieAssets.emptyList,
        LottieAssets.emptyGroups,
        LottieAssets.success,
      ];

      for (final asset in assets) {
        // In a real Flutter test, we'd use rootBundle.loadString(asset)
        // But since we are running in a local environment, we can check the file system directly.
        final file = File(asset);
        expect(file.existsSync(), isTrue, reason: 'File $asset should exist');

        final content = file.readAsStringSync();
        expect(
          json.decode(content),
          isA<Map<String, dynamic>>(),
          reason: 'File $asset should be valid JSON',
        );
      }
    });
  });
}
