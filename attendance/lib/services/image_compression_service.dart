import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

/// Shrinks profile photos before they're uploaded to Cloudinary. These are
/// small avatar-sized images shown in circular thumbnails — nobody zooms
/// into them — so trading some quality for a much smaller upload is a good
/// deal for both storage usage and upload time.
class ImageCompressionService {
  static const _quality = 65;

  /// Caps the longer edge at 800px; profile photos are never displayed
  /// larger than that, so anything past it is wasted bytes.
  static const _maxDimension = 800;

  /// Returns a compressed copy of [image], or [image] itself if compression
  /// fails or doesn't actually shrink the file.
  Future<File> compress(File image) async {
    final targetPath = p.join(
      p.dirname(image.path),
      '${p.basenameWithoutExtension(image.path)}_compressed_'
      '${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        image.absolute.path,
        targetPath,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        quality: _quality,
      );
      if (result == null) return image;

      final compressedFile = File(result.path);
      final originalSize = await image.length();
      final compressedSize = await compressedFile.length();
      if (compressedSize >= originalSize) {
        await compressedFile.delete();
        return image;
      }
      return compressedFile;
    } catch (_) {
      return image;
    }
  }
}
