import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:trustguard/src/features/dashboard/models/global_balance_summary.dart';
import 'package:trustguard/src/features/dashboard/services/dashboard_service.dart';
import 'package:trustguard/src/features/widgets/services/widget_data_service.dart';

class MockDashboardService extends Mock implements DashboardService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WidgetDataService service;
  late MockDashboardService mockDashboardService;
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    mockDashboardService = MockDashboardService();
    service = WidgetDataService(dashboardService: mockDashboardService);

    // Use the correct channel name for home_widget package
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('es.antonborri.home_widget'),
          (MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          },
        );
    log.clear();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('es.antonborri.home_widget'),
          null,
        );
    service.dispose();
  });

  group('WidgetDataService', () {
    test('getWidgetData returns aggregated balances and top groups', () async {
      const summary = GlobalBalanceSummary(
        totalOwedToMe: 1000,
        totalOwedByMe: 500,
        groupCount: 2,
        unsettledGroupCount: 1,
      );

      final topGroups = [
        (id: '1', name: 'Group 1', balance: 500),
        (id: '2', name: 'Group 2', balance: -300),
      ];

      when(
        () => mockDashboardService.getGlobalSummary(null),
      ).thenAnswer((_) async => summary);
      when(
        () => mockDashboardService.getTopGroupBalances(null),
      ).thenAnswer((_) async => topGroups);

      final data = await service.getWidgetData();

      expect(data.totalOwedToMe, 1000);
      expect(data.totalOwedByMe, 500);
      expect(data.netBalance, 500);
      expect(data.activeGroupCount, 2);
      expect(data.topGroups.length, 2);
      expect(data.topGroups[0].id, '1');
      expect(data.topGroups[0].name, 'Group 1');
      expect(data.topGroups[0].netAmountMinor, 500);
    });

    test(
      'saveWidgetData calls home_widget saveData with correct keys',
      () async {
        const summary = GlobalBalanceSummary(
          totalOwedToMe: 1000,
          totalOwedByMe: 500,
          groupCount: 1,
          unsettledGroupCount: 1,
        );

        final topGroups = [(id: '1', name: 'Group 1', balance: 500)];

        when(
          () => mockDashboardService.getGlobalSummary(null),
        ).thenAnswer((_) async => summary);
        when(
          () => mockDashboardService.getTopGroupBalances(null),
        ).thenAnswer((_) async => topGroups);

        final data = await service.getWidgetData();
        await service.saveWidgetData(data);

        final savedKeys = log
            .where((m) => m.method == 'saveWidgetData')
            .map((m) => m.arguments['id'])
            .toList();

        expect(savedKeys, contains('widget_owed_to_me_val'));
        expect(savedKeys, contains('widget_owed_by_me_val'));
        expect(savedKeys, contains('widget_net_balance_val'));
        expect(savedKeys, contains('widget_net_balance'));
        expect(savedKeys, contains('widget_owed'));
        expect(savedKeys, contains('widget_owing'));
        expect(savedKeys, contains('widget_group_count'));
        expect(savedKeys, contains('widget_last_updated'));
        expect(savedKeys, contains('widget_group_id_0'));
        expect(savedKeys, contains('widget_group_name_0'));
        expect(savedKeys, contains('widget_group_balance_0'));
        expect(savedKeys, contains('widget_group_balance_val_0'));
        expect(savedKeys, contains('widget_single_group_id'));

        // Verify single group ID is saved when groupCount == 1
        final singleGroupIdCall = log.firstWhere(
          (m) =>
              m.method == 'saveWidgetData' &&
              m.arguments['id'] == 'widget_single_group_id',
        );
        expect(singleGroupIdCall.arguments['data'], '1');
      },
    );

    test('updateWidget triggers platform widget refresh', () async {
      const summary = GlobalBalanceSummary(
        totalOwedToMe: 0,
        totalOwedByMe: 0,
        groupCount: 0,
        unsettledGroupCount: 0,
      );

      when(
        () => mockDashboardService.getGlobalSummary(null),
      ).thenAnswer((_) async => summary);
      when(
        () => mockDashboardService.getTopGroupBalances(null),
      ).thenAnswer((_) async => []);

      await service.updateWidget();

      expect(log.any((m) => m.method == 'updateWidget'), isTrue);
    });
  });
}
