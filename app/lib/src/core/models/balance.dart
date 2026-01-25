import 'package:freezed_annotation/freezed_annotation.dart';

part 'balance.freezed.dart';
part 'balance.g.dart';

@freezed
class MemberBalance with _$MemberBalance {
  const factory MemberBalance({
    required String memberId,
    required String memberName,
    required int netAmountMinor,
    required bool isCreditor,
  }) = _MemberBalance;

  factory MemberBalance.fromJson(Map<String, dynamic> json) =>
      _$MemberBalanceFromJson(json);
}
