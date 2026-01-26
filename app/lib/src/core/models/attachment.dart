import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';
part 'attachment.g.dart';

@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    required String id,
    required String txId,
    required String path,
    required String mime,
    required DateTime createdAt,
  }) = _Attachment;

  factory Attachment.fromJson(Map<String, dynamic> json) =>
      _$AttachmentFromJson(json);
}
