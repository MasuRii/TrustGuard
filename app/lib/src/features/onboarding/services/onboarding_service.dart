import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_state.dart';

class OnboardingService {
  final SharedPreferences _prefs;
  static const String _keyOnboardingComplete = 'onboarding_complete';
  static const String _keyOnboardingCompletedAt = 'onboarding_completed_at';

  OnboardingService(this._prefs);

  OnboardingState getOnboardingState() {
    final isComplete = _prefs.getBool(_keyOnboardingComplete) ?? false;
    final completedAtStr = _prefs.getString(_keyOnboardingCompletedAt);
    final completedAt = completedAtStr != null
        ? DateTime.parse(completedAtStr)
        : null;

    return OnboardingState(isComplete: isComplete, completedAt: completedAt);
  }

  Future<void> markOnboardingComplete() async {
    final now = DateTime.now();
    await _prefs.setBool(_keyOnboardingComplete, true);
    await _prefs.setString(_keyOnboardingCompletedAt, now.toIso8601String());
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_keyOnboardingComplete);
    await _prefs.remove(_keyOnboardingCompletedAt);
  }
}
