import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Thrown when a Cloudinary upload fails, either from a network error or
/// an error response from Cloudinary itself.
class CloudinaryUploadException implements Exception {
  CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => 'Cloudinary upload failed: $message';
}

/// Uploads images directly from the device to Cloudinary using an
/// unsigned upload preset — no Firebase Storage and no server-side signing
/// involved.
class CloudinaryService {
  CloudinaryService({http.Client? client}) : _client = client ?? http.Client();

  // TODO: update if this app is ever pointed at a different Cloudinary
  // account.
  static const _cloudName = 'jcviyden';
  static const _uploadPreset = 'sunday_kids_profile';

  final http.Client _client;

  Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

  /// Uploads [image] as a teacher's profile photo and returns its
  /// `secure_url`. Stored under the `teachers` folder, filename derived
  /// from [username].
  ///
  /// Unsigned uploads can't pass `overwrite: true`, so every upload gets a
  /// unique public id — `teachers/<username>_<timestamp>` — even when
  /// re-uploading a photo for the same teacher.
  Future<String> uploadTeacherPhoto(File image, String username) =>
      _upload(image: image, folder: 'teachers', identifier: username);

  /// Uploads [image] as a student's profile photo and returns its
  /// `secure_url`. Stored under the `students` folder, filename derived
  /// from [name] (students have no username field).
  ///
  /// Same unique-public-id reasoning as [uploadTeacherPhoto]:
  /// `students/<name>_<timestamp>`.
  Future<String> uploadStudentPhoto(File image, String name) =>
      _upload(image: image, folder: 'students', identifier: name);

  /// Uploads [image] as an admin's profile photo and returns its
  /// `secure_url`. Stored under the `admins` folder, filename derived
  /// from [name] (admins have no username field).
  ///
  /// Same unique-public-id reasoning as [uploadTeacherPhoto]:
  /// `admins/<name>_<timestamp>`.
  Future<String> uploadAdminPhoto(File image, String name) =>
      _upload(image: image, folder: 'admins', identifier: name);

  Future<String> _upload({
    required File image,
    required String folder,
    required String identifier,
  }) async {
    final sanitizedIdentifier = identifier
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    final publicId =
        '$folder/${sanitizedIdentifier}_${DateTime.now().millisecondsSinceEpoch}';

    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = publicId
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await _client.send(request);
    } catch (e) {
      throw CloudinaryUploadException('Network error: $e');
    }

    final response = await http.Response.fromStream(streamedResponse);
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw CloudinaryUploadException(
        'Unexpected response (HTTP ${response.statusCode})',
      );
    }

    if (response.statusCode != 200) {
      final error = body['error'] as Map<String, dynamic>?;
      throw CloudinaryUploadException(
        error?['message'] as String? ?? 'HTTP ${response.statusCode}',
      );
    }

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null) {
      throw CloudinaryUploadException('Response was missing secure_url');
    }
    return secureUrl;
  }
}
