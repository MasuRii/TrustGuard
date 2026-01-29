import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AvatarService {
  static const int maxAvatarSize = 256;
  static const int jpegQuality = 80;

  Future<String> saveAvatar(String memberId, File imageFile) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final avatarsDir = Directory(p.join(appDocDir.path, 'avatars'));

    if (!await avatarsDir.exists()) {
      await avatarsDir.create(recursive: true);
    }

    final bytes = await imageFile.readAsBytes();
    final img.Image? image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Could not decode image');
    }

    // Resize and crop to square
    final resized = image.width > image.height
        ? img.copyResize(image, height: maxAvatarSize)
        : img.copyResize(image, width: maxAvatarSize);

    final size = resized.width < resized.height
        ? resized.width
        : resized.height;
    final x = (resized.width - size) ~/ 2;
    final y = (resized.height - size) ~/ 2;
    final cropped = img.copyCrop(
      resized,
      x: x,
      y: y,
      width: size,
      height: size,
    );

    final jpegBytes = img.encodeJpg(cropped, quality: jpegQuality);
    final avatarPath = p.join(avatarsDir.path, '$memberId.jpg');
    final avatarFile = File(avatarPath);

    await avatarFile.writeAsBytes(jpegBytes);

    return avatarPath;
  }

  Future<void> deleteAvatar(String memberId) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final avatarPath = p.join(appDocDir.path, 'avatars', '$memberId.jpg');
    final file = File(avatarPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  File? getAvatarFile(String? path) {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }
}
