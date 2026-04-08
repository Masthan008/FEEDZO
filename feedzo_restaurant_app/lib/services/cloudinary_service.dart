import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Cloudinary image upload service.
/// Replace the constants with your real Cloudinary credentials.
class CloudinaryService {
  // Get these from: https://cloudinary.com/console
  static const _cloudName = 'dxbpni461';
  static const _uploadPreset = 'ml_default'; // unsigned preset - MUST be configured in Cloudinary

  static const _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload a file and return the secure URL, or null on failure.
  static Future<String?> uploadImage(File imageFile, {String folder = 'feedzo'}) async {
    try {
      debugPrint('Cloudinary: Starting upload for ${imageFile.path}');
      
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      debugPrint('Cloudinary: Sending request to $_baseUrl with preset: $_uploadPreset');
      
      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await http.Response.fromStream(response);

      debugPrint('Cloudinary: Response status: ${response.statusCode}');
      debugPrint('Cloudinary: Response body: ${body.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(body.body) as Map<String, dynamic>;
        final url = json['secure_url'] as String?;
        debugPrint('Cloudinary: Upload successful, URL: $url');
        return url;
      } else {
        debugPrint('Cloudinary: Upload failed with status ${response.statusCode}: ${body.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Cloudinary: Upload timed out after 30 seconds');
      return null;
    } catch (e, stack) {
      debugPrint('Cloudinary: Upload error: $e');
      debugPrint('Cloudinary: Stack trace: $stack');
      return null;
    }
  }

  /// Upload from bytes (useful for web/picked images)
  static Future<String?> uploadBytes(List<int> bytes, String filename, {String folder = 'feedzo'}) async {
    try {
      debugPrint('Cloudinary: Starting bytes upload for $filename (${bytes.length} bytes)');
      
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final body = await http.Response.fromStream(response);

      debugPrint('Cloudinary: Bytes upload response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(body.body) as Map<String, dynamic>?;
        final url = json?['secure_url'] as String?;
        debugPrint('Cloudinary: Bytes upload successful');
        return url;
      } else {
        debugPrint('Cloudinary: Bytes upload failed: ${body.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Cloudinary: Bytes upload timed out');
      return null;
    } catch (e, stack) {
      debugPrint('Cloudinary: Bytes upload error: $e');
      debugPrint('Cloudinary: Stack trace: $stack');
      return null;
    }
  }
}
