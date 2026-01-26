import 'package:freezed_annotation/freezed_annotation.dart';

part 'global_balance_summary.freezed.dart';
part 'global_balance_summary.g.dart';

@freezed
abstract class GlobalBalanceSummary with _$GlobalBalanceSummary {
  const factory GlobalBalanceSummary({
    required int totalOwedByMe,
    required int totalOwedToMe,
    required int groupCount,
    required int unsettledGroupCount,
  }) = _GlobalBalanceSummary;

  const GlobalBalanceSummary._();

  int get netBalance => totalOwedToMe - totalOwedByMe;

  factory GlobalBalanceSummary.fromJson(Map<String, dynamic> json) =>
      _$GlobalBalanceSummaryFromJson(json);
}
