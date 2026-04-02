import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cloudinary image upload service.
/// Replace the constants with your real Cloudinary credentials.
class CloudinaryService {
  // Get these from: https://cloudinary.com/console
  static const _cloudName = 'dxbpni461';
  static const _uploadPreset = 'ml_default'; // unsigned preset

  static const _baseUrl = 'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Upload a file and return the secure URL, or null on failure.
  static Future<String?> uploadImage(File imageFile, {String folder = 'feedzo'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final json = jsonDecode(body.body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Upload from bytes (useful for web/picked images)
  static Future<String?> uploadBytes(List<int> bytes, String filename, {String folder = 'feedzo'}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

      final response = await request.send();
      final body = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final json = jsonDecode(body.body) as Map<String, dynamic>?;
        return json?['secure_url'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
