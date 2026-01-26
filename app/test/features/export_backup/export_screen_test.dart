import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/app/providers.dart';
import 'package:trustguard/src/core/models/group.dart';
import 'package:trustguard/src/features/groups/presentation/groups_providers.dart';
import 'package:trustguard/src/features/export_backup/presentation/export_screen.dart';
import 'package:trustguard/src/features/export_backup/services/export_service.dart';
import 'package:trustguard/src/features/transactions/presentation/transactions_providers.dart';
import 'package:trustguard/src/features/settings/providers/lock_providers.dart';

class MockExportService extends Mock implements ExportService {}

class MockAppLockNotifier extends Notifier<AppLockState>
    with Mock
    implements AppLockNotifier {}

void main() {
  late MockExportService mockExportService;

  setUp(() {
    mockExportService = MockExportService();
  });

  Widget createWidget(String groupId) {
    return ProviderScope(
      overrides: [
        exportServiceProvider.overrideWithValue(mockExportService),
        groupStreamProvider(groupId).overrideWith(
          (ref) => Stream.value(
            Group(
              id: groupId,
              name: 'Test Group',
              currencyCode: 'USD',
              createdAt: DateTime.now(),
            ),
          ),
        ),
        transactionsByGroupProvider(
          groupId,
        ).overrideWith((ref) => Stream.value([])),
      ],
      child: MaterialApp(home: ExportScreen(groupId: groupId)),
    );
  }

  testWidgets('ExportScreen renders correctly', (tester) async {
    const groupId = 'group-1';
    await tester.pumpWidget(createWidget(groupId));
    await tester.pumpAndSettle();

    expect(find.text('Export Group Data'), findsOneWidget);
    expect(find.text('Export data for Test Group'), findsOneWidget);
    expect(find.text('Export as CSV'), findsOneWidget);
    expect(find.text('Share Text Summary'), findsOneWidget);
  });

  testWidgets('Export as CSV calls shareCsv', (tester) async {
    const groupId = 'group-1';
    when(
      () => mockExportService.shareCsv(groupId, any()),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget(groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export as CSV'));
    await tester.pump();

    verify(() => mockExportService.shareCsv(groupId, 'Test Group')).called(1);
  });

  testWidgets('Share Text Summary calls shareTextSummary', (tester) async {
    const groupId = 'group-1';
    when(
      () => mockExportService.shareTextSummary(groupId, any()),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(createWidget(groupId));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Share Text Summary'));
    await tester.pump();

    verify(
      () => mockExportService.shareTextSummary(groupId, 'Test Group'),
    ).called(1);
  });
}
