import 'package:freezed_annotation/freezed_annotation.dart';
import 'tag.dart';

part 'tag_with_usage.freezed.dart';
part 'tag_with_usage.g.dart';

@freezed
class TagWithUsage with _$TagWithUsage {
  const factory TagWithUsage({required Tag tag, required int usageCount}) =
      _TagWithUsage;

  factory TagWithUsage.fromJson(Map<String, dynamic> json) =>
      _$TagWithUsageFromJson(json);
}
