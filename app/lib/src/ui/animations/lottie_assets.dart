class LottieAssets {
  static const String onboarding1 = 'assets/animations/onboarding_offline.json';
  static const String onboarding2 = 'assets/animations/onboarding_privacy.json';
  static const String onboarding3 = 'assets/animations/onboarding_split.json';
  static const String emptyList = 'assets/animations/empty_list.json';
  static const String emptyGroups = 'assets/animations/empty_groups.json';
  static const String success = 'assets/animations/success.json';

  /// Helper method to check if an asset path exists in our definitions.
  static bool exists(String path) {
    return [
      onboarding1,
      onboarding2,
      onboarding3,
      emptyList,
      emptyGroups,
      success,
    ].contains(path);
  }
}
