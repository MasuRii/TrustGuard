import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class Member with _$Member {
  const factory Member({
    required String id,
    required String groupId,
    required String displayName,
    required DateTime createdAt,
    DateTime? removedAt,
    @Default(0) int orderIndex,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
}
