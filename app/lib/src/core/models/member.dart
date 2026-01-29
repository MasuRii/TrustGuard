import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'member.freezed.dart';
part 'member.g.dart';

@freezed
abstract class Member with _$Member {
  const Member._();

  const factory Member({
    required String id,
    required String groupId,
    required String displayName,
    required DateTime createdAt,
    DateTime? removedAt,
    String? avatarPath,
    int? avatarColor,
    @Default(0) int orderIndex,
  }) = _Member;

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  bool get hasAvatar => avatarPath != null;

  Color get displayColor =>
      avatarColor != null ? Color(avatarColor!) : Colors.grey;

  static const List<int> presetColors = [
    0xFFF44336, // Red
    0xFFE91E63, // Pink
    0xFF9C27B0, // Purple
    0xFF673AB7, // Deep Purple
    0xFF3F51B5, // Indigo
    0xFF2196F3, // Blue
    0xFF03A9F4, // Light Blue
    0xFF00BCD4, // Cyan
    0xFF009688, // Teal
    0xFF4CAF50, // Green
  ];
}
