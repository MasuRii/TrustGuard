import 'package:freezed_annotation/freezed_annotation.dart';

part 'widget_data.freezed.dart';
part 'widget_data.g.dart';

@freezed
abstract class WidgetGroupData with _$WidgetGroupData {
  const factory WidgetGroupData({
    required String id,
    required String name,
    required int netAmountMinor,
  }) = _WidgetGroupData;

  factory WidgetGroupData.fromJson(Map<String, dynamic> json) =>
      _$WidgetGroupDataFromJson(json);
}

@freezed
abstract class WidgetData with _$WidgetData {
  const factory WidgetData({
    required int totalOwedToMe,
    required int totalOwedByMe,
    required int netBalance,
    required String currencyCode,
    required int activeGroupCount,
    required DateTime lastUpdated,
    @Default([]) List<WidgetGroupData> topGroups,
  }) = _WidgetData;

  factory WidgetData.fromJson(Map<String, dynamic> json) =>
      _$WidgetDataFromJson(json);
}
