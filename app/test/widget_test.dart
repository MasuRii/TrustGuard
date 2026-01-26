import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/app.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Use an in-memory database for testing
    final db = AppDatabase(NativeDatabase.memory());
    final mockNotificationService = MockNotificationService();
    when(() => mockNotificationService.init()).thenAnswer((_) async {});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            mockNotificationService,
          ),
        ],
        child: const TrustGuardApp(),
      ),
    );

    // Initial pump to build the widget tree
    await tester.pump();
    // Pump again to let the StreamProvider emit data
    await tester.pump(Duration.zero);

    // Verify that we are on the Home screen.
    expect(find.text('TrustGuard'), findsWidgets);
    expect(find.text('No groups yet'), findsOneWidget);

    await db.close();
  });
}
