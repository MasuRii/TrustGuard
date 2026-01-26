import '../../models/attachment.dart' as model;
import '../database.dart';

extension AttachmentMapper on Attachment {
  model.Attachment toModel() {
    return model.Attachment(
      id: id,
      txId: txId,
      path: path,
      mime: mime,
      createdAt: createdAt,
    );
  }
}
