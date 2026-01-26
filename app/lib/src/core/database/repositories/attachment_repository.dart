import 'package:uuid/uuid.dart';
import '../database.dart';
import '../../models/attachment.dart' as model;
import '../mappers/attachment_mapper.dart';

abstract class AttachmentRepository {
  Future<void> createAttachment(String txId, String path, String mimeType);
  Future<List<model.Attachment>> getAttachmentsByTransaction(String txId);
  Future<void> deleteAttachment(String id);
  Future<void> deleteAttachmentsByTransaction(String txId);
}

class DriftAttachmentRepository implements AttachmentRepository {
  final AppDatabase db;

  DriftAttachmentRepository(this.db);

  @override
  Future<void> createAttachment(
    String txId,
    String path,
    String mimeType,
  ) async {
    final companion = AttachmentsCompanion.insert(
      id: const Uuid().v4(),
      txId: txId,
      path: path,
      mime: mimeType,
      createdAt: DateTime.now(),
    );
    await db.into(db.attachments).insert(companion);
  }

  @override
  Future<List<model.Attachment>> getAttachmentsByTransaction(
    String txId,
  ) async {
    final query = db.select(db.attachments)..where((t) => t.txId.equals(txId));
    final rows = await query.get();
    return rows.map((row) => row.toModel()).toList();
  }

  @override
  Future<void> deleteAttachment(String id) async {
    await (db.delete(db.attachments)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteAttachmentsByTransaction(String txId) async {
    await (db.delete(db.attachments)..where((t) => t.txId.equals(txId))).go();
  }
}
