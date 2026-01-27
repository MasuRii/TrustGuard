import 'package:shared_preferences/shared_preferences.dart';

enum CoachmarkKey {
  transactionSwipeHint,
  receiptScanHint,
  quickAddHint,
  filterHint,
  speedDialHint,
}

class CoachmarkService {
  final SharedPreferences _prefs;
  final Set<CoachmarkKey> _shownCoachmarks = {};

  CoachmarkService(this._prefs) {
    _load();
  }

  void _load() {
    final shown = _prefs.getStringList('coachmarks_shown') ?? [];
    for (final name in shown) {
      try {
        final key = CoachmarkKey.values.firstWhere((e) => e.name == name);
        _shownCoachmarks.add(key);
      } catch (_) {
        // Ignore invalid keys from previous versions
      }
    }
  }

  bool shouldShow(CoachmarkKey key) {
    return !_shownCoachmarks.contains(key);
  }

  Future<void> markShown(CoachmarkKey key) async {
    if (_shownCoachmarks.add(key)) {
      await _prefs.setStringList(
        'coachmarks_shown',
        _shownCoachmarks.map((e) => e.name).toList(),
      );
    }
  }

  Future<void> reset() async {
    _shownCoachmarks.clear();
    await _prefs.remove('coachmarks_shown');
  }
}
