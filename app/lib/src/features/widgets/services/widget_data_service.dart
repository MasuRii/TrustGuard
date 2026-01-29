import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../../core/utils/money.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../../dashboard/services/dashboard_service.dart';
import '../models/widget_data.dart';

class WidgetDataService {
  final DashboardService _dashboardService;

  WidgetDataService({required DashboardService dashboardService})
    : _dashboardService = dashboardService;

  static const String _androidWidgetName = 'BalanceWidgetProvider';
  // static const String _iosWidgetName = 'BalanceWidget'; // Placeholder

  Future<WidgetData> getWidgetData() async {
    // For now, aggregate all balances (null selfMemberId)
    final summary = await _dashboardService.getGlobalSummary(null);
    final topGroups = await _dashboardService.getTopGroupBalances(null);

    return WidgetData(
      totalOwedToMe: summary.totalOwedToMe,
      totalOwedByMe: summary.totalOwedByMe,
      netBalance: summary.netBalance,
      currencyCode: 'USD', // Default to USD for now, could be improved later
      activeGroupCount: summary.groupCount,
      lastUpdated: DateTime.now(),
      topGroups: topGroups
          .map((g) => WidgetGroupData(name: g.name, netAmountMinor: g.balance))
          .toList(),
    );
  }

  Future<void> saveWidgetData(WidgetData data) async {
    await HomeWidget.saveWidgetData(
      'widget_owed_to_me_val',
      data.totalOwedToMe,
    );
    await HomeWidget.saveWidgetData(
      'widget_owed_by_me_val',
      data.totalOwedByMe,
    );
    await HomeWidget.saveWidgetData('widget_net_balance_val', data.netBalance);

    // Save formatted strings for display
    await HomeWidget.saveWidgetData(
      'widget_net_balance',
      MoneyUtils.format(data.netBalance, currencyCode: data.currencyCode),
    );
    await HomeWidget.saveWidgetData(
      'widget_owed',
      'Owed: ${MoneyUtils.format(data.totalOwedToMe, currencyCode: data.currencyCode)}',
    );
    await HomeWidget.saveWidgetData(
      'widget_owing',
      'Owing: ${MoneyUtils.format(data.totalOwedByMe, currencyCode: data.currencyCode)}',
    );

    await HomeWidget.saveWidgetData('widget_currency_code', data.currencyCode);
    await HomeWidget.saveWidgetData(
      'widget_group_count',
      '${data.activeGroupCount} active groups',
    );

    final lastUpdatedStr =
        '${data.lastUpdated.hour.toString().padLeft(2, '0')}:${data.lastUpdated.minute.toString().padLeft(2, '0')}';
    await HomeWidget.saveWidgetData(
      'widget_last_updated',
      'Updated at $lastUpdatedStr',
    );

    // Save top groups for large widget
    for (int i = 0; i < data.topGroups.length; i++) {
      final group = data.topGroups[i];
      await HomeWidget.saveWidgetData('widget_group_name_$i', group.name);
      await HomeWidget.saveWidgetData(
        'widget_group_balance_$i',
        MoneyUtils.format(
          group.netAmountMinor,
          currencyCode: data.currencyCode,
        ),
      );
      await HomeWidget.saveWidgetData(
        'widget_group_balance_val_$i',
        group.netAmountMinor,
      );
    }
    // Clear remaining slots (up to 5)
    for (int i = data.topGroups.length; i < 5; i++) {
      await HomeWidget.saveWidgetData('widget_group_name_$i', '');
      await HomeWidget.saveWidgetData('widget_group_balance_$i', '');
      await HomeWidget.saveWidgetData('widget_group_balance_val_$i', 0);
    }
  }

  Future<void> updateWidget() async {
    final data = await getWidgetData();
    await saveWidgetData(data);
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
      // iOSName: _iosWidgetName,
    );
  }
}

final widgetDataServiceProvider = Provider<WidgetDataService>((ref) {
  return WidgetDataService(
    dashboardService: ref.watch(dashboardServiceProvider),
  );
});
