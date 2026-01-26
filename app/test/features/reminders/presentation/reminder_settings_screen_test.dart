import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/database/database.dart';
import 'package:trustguard/src/core/database/repositories/reminder_repository.dart';
import 'package:trustguard/src/core/models/reminder_settings.dart';
import 'package:trustguard/src/core/platform/notification_service.dart';
import 'package:trustguard/src/features/reminders/presentation/reminder_settings_screen.dart';
import 'package:uuid/uuid.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late AppDatabase db;
  late MockNotificationService mockNotificationService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockNotificationService = MockNotificationService();

    when(
      () => mockNotificationService.isPermissionGranted(),
    ).thenAnswer((_) async => true);
  });

  Future<void> setupGroup(String id) async {
    await db
        .into(db.groups)
        .insert(
          GroupsCompanion.insert(
            id: id,
            name: 'Test Group',
            currencyCode: 'USD',
            createdAt: DateTime.now(),
          ),
        );
  }

  testWidgets('ReminderSettingsScreen allows toggling and schedule selection', (
    WidgetTester tester,
  ) async {
    final groupId = const Uuid().v4();
    await setupGroup(groupId);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationServiceProvider.overrideWithValue(
            mockNotificationService,
          ),
        ],
        child: MaterialApp(home: ReminderSettingsScreen(groupId: groupId)),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);

    // Default state: disabled
    expect(find.text('Enable Reminders'), findsOneWidget);
    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);

    // Toggle on
    await tester.tap(switchFinder);
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(switchFinder).value, isTrue);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);

    // Change to Weekly
    await tester.tap(find.text('Weekly'));
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pumpAndSettle();

    // Verify in database
    final repository = DriftReminderRepository(db);
    final settings = await repository.getReminderSettings(groupId);
    expect(settings?.enabled, isTrue);
    expect(settings?.schedule, ReminderSchedule.weekly);

    await db.close();
    await tester.pump(Duration.zero);
  });
}
