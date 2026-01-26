import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class AttachmentService {
  static const String _attachmentDir = 'attachments';

  Future<String> saveAttachment(String txId, File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final txDir = Directory(p.join(directory.path, _attachmentDir, txId));

    if (!await txDir.exists()) {
      await txDir.create(recursive: true);
    }

    final uuid = const Uuid().v4();
    final extension = p.extension(imageFile.path);
    final fileName = '$uuid$extension';
    final savedFile = File(p.join(txDir.path, fileName));

    // Compression
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image != null) {
      // Resize to max 1024px width
      if (image.width > 1024) {
        image = img.copyResize(image, width: 1024);
      }

      final compressedBytes = img.encodeJpg(image, quality: 80);
      await savedFile.writeAsBytes(compressedBytes);
    } else {
      // Fallback if decoding fails
      await imageFile.copy(savedFile.path);
    }

    return savedFile.path;
  }

  Future<List<File>> getAttachments(String txId) async {
    final directory = await getApplicationDocumentsDirectory();
    final txDir = Directory(p.join(directory.path, _attachmentDir, txId));

    if (!await txDir.exists()) {
      return [];
    }

    final entities = await txDir.list().toList();
    return entities.whereType<File>().toList();
  }

  Future<void> deleteAttachment(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteAllAttachments(String txId) async {
    final directory = await getApplicationDocumentsDirectory();
    final txDir = Directory(p.join(directory.path, _attachmentDir, txId));

    if (await txDir.exists()) {
      await txDir.delete(recursive: true);
    }
  }

  Future<int> getStorageUsage() async {
    final directory = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(directory.path, _attachmentDir));

    if (!await attachmentsDir.exists()) {
      return 0;
    }

    int totalSize = 0;
    await for (final entity in attachmentsDir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }
}
