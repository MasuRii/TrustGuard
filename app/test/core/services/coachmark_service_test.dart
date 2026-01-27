import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustguard/src/core/services/coachmark_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late CoachmarkService coachmarkService;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getStringList('coachmarks_shown')).thenReturn([]);
    coachmarkService = CoachmarkService(mockPrefs);
  });

  group('CoachmarkService', () {
    test('shouldShow returns true for unseen coachmarks', () {
      expect(
        coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint),
        true,
      );
    });

    test(
      'markShown persists to SharedPreferences and updates shouldShow',
      () async {
        when(
          () => mockPrefs.setStringList(any(), any()),
        ).thenAnswer((_) async => true);

        await coachmarkService.markShown(CoachmarkKey.transactionSwipeHint);

        verify(
          () => mockPrefs.setStringList('coachmarks_shown', [
            'transactionSwipeHint',
          ]),
        ).called(1);
        expect(
          coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint),
          false,
        );
      },
    );

    test('shouldShow returns false after markShown', () async {
      when(
        () => mockPrefs.setStringList(any(), any()),
      ).thenAnswer((_) async => true);
      await coachmarkService.markShown(CoachmarkKey.transactionSwipeHint);
      expect(
        coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint),
        false,
      );
    });

    test('load restores shown coachmarks from SharedPreferences', () {
      when(
        () => mockPrefs.getStringList('coachmarks_shown'),
      ).thenReturn(['transactionSwipeHint', 'receiptScanHint']);
      coachmarkService = CoachmarkService(mockPrefs);

      expect(
        coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint),
        false,
      );
      expect(coachmarkService.shouldShow(CoachmarkKey.receiptScanHint), false);
      expect(coachmarkService.shouldShow(CoachmarkKey.quickAddHint), true);
    });

    test('reset clears all coachmarks', () async {
      when(
        () => mockPrefs.getStringList('coachmarks_shown'),
      ).thenReturn(['transactionSwipeHint']);
      when(
        () => mockPrefs.remove('coachmarks_shown'),
      ).thenAnswer((_) async => true);
      coachmarkService = CoachmarkService(mockPrefs);

      await coachmarkService.reset();

      verify(() => mockPrefs.remove('coachmarks_shown')).called(1);
      expect(
        coachmarkService.shouldShow(CoachmarkKey.transactionSwipeHint),
        true,
      );
    });
  });
}
