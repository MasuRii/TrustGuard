import 'package:freezed_annotation/freezed_annotation.dart';

part 'transaction_filter.freezed.dart';
part 'transaction_filter.g.dart';

@freezed
class TransactionFilter with _$TransactionFilter {
  const factory TransactionFilter({
    String? searchQuery,
    Set<String>? tagIds,
    Set<String>? memberIds,
    DateTime? startDate,
    DateTime? endDate,
  }) = _TransactionFilter;

  factory TransactionFilter.fromJson(Map<String, dynamic> json) =>
      _$TransactionFilterFromJson(json);

  const TransactionFilter._();

  bool get isEmpty =>
      (searchQuery == null || searchQuery!.isEmpty) &&
      (tagIds == null || tagIds!.isEmpty) &&
      (memberIds == null || memberIds!.isEmpty) &&
      startDate == null &&
      endDate == null;
}
